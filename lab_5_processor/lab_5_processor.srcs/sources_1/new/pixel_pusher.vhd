library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pixel_pusher is
    port (
        clk : in std_logic;
        en  : in std_logic;
        hcount : in std_logic_vector(9 downto 0);
        vcount : in std_logic_vector(9 downto 0);
        vid : in std_logic;
        vs  : in std_logic;
        pixel : in std_logic_vector(15 downto 0);
        addr : out std_logic_vector(11 downto 0);
        R : out std_logic_vector(4 downto 0);
        G : out std_logic_vector(5 downto 0);
        B : out std_logic_vector(4 downto 0)
    );
end pixel_pusher;

architecture rtl of pixel_pusher is
    signal h_reg : std_logic_vector(9 downto 0) := (others => '0');
    signal v_reg : std_logic_vector(9 downto 0) := (others => '0');
    signal vid_reg : std_logic := '0';
begin
    
    process(clk)
    begin
        if rising_edge(clk) then
            if en = '1' then
                h_reg <= hcount;
                v_reg <= vcount;
                vid_reg <= vid;
            end if;
        end if;
    end process;
    
    -- Calculate address: 64x64 framebuffer with 12-bit address
    -- addr = v*64 + h (for 64x64 resolution)
    -- But we need to handle larger hcount/vcount space
    addr <= std_logic_vector(to_unsigned(
        (to_integer(unsigned(h_reg(5 downto 0))) + 
         to_integer(unsigned(v_reg(5 downto 0))) * 64),
        12
    ));
    
    -- Pixel format: [R(4:0)][G(5:0)][B(4:0)]
    -- Extract color components from 16-bit pixel
    R <= pixel(15 downto 11);
    G <= pixel(10 downto 5);
    B <= pixel(4 downto 0);
    
end rtl;
