library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hdmi_top is
    generic (
        SIM_BYPASS_CLK_WIZ : boolean := false
    );
    port (
        clk         : in  std_logic;  -- 125 MHz board clock
        hdmi_clk_p  : out std_logic;
        hdmi_clk_n  : out std_logic;
        hdmi_d_p    : out std_logic_vector(2 downto 0);
        hdmi_d_n    : out std_logic_vector(2 downto 0);
        hdmi_out_en : out std_logic   -- Drive high for Zybo Rev. B Source mode
    );
end hdmi_top;

architecture behavioral of hdmi_top is
    component clk_wiz_0 is
        port (
            clk_out1 : out std_logic; -- 25 MHz PixelClk
            reset    : in  std_logic;
            locked   : out std_logic;
            clk_in1  : in  std_logic  -- 125 MHz input
        );
    end component;

    component vga_ctrl is
        port (
            clk    : in  std_logic;
            enable : in  std_logic;
            hcount : out std_logic_vector(9 downto 0);
            vcount : out std_logic_vector(9 downto 0);
            vid    : out std_logic;
            hs     : out std_logic;
            vs     : out std_logic
        );
    end component;

    component picture is
        port (
            clka  : in  std_logic;
            addra : in  std_logic_vector(17 downto 0);
            douta : out std_logic_vector(7 downto 0)
        );
    end component;

    component pixel_pusher_hdmi is
        port (
            clk    : in  std_logic;
            enable : in  std_logic;
            vs     : in  std_logic;
            pixel  : in  std_logic_vector(7 downto 0);
            hcount : in  std_logic_vector(9 downto 0);
            vid    : in  std_logic;
            addr   : out std_logic_vector(17 downto 0);
            r      : out std_logic_vector(7 downto 0);
            g      : out std_logic_vector(7 downto 0);
            b      : out std_logic_vector(7 downto 0)
        );
    end component;

    component rgb2dvi_0 is
        port (
            TMDS_Clk_p  : out std_logic;
            TMDS_Clk_n  : out std_logic;
            TMDS_Data_p : out std_logic_vector(2 downto 0);
            TMDS_Data_n : out std_logic_vector(2 downto 0);
            aRst        : in  std_logic;
            vid_pData   : in  std_logic_vector(23 downto 0);
            vid_pVDE    : in  std_logic;
            vid_pHSync  : in  std_logic;
            vid_pVSync  : in  std_logic;
            PixelClk    : in  std_logic;
            SerialClk   : in  std_logic
        );
    end component;

    signal pixel_clk   : std_logic;
    signal clk_locked  : std_logic;
    signal hcount      : std_logic_vector(9 downto 0);
    signal vcount      : std_logic_vector(9 downto 0);
    signal vid         : std_logic;
    signal hs          : std_logic;
    signal vs          : std_logic;
    signal pixel       : std_logic_vector(7 downto 0);
    signal addr        : std_logic_vector(17 downto 0);
    signal r8          : std_logic_vector(7 downto 0);
    signal g8          : std_logic_vector(7 downto 0);
    signal b8          : std_logic_vector(7 downto 0);
    signal vid_pdata   : std_logic_vector(23 downto 0);
    signal encoder_rst : std_logic;
begin
    clk_wiz_gen : if not SIM_BYPASS_CLK_WIZ generate
        clkgen_i : clk_wiz_0
            port map (
                clk_out1 => pixel_clk,
                reset    => '0',
                locked   => clk_locked,
                clk_in1  => clk
            );
    end generate;

    sim_bypass_gen : if SIM_BYPASS_CLK_WIZ generate
        pixel_clk  <= clk;
        clk_locked <= '1';
    end generate;

    vga_ctrl_i : vga_ctrl
        port map (
            clk    => pixel_clk,
            enable => '1',
            hcount => hcount,
            vcount => vcount,
            vid    => vid,
            hs     => hs,
            vs     => vs
        );

    picture_i : picture
        port map (
            clka  => pixel_clk,
            addra => addr,
            douta => pixel
        );

    pixel_pusher_hdmi_i : pixel_pusher_hdmi
        port map (
            clk    => pixel_clk,
            enable => '1',
            vs     => vs,
            pixel  => pixel,
            hcount => hcount,
            vid    => vid,
            addr   => addr,
            r      => r8,
            g      => g8,
            b      => b8
        );

    vid_pdata <= r8 & g8 & b8;
    encoder_rst <= not clk_locked;

    rgb2dvi_i : rgb2dvi_0
        port map (
            TMDS_Clk_p  => hdmi_clk_p,
            TMDS_Clk_n  => hdmi_clk_n,
            TMDS_Data_p => hdmi_d_p,
            TMDS_Data_n => hdmi_d_n,
            aRst        => encoder_rst,
            vid_pData   => vid_pdata,
            vid_pVDE    => vid,
            vid_pHSync  => hs,
            vid_pVSync  => vs,
            PixelClk    => pixel_clk,
            SerialClk   => clk
        );

    hdmi_out_en <= '1';
end behavioral;

