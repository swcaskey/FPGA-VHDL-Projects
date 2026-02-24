-- Set sim time to 500ms

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity divider_top_tb is
end divider_top_tb;

architecture testbench of divider_top_tb is
    component divider_top is
        port (
            clk  : in std_logic;
            led0 : out std_logic
        );
    end component;

    -- Signals
    signal clk_tb  : std_logic := '0';
    signal led0_tb : std_logic;

    -- Clock period (125 MHz = 8 ns)
    constant clk_period : time := 8 ns;

begin

    -- Instantiate
    uut: divider_top
    port map (
        clk  => clk_tb,
        led0 => led0_tb
    );

    clk_process : process
    begin
        clk_tb <= '0';
        wait for clk_period/2;
        clk_tb <= '1';
        wait for clk_period/2;
    end process;

    stim_proc: process
    begin
        -- Hold reset state
        wait for 100 ns;
        -- Let the simulation run.
        -- To see 2 full LED toggles (1 second), we need 125,000,000 cycles.
        wait;
    end process;

end testbench;