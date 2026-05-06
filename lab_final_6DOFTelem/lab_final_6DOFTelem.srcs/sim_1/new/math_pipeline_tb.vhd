library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity math_pipeline_tb is
end math_pipeline_tb;

architecture behavioral of math_pipeline_tb is

    component math_pipeline is
        port (
            clk, rst, start : in std_logic;
            pitch, roll, yaw: in std_logic_vector(15 downto 0);
            jstk_x, jstk_y  : in std_logic_vector(15 downto 0);
            v0_x, v0_y      : out std_logic_vector(9 downto 0);
            v1_x, v1_y      : out std_logic_vector(9 downto 0);
            v2_x, v2_y      : out std_logic_vector(9 downto 0);
            v3_x, v3_y      : out std_logic_vector(9 downto 0);
            done            : out std_logic
        );
    end component;

    signal clk   : std_logic := '0';
    signal rst   : std_logic := '0';
    signal start : std_logic := '0';
    
    signal pitch, roll, yaw : std_logic_vector(15 downto 0) := (others => '0');
    signal jstk_x, jstk_y   : std_logic_vector(15 downto 0) := (others => '0');
    
    signal v0_x, v0_y, v1_x, v1_y : std_logic_vector(9 downto 0);
    signal v2_x, v2_y, v3_x, v3_y : std_logic_vector(9 downto 0);
    signal done : std_logic;

    constant CLK_PERIOD : time := 8 ns; -- 125 MHz system clock

begin

    clk_process : process
    begin
        clk <= '0'; wait for CLK_PERIOD / 2;
        clk <= '1'; wait for CLK_PERIOD / 2;
    end process;

    dut : math_pipeline port map (
        clk => clk, rst => rst, start => start,
        pitch => pitch, roll => roll, yaw => yaw,
        jstk_x => jstk_x, jstk_y => jstk_y,
        v0_x => v0_x, v0_y => v0_y, v1_x => v1_x, v1_y => v1_y,
        v2_x => v2_x, v2_y => v2_y, v3_x => v3_x, v3_y => v3_y,
        done => done
    );

    stim : process
    begin
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        wait for 20 ns;
        
        -- Simulate pushing the JSTK2 hard right and slightly up
        jstk_x <= std_logic_vector(to_signed(4096, 16));
        jstk_y <= std_logic_vector(to_signed(-2048, 16));
        
        -- Trigger the math pipeline
        start <= '1';
        wait until done = '1';
        start <= '0';
        
        wait for 50 ns;
        std.env.stop;
    end process;

end behavioral;