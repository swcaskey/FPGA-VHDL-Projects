library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_div_25 is
    port (
        CLK : in std_logic;
        DIV : out std_logic
    );
end clock_div_25;

architecture behavioral of clock_div_25 is
    -- For 25 MHz from 125 MHz: 125,000,000 / 25,000,000 = 5
    -- Count from 0 to 4 (5 cycles), output pulse every 5 cycles
    signal counter : unsigned(2 downto 0) := (others => '0');
begin
    process(CLK)
    begin
        if rising_edge(CLK) then
            if (counter = 4) then
                counter <= (others => '0');
                DIV <= '1';
            else
                counter <= counter + 1;
                DIV <= '0';
            end if;
        end if;
    end process;
end behavioral;
