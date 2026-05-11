library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hdmi_telemetry_top is
    port (
        -- Board clock/reset/select
        sysclk     : in  std_logic; -- 125 MHz
        btn        : in  std_logic_vector(0 downto 0);
        sw         : in  std_logic_vector(0 downto 0); -- SW0 mode select

        -- SPI Lines for PMOD NAV
        nav_mosi   : out std_logic;
        nav_miso   : in  std_logic;
        nav_sclk   : out std_logic;
        nav_cs     : out std_logic;

        -- SPI Lines for PMOD JSTK2
        jstk_mosi  : out std_logic;
        jstk_miso  : in  std_logic;
        jstk_sclk  : out std_logic;
        jstk_cs    : out std_logic;

        -- Diagnostic LEDs
        led        : out std_logic_vector(3 downto 0)
    );
end hdmi_telemetry_top;

architecture structural of hdmi_telemetry_top is
    signal rst : std_logic;
    signal spi_en : std_logic;
    
    -- NAV SPI bus and outputs
    signal spi1_start, spi1_ready : std_logic;
    signal spi1_din, spi1_dout    : std_logic_vector(7 downto 0);
    signal pitch_val, roll_val, yaw_val : std_logic_vector(15 downto 0);
    signal imu_start, imu_valid : std_logic;

    -- JSTK SPI bus and outputs
    signal spi2_start, spi2_ready : std_logic;
    signal spi2_din, spi2_dout    : std_logic_vector(7 downto 0);
    signal jstk_x_val, jstk_y_val : std_logic_vector(15 downto 0);
    signal btn_center             : std_logic;
    signal jstk_start, jstk_valid : std_logic;

    -- Thresholds for 0.5g (roughly a 30-degree tilt)
    constant IMU_THRESH_HI : signed(15 downto 0) := to_signed(8192, 16);
    constant IMU_THRESH_LO : signed(15 downto 0) := to_signed(-8192, 16);
    
    constant JSTK_THRESH_HI : unsigned(15 downto 0) := to_unsigned(160, 16);
    constant JSTK_THRESH_LO : unsigned(15 downto 0) := to_unsigned(96, 16);

    signal imu_led0, imu_led1, imu_led2 : std_logic;
    signal jstk_led0, jstk_led1 : std_logic;
    
    -- 100 Hz Pacing Timer
    type poll_state_type is (IDLE, READ_SENSORS, WAIT_IMU, WAIT_JSTK);
    signal poll_state : poll_state_type := IDLE;
    signal timer_cnt : unsigned(23 downto 0) := (others => '0');
    constant TIMER_MAX : unsigned(23 downto 0) := to_unsigned(1250000, 24); -- 10ms at 125MHz

begin
    rst <= btn(0);

    U_SPI_CLK : entity work.spi_clock_en
        port map (
            clk_125mhz  => sysclk,
            spi_en_1mhz => spi_en
        );

    U_SPI_NAV : entity work.spi_master
        port map (
            clk => sysclk, spi_en => spi_en, rst => rst,
            start => spi1_start, data_in => spi1_dout,
            data_out => spi1_din, ready => spi1_ready,
            mosi => nav_mosi, miso => nav_miso, sclk => nav_sclk
        );

    U_IMU_CTRL : entity work.nav_imu_controller
        port map (
            clk => sysclk, rst => rst,
            start_read => imu_start, data_valid => imu_valid,
            pitch_out => pitch_val, roll_out => roll_val, yaw_out => yaw_val,
            spi_ready => spi1_ready, spi_data_in => spi1_din,
            spi_start => spi1_start, spi_data_out => spi1_dout,
            cs_ag => nav_cs
        );

    U_SPI_JSTK : entity work.spi_master
        port map (
            clk => sysclk, spi_en => spi_en, rst => rst,
            start => spi2_start, data_in => spi2_dout,
            data_out => spi2_din, ready => spi2_ready,
            mosi => jstk_mosi, miso => jstk_miso, sclk => jstk_sclk
        );

    U_JSTK_CTRL : entity work.jstk2_controller
        port map (
            clk => sysclk, rst => rst,
            start_read => jstk_start, data_valid => jstk_valid,
            x_out => jstk_x_val, y_out => jstk_y_val, joystick_btn => btn_center,
            spi_ready => spi2_ready, spi_data_in => spi2_din,
            spi_start => spi2_start, spi_data_out => spi2_dout,
            cs_jstk => jstk_cs
        );

    -- Safe 100 Hz Polling FSM
    process(sysclk)
    begin
        if rising_edge(sysclk) then
            if rst = '1' then
                imu_start <= '0';
                jstk_start <= '0';
                poll_state <= IDLE;
                timer_cnt <= (others => '0');
            else
                case poll_state is
                    when IDLE =>
                        imu_start <= '0';
                        jstk_start <= '0';
                        if timer_cnt = TIMER_MAX then
                            timer_cnt <= (others => '0');
                            poll_state <= READ_SENSORS;
                        else
                            timer_cnt <= timer_cnt + 1;
                        end if;

                    when READ_SENSORS =>
                        imu_start <= '1';
                        jstk_start <= '1';
                        poll_state <= WAIT_IMU;

                    when WAIT_IMU =>
                        if imu_valid = '1' then
                            imu_start <= '0';
                            poll_state <= WAIT_JSTK;
                        end if;

                    when WAIT_JSTK =>
                        if jstk_valid = '1' then
                            jstk_start <= '0';
                            poll_state <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- Mode 0 (SW0=0): NAV Accelerometer Tilt-O-Meter
    
    -- Pitch: Lights up if tilted > 30 degrees forward or backward
    imu_led2 <= '1' when (signed(pitch_val) > IMU_THRESH_HI) or (signed(pitch_val) < IMU_THRESH_LO) else '0';
    
    -- Roll: Lights up if tilted > 30 degrees left or right
    imu_led1 <= '1' when (signed(roll_val) > IMU_THRESH_HI) or (signed(roll_val) < IMU_THRESH_LO) else '0';
    
    -- Upside Down: The Z-axis normally reads ~16384 (gravity pulling down). 
    -- If it goes below zero, the board has been flipped upside down!
    imu_led0 <= '1' when (signed(yaw_val) < 0) else '0';

    -- Mode 1 (SW0=1): JSTK thresholds
    jstk_led0 <= '1' when (unsigned(jstk_x_val) > JSTK_THRESH_HI) or (unsigned(jstk_x_val) < JSTK_THRESH_LO) else '0';
    jstk_led1 <= '1' when (unsigned(jstk_y_val) > JSTK_THRESH_HI) or (unsigned(jstk_y_val) < JSTK_THRESH_LO) else '0';

    -- LED Routing
    led(0) <= imu_led0 when sw(0) = '0' else jstk_led0;
    led(1) <= imu_led1 when sw(0) = '0' else jstk_led1;
    led(2) <= imu_led2 when sw(0) = '0' else '0';
    led(3) <= '0';

end structural;