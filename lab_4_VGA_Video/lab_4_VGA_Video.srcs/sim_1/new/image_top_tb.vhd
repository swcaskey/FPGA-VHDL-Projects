library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity image_top_tb is
end image_top_tb;

architecture behavioral of image_top_tb is
    component image_top is
        port (
            clk : in std_logic;
            vga_hs : out std_logic;
            vga_vs : out std_logic;
            vga_r : out std_logic_vector(4 downto 0);
            vga_g : out std_logic_vector(5 downto 0);
            vga_b : out std_logic_vector(4 downto 0)
        );
    end component;
    
    signal clk : std_logic := '0';
    signal vga_hs : std_logic;
    signal vga_vs : std_logic;
    signal vga_r : std_logic_vector(4 downto 0);
    signal vga_g : std_logic_vector(5 downto 0);
    signal vga_b : std_logic_vector(4 downto 0);
    
    constant CLK_PERIOD : time := 8 ns;  -- 125 MHz clock
    
begin
    -- Clock generation
    process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;
    
    -- Instantiate DUT
    dut : image_top
        port map (
            clk => clk,
            vga_hs => vga_hs,
            vga_vs => vga_vs,
            vga_r => vga_r,
            vga_g => vga_g,
            vga_b => vga_b
        );
    
    -- Stimulus process - run for a few frames
    process
    begin
        -- Simulate about 5 frames (to see VS toggling)
        -- At 25 MHz, one frame = 16.68 ms
        -- 5 frames = ~84 ms
        wait for 100 ms;
        wait;
    end process;
    
end behavioral;
