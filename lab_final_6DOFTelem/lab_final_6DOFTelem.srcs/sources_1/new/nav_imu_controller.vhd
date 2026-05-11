library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nav_imu_controller is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        start_read : in  std_logic;
        data_valid : out std_logic;
        pitch_out  : out std_logic_vector(15 downto 0);
        roll_out   : out std_logic_vector(15 downto 0);
        yaw_out    : out std_logic_vector(15 downto 0);
        spi_ready  : in  std_logic;
        spi_data_in: in  std_logic_vector(7 downto 0);
        spi_start  : out std_logic;
        spi_data_out: out std_logic_vector(7 downto 0);
        cs_ag      : out std_logic
    );
end nav_imu_controller;

architecture behavioral of nav_imu_controller is
    type state_type is (BOOT_WAIT, INIT, IDLE, READ_IMU, DONE);
    signal state : state_type := BOOT_WAIT;
    signal step  : integer range 0 to 10 := 0;

    type spi_state_type is (S_IDLE, S_WAIT_ACK, S_WAIT_READY);
    signal spi_state : spi_state_type := S_IDLE;
    signal go_spi    : std_logic := '0';
    signal spi_done  : std_logic := '0';
    signal tx_byte   : std_logic_vector(7 downto 0) := x"00";

    signal xl, xh, yl, yh, zl, zh : std_logic_vector(7 downto 0);
    signal delay_us  : integer range 0 to 255 := 0;
    signal boot_cnt  : integer range 0 to 625000 := 0; -- 5ms delay at 125MHz

begin
    -- SPI Handshake Engine
    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                spi_state <= S_IDLE;
                spi_start <= '0';
                spi_done <= '0';
                spi_data_out <= x"00";
            else
                case spi_state is
                    when S_IDLE =>
                        spi_done <= '0';
                        if go_spi = '1' then
                            spi_data_out <= tx_byte;
                            spi_start <= '1';
                            spi_state <= S_WAIT_ACK;
                        end if;
                    when S_WAIT_ACK =>
                        if spi_ready = '0' then
                            spi_start <= '0';
                            spi_state <= S_WAIT_READY;
                        end if;
                    when S_WAIT_READY =>
                        if spi_ready = '1' then
                            spi_done <= '1';
                            spi_state <= S_IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- Main Data Controller
    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= BOOT_WAIT;
                step <= 0;
                go_spi <= '0';
                cs_ag <= '1';
                data_valid <= '0';
                pitch_out <= (others => '0');
                roll_out <= (others => '0'); yaw_out <= (others => '0');
                boot_cnt <= 0;
                delay_us <= 0;
            else
                case state is
                    when BOOT_WAIT =>
                        cs_ag <= '1';
                        -- Hold here for 5 milliseconds so the physical silicon can wake up
                        if boot_cnt < 625000 then
                            boot_cnt <= boot_cnt + 1;
                        else
                            state <= INIT;
                        end if;

                    when INIT =>
                        if spi_done = '1' then
                            go_spi <= '0';
                            step <= step + 1;
                        elsif go_spi = '0' then
                            if step = 0 then cs_ag <= '0';
                                tx_byte <= x"22"; go_spi <= '1'; -- CTRL_REG8
                            elsif step = 1 then tx_byte <= x"04";
                                go_spi <= '1'; -- Enable Auto-Increment
                            elsif step = 2 then
                                cs_ag <= '1';
                                if delay_us < 250 then delay_us <= delay_us + 1;
                                else delay_us <= 0; step <= 3; end if;
                            elsif step = 3 then cs_ag <= '0'; tx_byte <= x"10"; go_spi <= '1';
                                -- CTRL_REG1_G
                            elsif step = 4 then tx_byte <= x"C0";
                                go_spi <= '1'; -- Wake Gyroscope
                            elsif step = 5 then
                                cs_ag <= '1';
                                if delay_us < 250 then delay_us <= delay_us + 1;
                                else delay_us <= 0; step <= 6; end if;
                            elsif step = 6 then cs_ag <= '0'; tx_byte <= x"20"; go_spi <= '1';
                                -- CTRL_REG6_XL
                            elsif step = 7 then tx_byte <= x"C0";
                                go_spi <= '1'; -- Wake Accelerometer
                            elsif step = 8 then
                                cs_ag <= '1';
                                state <= IDLE;
                            end if;
                        end if;

                    when IDLE =>
                        data_valid <= '0';
                        cs_ag <= '1';
                        step <= 0;
                        if start_read = '1' then
                            state <= READ_IMU;
                        end if;

                    when READ_IMU =>
                        if start_read = '0' then
                            go_spi <= '0';
                            cs_ag <= '1'; step <= 0; state <= IDLE;
                        elsif spi_done = '1' then
                            go_spi <= '0';
                            if step = 1 then xl <= spi_data_in; end if;
                            if step = 2 then xh <= spi_data_in; end if;
                            if step = 3 then yl <= spi_data_in; end if;
                            if step = 4 then yh <= spi_data_in; end if;
                            if step = 5 then zl <= spi_data_in; end if;
                            if step = 6 then zh <= spi_data_in; end if;
                            step <= step + 1;
                        elsif go_spi = '0' then
                            cs_ag <= '0';
                            -- FIXED: Read Address for Gyroscope (0x18 + Read Bit)
                            if step = 0 then tx_byte <= x"98";
                            go_spi <= '1'; 
                            elsif step < 7 then tx_byte <= x"00"; go_spi <= '1'; 
                            else state <= DONE;
                            end if;
                        end if;

                    when DONE =>
                        cs_ag <= '1';
                        pitch_out <= xh & xl;
                        roll_out  <= yh & yl;
                        yaw_out   <= zh & zl;
                        data_valid <= '1';
                        if start_read = '0' then
                            state <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;
end behavioral;