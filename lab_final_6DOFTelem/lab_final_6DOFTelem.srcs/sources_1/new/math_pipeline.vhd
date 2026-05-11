library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity math_pipeline is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        start      : in  std_logic;
        
        -- Sensor Inputs (from Phase 2)
        pitch      : in  std_logic_vector(15 downto 0);
        roll       : in  std_logic_vector(15 downto 0);
        yaw        : in  std_logic_vector(15 downto 0);
        jstk_x     : in  std_logic_vector(15 downto 0);
        jstk_y     : in  std_logic_vector(15 downto 0);
        
        -- 2D Outputs (Flattened screen coordinates for 4 vertices)
        -- Sized to 10-bits to match VGA/HDMI hcount and vcount
        v0_x, v0_y : out std_logic_vector(9 downto 0);
        v1_x, v1_y : out std_logic_vector(9 downto 0);
        v2_x, v2_y : out std_logic_vector(9 downto 0);
        v3_x, v3_y : out std_logic_vector(9 downto 0);
        
        done       : out std_logic
    );
end math_pipeline;

architecture behavioral of math_pipeline is

    type state_type is (IDLE, ROTATE, TRANSLATE, PROJECT, FINISH);
    signal state : state_type := IDLE;

    -- Hardcoded 3D Wireframe Vertices (Fixed Point)
    -- Slight depth spread gives a visible "orbit camera" effect.
    type vertex_array is array (0 to 3) of signed(15 downto 0);
    constant ORIG_X : vertex_array := (to_signed(-50, 16), to_signed(50, 16), to_signed(50, 16), to_signed(-50, 16));
    constant ORIG_Y : vertex_array := (to_signed(-50, 16), to_signed(-50, 16), to_signed(50, 16), to_signed(50, 16));
    constant ORIG_Z : vertex_array := (to_signed(80, 16), to_signed(120, 16), to_signed(120, 16), to_signed(80, 16));

    -- Pipeline registers
    signal rot_x, rot_y, rot_z     : vertex_array := (others => (others => '0'));
    signal trans_x, trans_y, trans_z : vertex_array := (others => (others => '0'));
    signal proj_x, proj_y          : vertex_array := (others => (others => '0'));

    constant JSTK_CENTER : signed(15 downto 0) := to_signed(128, 16);
    constant ORBIT_MIX_SHIFT : integer := 7;
    constant JSTK_ROT_SHIFT : integer := 1;
    constant JSTK_TILT_SHIFT : integer := 1;
    constant IMU_MAIN_SHIFT : integer := 10;
    constant IMU_ROLL_SHIFT : integer := 11;

    function clamp_to_10(value : signed(15 downto 0); max_value : integer) return std_logic_vector is
        variable val_i : integer;
        variable out_i : integer;
    begin
        val_i := to_integer(value);
        if val_i < 0 then
            out_i := 0;
        elsif val_i > max_value then
            out_i := max_value;
        else
            out_i := val_i;
        end if;
        return std_logic_vector(to_unsigned(out_i, 10));
    end function;

begin

    process(clk)
        variable i : integer range 0 to 3;
        variable spin_cmd      : signed(15 downto 0);
        variable tilt_cmd      : signed(15 downto 0);
        variable imu_yaw_off   : signed(15 downto 0);
        variable imu_pitch_off : signed(15 downto 0);
        variable imu_roll_off  : signed(15 downto 0);
        variable x_tmp         : signed(15 downto 0);
        variable y_tmp         : signed(15 downto 0);
        variable z_tmp         : signed(15 downto 0);
        variable z_depth       : integer;
        variable depth_scale   : integer range 0 to 3;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= IDLE;
                done <= '0';
                v0_x <= (others => '0'); v0_y <= (others => '0');
                v1_x <= (others => '0'); v1_y <= (others => '0');
                v2_x <= (others => '0'); v2_y <= (others => '0');
                v3_x <= (others => '0'); v3_y <= (others => '0');
            else
                case state is
                    when IDLE =>
                        done <= '0';
                        if start = '1' then
                            state <= ROTATE;
                        end if;

                    when ROTATE =>
                        -- 1. Orbit-style small-angle rotation (timing-safe).
                        spin_cmd      := resize(shift_right((JSTK_CENTER - signed(jstk_x)), JSTK_ROT_SHIFT), 16);
                        tilt_cmd      := resize(shift_right((signed(jstk_y) - JSTK_CENTER), JSTK_TILT_SHIFT), 16);
                        imu_yaw_off   := resize(shift_right(signed(yaw), IMU_MAIN_SHIFT), 16);
                        imu_pitch_off := resize(shift_right(signed(pitch), IMU_MAIN_SHIFT), 16);
                        imu_roll_off  := resize(shift_right(signed(roll), IMU_ROLL_SHIFT), 16);

                        for i in 0 to 3 loop
                            -- Yaw (around Y axis)
                            x_tmp := resize(ORIG_X(i) + shift_right(spin_cmd * ORIG_Z(i), ORBIT_MIX_SHIFT), 16);
                            z_tmp := resize(ORIG_Z(i) - shift_right(spin_cmd * ORIG_X(i), ORBIT_MIX_SHIFT), 16);

                            -- Pitch (around X axis)
                            y_tmp := resize(ORIG_Y(i) - shift_right(tilt_cmd * z_tmp, ORBIT_MIX_SHIFT), 16);
                            z_tmp := resize(z_tmp + shift_right(tilt_cmd * ORIG_Y(i), ORBIT_MIX_SHIFT), 16);

                            rot_x(i) <= resize(x_tmp + imu_yaw_off + imu_roll_off, 16);
                            rot_y(i) <= resize(y_tmp + imu_pitch_off - imu_roll_off, 16);
                            rot_z(i) <= z_tmp;
                        end loop;
                        state <= TRANSLATE;

                    when TRANSLATE =>
                        -- 2. Pass-through stage
                        for i in 0 to 3 loop
                            trans_x(i) <= rot_x(i);
                            trans_y(i) <= rot_y(i);
                            trans_z(i) <= rot_z(i);
                        end loop;
                        state <= PROJECT;

                    when PROJECT =>
                        -- 3. Depth-aware projection without expensive general division.
                        for i in 0 to 3 loop
                            z_depth := to_integer(trans_z(i));

                            if z_depth < 80 then
                                depth_scale := 3; -- nearest
                            elsif z_depth < 100 then
                                depth_scale := 2;
                            elsif z_depth < 120 then
                                depth_scale := 1;
                            else
                                depth_scale := 0; -- farthest
                            end if;

                            proj_x(i) <= resize(shift_left(trans_x(i), depth_scale) + 320, 16);
                            proj_y(i) <= resize(shift_left(trans_y(i), depth_scale) + 240, 16);
                        end loop;
                        state <= FINISH;

                    when FINISH =>
                        -- Clamp to the active 640x480 frame before converting to 10-bit
                        v0_x <= clamp_to_10(proj_x(0), 639);
                        v0_y <= clamp_to_10(proj_y(0), 479);
                        
                        v1_x <= clamp_to_10(proj_x(1), 639);
                        v1_y <= clamp_to_10(proj_y(1), 479);
                        
                        v2_x <= clamp_to_10(proj_x(2), 639);
                        v2_y <= clamp_to_10(proj_y(2), 479);
                        
                        v3_x <= clamp_to_10(proj_x(3), 639);
                        v3_y <= clamp_to_10(proj_y(3), 479);
                        
                        done <= '1';
                        if start = '0' then
                            state <= IDLE;
                        end if;

                end case;
            end if;
        end if;
    end process;

end behavioral;
