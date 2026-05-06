library ieee;
use ieee.std_logic_1164.all;

entity hdmi_telemetry_top is
    port (
        -- Board Clock
        sysclk     : in  std_logic; -- 125 MHz physical board clock
        btn        : in  std_logic_vector(0 downto 0); -- Hardware reset button
        
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
        
        -- HDMI TMDS Outputs
        TMDS_Clk_p : out std_logic;
        TMDS_Clk_n : out std_logic;
        TMDS_Data_p: out std_logic_vector(2 downto 0);
        TMDS_Data_n: out std_logic_vector(2 downto 0)
    );
end hdmi_telemetry_top;

architecture structural of hdmi_telemetry_top is

    -- Reset signals
    signal rst       : std_logic;
    signal rst_n     : std_logic;
    signal vid_reset : std_logic;
    
    -- Clock signals
    signal pclk      : std_logic; -- 25 MHz from clk_wiz
    signal serial_clk: std_logic; -- Phase-locked 125 MHz from clk_wiz
    signal clk_lock  : std_logic;
    signal spi_en    : std_logic; -- 1 MHz pulse
    
    -- SPI Master shared buses
    signal spi1_start, spi1_ready : std_logic;
    signal spi1_din, spi1_dout    : std_logic_vector(7 downto 0);
    
    signal spi2_start, spi2_ready : std_logic;
    signal spi2_din, spi2_dout    : std_logic_vector(7 downto 0);
    
    -- Sensor Data
    signal pitch_val, roll_val, yaw_val : std_logic_vector(15 downto 0);
    signal jstk_x_val, jstk_y_val       : std_logic_vector(15 downto 0);
    signal btn_center                   : std_logic;
    
    -- FSM Handshakes
    signal imu_start, imu_valid   : std_logic;
    signal jstk_start, jstk_valid : std_logic;
    signal math_start, math_done  : std_logic;
    
    -- Math to Renderer Data
    signal v0_x, v0_y : std_logic_vector(9 downto 0);
    signal v1_x, v1_y : std_logic_vector(9 downto 0);
    signal v2_x, v2_y : std_logic_vector(9 downto 0);
    signal v3_x, v3_y : std_logic_vector(9 downto 0);
    
    -- VGA Timing to Renderer & HDMI
    signal hsync, vsync, vde : std_logic;
    signal hcount, vcount    : std_logic_vector(9 downto 0);
    
    -- Video RGB Data
    signal red_data, green_data, blue_data : std_logic_vector(7 downto 0);
    signal rgb_combined : std_logic_vector(23 downto 0);

begin

    -- Standardize Resets
    rst <= btn(0);
    rst_n <= not btn(0);
    vid_reset <= not clk_lock;
    rgb_combined <= red_data & green_data & blue_data;

    --------------------------------------------------------------------------
    -- CLOCKING INFRASTRUCTURE
    --------------------------------------------------------------------------
    U_CLK_WIZ : entity work.clk_wiz_0
        port map (
            clk_in1  => sysclk,
            reset    => rst,
            clk_out1 => pclk,
            clk_out2 => serial_clk, -- Routed for the HDMI IP block
            locked   => clk_lock
        );

    U_SPI_CLK : entity work.spi_clock_en
        port map (
            clk_125mhz  => sysclk,
            spi_en_1mhz => spi_en
        );

    --------------------------------------------------------------------------
    -- CENTRAL CONTROLLER
    --------------------------------------------------------------------------
    U_MASTER_FSM : entity work.central_fsmd
        port map (
            clk => sysclk, rst => rst,
            video_active => vde,
            imu_start => imu_start, imu_valid => imu_valid,
            jstk_start => jstk_start, jstk_valid => jstk_valid,
            math_start => math_start, math_done => math_done
        );

    --------------------------------------------------------------------------
    -- IMU SENSOR PIPELINE
    --------------------------------------------------------------------------
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

    --------------------------------------------------------------------------
    -- JOYSTICK SENSOR PIPELINE
    --------------------------------------------------------------------------
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

    --------------------------------------------------------------------------
    -- 3D MATHEMATICS DATAPATH
    --------------------------------------------------------------------------
    U_MATH : entity work.math_pipeline
        port map (
            clk => sysclk, rst => rst, start => math_start,
            pitch => pitch_val, roll => roll_val, yaw => yaw_val,
            jstk_x => jstk_x_val, jstk_y => jstk_y_val,
            v0_x => v0_x, v0_y => v0_y, v1_x => v1_x, v1_y => v1_y,
            v2_x => v2_x, v2_y => v2_y, v3_x => v3_x, v3_y => v3_y,
            done => math_done
        );

    --------------------------------------------------------------------------
    -- VIDEO RENDERING & OUTPUT
    --------------------------------------------------------------------------
    U_VGA_CTRL : entity work.vga_ctrl
        port map (
            clk => pclk, en => '1',
            vid => vde, hs => hsync, vs => vsync,
            hc => hcount, vc => vcount
        );

    U_RENDERER : entity work.wireframe_renderer
        port map (
            pclk => pclk, rst => rst, video_active => vde,
            hcount => hcount, vcount => vcount,
            v0_x => v0_x, v0_y => v0_y, v1_x => v1_x, v1_y => v1_y,
            v2_x => v2_x, v2_y => v2_y, v3_x => v3_x, v3_y => v3_y,
            red => red_data, green => green_data, blue => blue_data
        );

    U_RGB2DVI : entity work.rgb2dvi_0
        port map (
            TMDS_Clk_p  => TMDS_Clk_p,
            TMDS_Clk_n  => TMDS_Clk_n,
            TMDS_Data_p => TMDS_Data_p,
            TMDS_Data_n => TMDS_Data_n,
            aRst        => vid_reset, 
            vid_pData   => rgb_combined,
            vid_pVDE    => vde,
            vid_pHSync  => hsync,
            vid_pVSync  => vsync,
            PixelClk    => pclk,
            SerialClk   => serial_clk -- Locked to the Clocking Wizard to resolve timing violation
        );

end structural;