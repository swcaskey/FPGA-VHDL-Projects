-- Set sim time to 500us

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debounce_tb is
end debounce_tb;

architecture testbench of debounce_tb is
    component debounce is
        generic (
            clk_freq    : integer;
            stable_time : integer
        );
        port (
            clk  : in  std_logic;
            btn  : in  std_logic;
            dbnc : out std_logic
        );
    end component;

    signal clk_tb  : std_logic := '0';
    signal btn_tb  : std_logic := '0';
    signal dbnc_tb : std_logic;

    constant clk_period : time := 8 ns; -- 125 MHz

begin
    -- Instantiate with a shorter time for simulation (1 ms)
    uut: debounce
    generic map (
        clk_freq    => 125_000_000,
        stable_time => 1 -- Wait only 1 ms for simulation
    )
    port map (
        clk  => clk_tb,
        btn  => btn_tb,
        dbnc => dbnc_tb
    );

    clk_proc: process
    begin
        clk_tb <= '0';
        wait for clk_period/2;
        clk_tb <= '1';
        wait for clk_period/2;
    end process;

    stim_proc: process
    begin
        wait for 100 ns;
       
        -- Toggle button rapidly
        btn_tb <= '1'; wait for 50 us;
        btn_tb <= '0'; wait for 50 us;
        btn_tb <= '1'; wait for 50 us;
        btn_tb <= '0'; wait for 50 us;
       
        -- Stable press
        btn_tb <= '1';
       
        -- Wait for  stable time (1 ms) + buffer
        wait for 2 ms;
       
        -- Release button
        btn_tb <= '0';
        wait;
    end process;

end testbench;