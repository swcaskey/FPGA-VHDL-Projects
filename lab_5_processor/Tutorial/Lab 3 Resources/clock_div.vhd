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
    -- For 115,200 Hz from 125 MHz: 125,000,000 / 115,200 = 1085 (rounded)
    -- Count from 0 to 1084 (1085 cycles)
    -- Need 11 bits: 2^11 = 2048 > 1085
    signal counter : unsigned(10 downto 0) := (others => '0');
   
begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- Check if we reached the limit (1085 - 1 = 1084)
            if (counter = 1084) then
                counter <= (others => '0');
                div <= '1'; -- Generate 1-cycle pulse at 115,200 Hz
            else
                counter <= counter + 1;
                div <= '0';
            end if;
        end if;
    end process;
end behavioral;