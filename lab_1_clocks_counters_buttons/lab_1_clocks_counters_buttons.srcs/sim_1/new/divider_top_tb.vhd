-- Set sim time to 500ms

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity divider_top_tb is
end divider_top_tb;

architecture testbench of divider_top_tb is

    -- Component Declaration
    component divider_top is
        port (
            clk  : in std_logic;
            led0 : out std_logic
        );
    end component;

    -- Signals
    signal clk_tb  : std_logic := '0';
    signal led0_tb : std_logic;

    -- Clock period definitions (125 MHz = 8 ns)
    constant clk_period : time := 8 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: divider_top
    port map (
        clk  => clk_tb,
        led0 => led0_tb
    );

    -- Clock process definitions
    clk_process : process
    begin
        clk_tb <= '0';
        wait for clk_period/2;
        clk_tb <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Hold reset state (if you had one)
        wait for 100 ns;

        -- Let the simulation run.
        -- To see 2 full LED toggles (1 second), we need 125,000,000 cycles.
        -- In a real waveform viewer, you might want to reduce the counter limit
        -- in clock_div.vhd temporarily to test the logic faster (e.g., count to 10),
        -- but for the lab requirement, we loop here.
       
        -- This wait is arbitrary; usually, you just run the sim for "1 sec" in the tool settings.
        wait;
    end process;

end testbench;