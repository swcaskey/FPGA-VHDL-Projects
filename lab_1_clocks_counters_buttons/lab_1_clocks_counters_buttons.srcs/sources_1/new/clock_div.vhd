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
    -- We need to count up to 62,500,000.
    -- Therefre we need 26 bits, 2^26 = 67,108,864, to hold count
    signal counter : unsigned(25 downto 0) := (others => '0');
   
begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- Check if we reached the limit (62,500,000 - 1) like Lab0
            if (counter = 62499999) then
                counter <= (others => '0');
                div <= '1'; -- Generate 1-cycle pulse. 2 Hz.
            else
                counter <= counter + 1;
                div <= '0';
            end if;
        end if;
    end process;
end behavioral;