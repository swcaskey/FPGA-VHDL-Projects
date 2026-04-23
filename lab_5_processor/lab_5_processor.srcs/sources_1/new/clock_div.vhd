library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_div is
    port (
        CLK : in std_logic;
        DIV : out std_logic
    );
end clock_div;

architecture behavioral of clock_div is
    -- For 115,200 Hz from 125 MHz: 125,000,000 / 115,200 = 1085 (rounded)
    -- Count from 0 to 1084 (1085 cycles)
    signal counter : unsigned(10 downto 0) := (others => '0');
begin
    process(CLK)
    begin
        if rising_edge(CLK) then
            if (counter = 1084) then
                counter <= (others => '0');
                DIV <= '1';
            else
                counter <= counter + 1;
                DIV <= '0';
            end if;
        end if;
    end process;
end behavioral;
