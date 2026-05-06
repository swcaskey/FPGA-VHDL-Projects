library ieee;
use ieee.std_logic_1164.all;

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
    
    -- Register to detect the falling edge of video_active
    signal vblank_prev : std_logic := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= IDLE;
                imu_start <= '0';
                jstk_start <= '0';
                math_start <= '0';
                vblank_prev <= '0';
            else
                vblank_prev <= video_active; 

                case state is
                    when IDLE =>
                        imu_start <= '0';
                        jstk_start <= '0';
                        math_start <= '0';
                        state <= WAIT_VBLANK;

                    when WAIT_VBLANK =>
                        -- Wait for falling edge of video_active (Start of Vertical Blanking)
                        if vblank_prev = '1' and video_active = '0' then
                            state <= READ_IMU;
                        end if;

                    when READ_IMU =>
                        imu_start <= '1';
                        state <= WAIT_IMU;

                    when WAIT_IMU =>
                        if imu_valid = '1' then
                            imu_start <= '0';
                            state <= READ_JSTK;
                        end if;

                    when READ_JSTK =>
                        jstk_start <= '1';
                        state <= WAIT_JSTK;

                    when WAIT_JSTK =>
                        if jstk_valid = '1' then
                            jstk_start <= '0';
                            state <= CALC_MATH;
                        end if;

                    when CALC_MATH =>
                        math_start <= '1';
                        state <= WAIT_MATH;

                    when WAIT_MATH =>
                        if math_done = '1' then
                            math_start <= '0';
                            state <= WAIT_VBLANK; -- Wait for the next frame
                        end if;

                    when others =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;
end behavioral;