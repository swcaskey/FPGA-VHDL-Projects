library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_clock_en is
    port (
        clk_125mhz  : in  std_logic;
        spi_en_1mhz : out std_logic
    );
end spi_clock_en;

architecture behavioral of spi_clock_en is
    -- 125 MHz / 1 MHz = 125. We count from 0 to 124.
    -- 7 bits required (2^7 = 128)
    signal counter : unsigned(6 downto 0) := (others => '0');
begin
    process(clk_125mhz)
    begin
        if rising_edge(clk_125mhz) then
            if counter = 124 then
                counter <= (others => '0');
                spi_en_1mhz <= '1';
            else
                counter <= counter + 1;
                spi_en_1mhz <= '0';
            end if;
        end if;
    end process;
end behavioral;