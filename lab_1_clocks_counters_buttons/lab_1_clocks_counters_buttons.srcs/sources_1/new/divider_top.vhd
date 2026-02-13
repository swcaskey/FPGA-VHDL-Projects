library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity divider_top is
    port(
        -- Clock
        clk  : in  std_logic;
        div : out std_logic;
        
        -- D Flip flop
        CE  : in std_logic;
        D   : in std_logic;
        Q   : out std_logic
    );
end divider_top;

architecture behavioral of divider_top is

begin
    -- Clock
    U1: entity work.clock_div
        port map (
            clk => clk,
            div => div
        );
    
    -- D Flip flop
    process (CLK)
    begin
        -- Finish
    end process;
end behavioral;