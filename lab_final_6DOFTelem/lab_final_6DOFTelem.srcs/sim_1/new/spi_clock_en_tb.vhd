library ieee;
use ieee.std_logic_1164.all;

entity spi_clock_en_tb is
end spi_clock_en_tb;

architecture behavioral of spi_clock_en_tb is
    
    component spi_clock_en is
        port (
            clk_125mhz  : in  std_logic;
            spi_en_1mhz : out std_logic
        );
    end component;
    
    signal clk_125mhz  : std_logic := '0';
    signal spi_en_1mhz : std_logic;
    
    -- 125 MHz = 8 ns period
    constant CLK_PERIOD : time := 8 ns; 
    
begin

    -- Generate the 125 MHz hardware clock
    clk_process : process
    begin
        clk_125mhz <= '0';
        wait for CLK_PERIOD / 2;
        clk_125mhz <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Instantiate the Device Under Test (DUT)
    dut : spi_clock_en
        port map (
            clk_125mhz  => clk_125mhz,
            spi_en_1mhz => spi_en_1mhz
        );

    -- Run the simulation for 10 microseconds to capture 10 full SPI cycles
    stim : process
    begin
        wait for 10 us; 
        std.env.stop;
    end process;

end behavioral;