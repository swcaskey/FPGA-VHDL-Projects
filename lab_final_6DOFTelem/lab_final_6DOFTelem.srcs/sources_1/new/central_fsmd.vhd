library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity central_fsmd is
    port (
        clk             : in  std_logic; -- 125 MHz system clock
        rst             : in  std_logic;

        -- Triggers from VGA timing
        video_active    : in  std_logic;

        -- IMU Controller Interface
        imu_start       : out std_logic;
        imu_valid       : in  std_logic;

        -- JSTK2 Controller Interface
        jstk_start      : out std_logic;
        jstk_valid      : in  std_logic;

        -- Math Pipeline Interface
        math_start      : out std_logic;
        math_done       : in  std_logic
    );
end central_fsmd;

architecture behavioral of central_fsmd is
    type state_type is (IDLE, WAIT_VBLANK, READ_IMU, WAIT_IMU, READ_JSTK, WAIT_JSTK, CALC_MATH, WAIT_MATH);
    signal state : state_type := IDLE;

    -- Synchronize video_active (25 MHz domain) into the 125 MHz FSM domain
    signal vblank_ff1  : std_logic := '0';
    signal vblank_ff2  : std_logic := '0';
    signal vblank_prev : std_logic := '0';

    -- Deadlock guard: do not wait forever if a sub-block misses its done/valid handshake
    constant WAIT_TIMEOUT : unsigned(23 downto 0) := to_unsigned(12500000, 24); -- ~100 ms @125 MHz
    signal wait_counter   : unsigned(23 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= IDLE;
                imu_start <= '0';
                jstk_start <= '0';
                math_start <= '0';
                vblank_ff1 <= '0';
                vblank_ff2 <= '0';
                vblank_prev <= '0';
                wait_counter <= (others => '0');
            else
                vblank_ff1 <= video_active;
                vblank_ff2 <= vblank_ff1;
                vblank_prev <= vblank_ff2;

                case state is
                    when IDLE =>
                        imu_start <= '0';
                        jstk_start <= '0';
                        math_start <= '0';
                        wait_counter <= (others => '0');
                        state <= WAIT_VBLANK;

                    when WAIT_VBLANK =>
                        imu_start <= '0';
                        jstk_start <= '0';
                        math_start <= '0';
                        wait_counter <= (others => '0');
                        -- Wait for falling edge of video_active (Start of Vertical Blanking)
                        if vblank_prev = '1' and vblank_ff2 = '0' then
                            state <= READ_IMU;
                        end if;

                    when READ_IMU =>
                        imu_start <= '1';
                        jstk_start <= '0';
                        math_start <= '0';
                        wait_counter <= (others => '0');
                        state <= WAIT_IMU;

                    when WAIT_IMU =>
                        imu_start <= '1';
                        jstk_start <= '0';
                        math_start <= '0';
                        if imu_valid = '1' then
                            imu_start <= '0';
                            wait_counter <= (others => '0');
                            state <= READ_JSTK;
                        elsif wait_counter = WAIT_TIMEOUT then
                            imu_start <= '0';
                            wait_counter <= (others => '0');
                            state <= READ_JSTK;
                        else
                            wait_counter <= wait_counter + 1;
                        end if;

                    when READ_JSTK =>
                        imu_start <= '0';
                        jstk_start <= '1';
                        math_start <= '0';
                        wait_counter <= (others => '0');
                        state <= WAIT_JSTK;

                    when WAIT_JSTK =>
                        imu_start <= '0';
                        jstk_start <= '1';
                        math_start <= '0';
                        if jstk_valid = '1' then
                            jstk_start <= '0';
                            wait_counter <= (others => '0');
                            state <= CALC_MATH;
                        elsif wait_counter = WAIT_TIMEOUT then
                            jstk_start <= '0';
                            wait_counter <= (others => '0');
                            state <= CALC_MATH;
                        else
                            wait_counter <= wait_counter + 1;
                        end if;

                    when CALC_MATH =>
                        imu_start <= '0';
                        jstk_start <= '0';
                        math_start <= '1';
                        wait_counter <= (others => '0');
                        state <= WAIT_MATH;

                    when WAIT_MATH =>
                        imu_start <= '0';
                        jstk_start <= '0';
                        math_start <= '1';
                        if math_done = '1' then
                            math_start <= '0';
                            wait_counter <= (others => '0');
                            state <= WAIT_VBLANK; -- Wait for the next frame
                        elsif wait_counter = WAIT_TIMEOUT then
                            math_start <= '0';
                            wait_counter <= (others => '0');
                            state <= WAIT_VBLANK; -- Wait for the next frame
                        else
                            wait_counter <= wait_counter + 1;
                        end if;

                    when others =>
                        imu_start <= '0';
                        jstk_start <= '0';
                        math_start <= '0';
                        wait_counter <= (others => '0');
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;
end behavioral;
