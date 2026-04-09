library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_div is
    port (
        clk : in std_logic;
        div : out std_logic
    );
end clock_div;

architecture behavioral of clock_div is
    -- For 25 MHz from 125 MHz: 125,000,000 / 25,000,000 = 5
    -- Count from 0 to 4 (5 cycles), enable pulse on every 5th cycle
    -- Need 3 bits: 2^3 = 8 > 4
    signal counter : unsigned(2 downto 0) := (others => '0');
   
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if (counter = 4) then
                counter <= (others => '0');
                div <= '1';  -- Generate 1-cycle pulse at 25 MHz
            else
                counter <= counter + 1;
                div <= '0';
            end if;
        end if;
    end process;
end behavioral;