library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wireframe_renderer_tb is
end wireframe_renderer_tb;

architecture behavioral of wireframe_renderer_tb is

    component wireframe_renderer is
        port (
            pclk, rst, video_active : in std_logic;
            hcount, vcount          : in std_logic_vector(9 downto 0);
            v0_x, v0_y, v1_x, v1_y  : in std_logic_vector(9 downto 0);
            v2_x, v2_y, v3_x, v3_y  : in std_logic_vector(9 downto 0);
            red, green, blue        : out std_logic_vector(7 downto 0)
        );
    end component;

    signal pclk         : std_logic := '0';
    signal rst          : std_logic := '0';
    signal video_active : std_logic := '1';
    
    signal hcount, vcount : std_logic_vector(9 downto 0) := (others => '0');
    
    -- Hardcode the coordinates we verified in Phase 3
    signal v0_x : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(348, 10));
    signal v0_y : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(76, 10));
    
    signal v1_x : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(548, 10));
    signal v1_y : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(76, 10));
    
    signal v2_x : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(548, 10));
    signal v2_y : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(276, 10));
    
    signal v3_x : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(348, 10));
    signal v3_y : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(276, 10));
    
    signal red, green, blue : std_logic_vector(7 downto 0);

    -- 25 MHz Pixel Clock = 40 ns period
    constant PCLK_PERIOD : time := 40 ns;

begin

    clk_process : process
    begin
        pclk <= '0'; wait for PCLK_PERIOD / 2;
        pclk <= '1'; wait for PCLK_PERIOD / 2;
    end process;

    dut : wireframe_renderer port map (
        pclk => pclk, rst => rst, video_active => video_active,
        hcount => hcount, vcount => vcount,
        v0_x => v0_x, v0_y => v0_y, v1_x => v1_x, v1_y => v1_y,
        v2_x => v2_x, v2_y => v2_y, v3_x => v3_x, v3_y => v3_y,
        red => red, green => green, blue => blue
    );

    stim : process
    begin
        rst <= '1';
        wait for 80 ns;
        rst <= '0';
        wait for 40 ns;
        
        -- Fast forward the monitor to scanline 76 (Where Vertex 0 is)
        vcount <= std_logic_vector(to_unsigned(76, 10));
        
        -- Sweep the horizontal pixel counter right before, across, and right after Vertex 0
        -- Vertex 0 X is at 348. The radius is 3. 
        -- It should light up White from X=345 to X=351.
        for i in 340 to 355 loop
            hcount <= std_logic_vector(to_unsigned(i, 10));
            wait for PCLK_PERIOD;
        end loop;

        wait for 100 ns;
        std.env.stop;
    end process;

end behavioral;