library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wireframe_renderer is
    port (
        pclk         : in  std_logic; -- 25 MHz Pixel Clock
        rst          : in  std_logic;
        
        -- VGA timing signals (from vga_ctrl.vhd)
        video_active : in  std_logic;
        hcount       : in  std_logic_vector(9 downto 0);
        vcount       : in  std_logic_vector(9 downto 0);
        
        -- 2D Projected Vertices (from math_pipeline.vhd)
        v0_x, v0_y   : in  std_logic_vector(9 downto 0);
        v1_x, v1_y   : in  std_logic_vector(9 downto 0);
        v2_x, v2_y   : in  std_logic_vector(9 downto 0);
        v3_x, v3_y   : in  std_logic_vector(9 downto 0);
        
        -- RGB Output to rgb2dvi IP (24-bit color)
        red          : out std_logic_vector(7 downto 0);
        green        : out std_logic_vector(7 downto 0);
        blue         : out std_logic_vector(7 downto 0)
    );
end wireframe_renderer;

architecture behavioral of wireframe_renderer is
    -- Draw a 7x7 pixel block for each vertex (Radius of 3 pixels)
    constant P_SIZE : integer := 3; 
begin
    process(pclk)
        variable h_int : integer;
        variable v_int : integer;
    begin
        if rising_edge(pclk) then
            if rst = '1' then
                red   <= (others => '0');
                green <= (others => '0');
                blue  <= (others => '0');
            elsif video_active = '1' then
                h_int := to_integer(unsigned(hcount));
                v_int := to_integer(unsigned(vcount));
                
                -- Check if current pixel is within the bounding box of any vertex
                if  (abs(h_int - to_integer(unsigned(v0_x))) <= P_SIZE and abs(v_int - to_integer(unsigned(v0_y))) <= P_SIZE) or
                    (abs(h_int - to_integer(unsigned(v1_x))) <= P_SIZE and abs(v_int - to_integer(unsigned(v1_y))) <= P_SIZE) or
                    (abs(h_int - to_integer(unsigned(v2_x))) <= P_SIZE and abs(v_int - to_integer(unsigned(v2_y))) <= P_SIZE) or
                    (abs(h_int - to_integer(unsigned(v3_x))) <= P_SIZE and abs(v_int - to_integer(unsigned(v3_y))) <= P_SIZE) then
                    
                    -- On a vertex -> Draw White
                    red   <= x"FF";
                    green <= x"FF";
                    blue  <= x"FF";
                else
                    -- Empty space -> Draw Black
                    red   <= x"00";
                    green <= x"00";
                    blue  <= x"00";
                end if;
            else
                -- Monitor blanking interval (Must be black to maintain sync)
                red   <= x"00";
                green <= x"00";
                blue  <= x"00";
            end if;
        end if;
    end process;
end behavioral;