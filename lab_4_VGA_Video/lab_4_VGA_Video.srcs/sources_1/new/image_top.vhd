library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity image_top is
    port (
        clk : in std_logic;
        vga_hs : out std_logic;
        vga_vs : out std_logic;
        vga_r : out std_logic_vector(4 downto 0);
        vga_g : out std_logic_vector(5 downto 0);
        vga_b : out std_logic_vector(4 downto 0)
    );
end image_top;

architecture behavioral of image_top is
    -- Component declarations
    component clock_div is
        port (
            clk : in std_logic;
            div : out std_logic
        );
    end component;
    
    component vga_ctrl is
        port (
            clk : in std_logic;
            enable : in std_logic;
            hcount : out std_logic_vector(9 downto 0);
            vcount : out std_logic_vector(9 downto 0);
            vid : out std_logic;
            hs : out std_logic;
            vs : out std_logic
        );
    end component;
    
    component pixel_pusher is
        port (
            clk : in std_logic;
            enable : in std_logic;
            vs : in std_logic;
            pixel : in std_logic_vector(7 downto 0);
            hcount : in std_logic_vector(9 downto 0);
            vid : in std_logic;
            addr : out std_logic_vector(17 downto 0);
            r : out std_logic_vector(4 downto 0);
            g : out std_logic_vector(5 downto 0);
            b : out std_logic_vector(4 downto 0)
        );
    end component;
    
    component picture is
        port (
            clka : in std_logic;
            ena : in std_logic;
            addra : in std_logic_vector(17 downto 0);
            douta : out std_logic_vector(7 downto 0)
        );
    end component;
    
    -- Internal signals
    signal clk_enable : std_logic;
    signal hcount : std_logic_vector(9 downto 0);
    signal vcount : std_logic_vector(9 downto 0);
    signal vid : std_logic;
    signal hs : std_logic;
    signal vs : std_logic;
    signal pixel : std_logic_vector(7 downto 0);
    signal addr : std_logic_vector(17 downto 0);
    
begin
    -- Instantiate clock divider to generate 25 MHz enable from 125 MHz
    clk_div_inst : clock_div
        port map (
            clk => clk,
            div => clk_enable
        );
    
    -- Instantiate VGA controller
    vga_ctrl_inst : vga_ctrl
        port map (
            clk => clk,
            enable => clk_enable,
            hcount => hcount,
            vcount => vcount,
            vid => vid,
            hs => hs,
            vs => vs
        );
    
    -- Instantiate picture ROM
    picture_inst : picture
        port map (
            clka => clk,
            ena => '1',
            addra => addr,
            douta => pixel
        );
    
    -- Instantiate pixel pusher
    pixel_pusher_inst : pixel_pusher
        port map (
            clk => clk,
            enable => clk_enable,
            vs => vs,
            pixel => pixel,
            hcount => hcount,
            vid => vid,
            addr => addr,
            r => vga_r,
            g => vga_g,
            b => vga_b
        );
    
    -- Output sync signals
    vga_hs <= hs;
    vga_vs <= vs;
    
end behavioral;
