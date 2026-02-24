-- Set sim time to 10us

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fancy_counter_tb is
end fancy_counter_tb;

architecture testbench of fancy_counter_tb is
    component fancy_counter is
        port (
            clk     : in  std_logic;
            clk_en  : in  std_logic;
            dir     : in  std_logic;
            en      : in  std_logic;
            ld      : in  std_logic;
            rst     : in  std_logic;
            updn    : in  std_logic;
            val     : in  std_logic_vector(3 downto 0);
            cnt     : out std_logic_vector(3 downto 0)
        );
    end component;

    signal clk_tb    : std_logic := '0';
    signal clk_en_tb : std_logic := '1';
    signal dir_tb    : std_logic := '0';
    signal en_tb     : std_logic := '1';
    signal ld_tb     : std_logic := '0';
    signal rst_tb    : std_logic := '0';
    signal updn_tb   : std_logic := '0';
    signal val_tb    : std_logic_vector(3 downto 0) := "1111"; -- Limit is 15 (F)
    signal cnt_tb    : std_logic_vector(3 downto 0);

    constant clk_period : time := 2 ns;

begin

    uut: fancy_counter
    port map (
        clk     => clk_tb,
        clk_en  => clk_en_tb,
        dir     => dir_tb,
        en      => en_tb,
        ld      => ld_tb,
        rst     => rst_tb,
        updn    => updn_tb,
        val     => val_tb,
        cnt     => cnt_tb
    );

    -- Clock Gen
    clk_process: process
    begin
        clk_tb <= '0';
        wait for clk_period/2;
        clk_tb <= '1';
        wait for clk_period/2;
    end process;

    stim_proc: process
    begin
        -- wait for the 32 ns duration to see the full 0 -> F -> 0 cycle
        wait for 32 ns;
        wait;
    end process;

end testbench;