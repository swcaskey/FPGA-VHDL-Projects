-- Set sim time to 2us

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

    -- Signals
    signal clk_tb    : std_logic := '0';
    signal clk_en_tb : std_logic := '0';
    signal dir_tb    : std_logic := '0';
    signal en_tb     : std_logic := '0';
    signal ld_tb     : std_logic := '0';
    signal rst_tb    : std_logic := '0';
    signal updn_tb   : std_logic := '0';
    signal val_tb    : std_logic_vector(3 downto 0) := "0000";
    signal cnt_tb    : std_logic_vector(3 downto 0);

    constant clk_period : time := 8 ns;

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

    -- Clock Generation
    clk_process: process
    begin
        clk_tb <= '0';
        wait for clk_period/2;
        clk_tb <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus Process
    stim_proc: process
    begin
        -- Initialize inputs
        en_tb <= '0';
        rst_tb <= '1';
        wait for 100 ns;

        -- 1. RELEASE RESET (Synchronized)
        wait until rising_edge(clk_tb);
        rst_tb <= '0';
       
        -- 2. CONFIGURE: Load value 5, Dir Up
        wait until rising_edge(clk_tb);
        en_tb <= '1';
        val_tb <= "0101"; -- Limit = 5
        ld_tb <= '1';     -- Load Value
        dir_tb <= '0';    -- Up
        updn_tb <= '1';   -- Update Dir
       
        -- Hold config for 1 cycle
        wait until rising_edge(clk_tb);
        ld_tb <= '0';
        updn_tb <= '0';
       
        -- 3. COUNT UP (Pulse clk_en 10 times)
        -- Should count: 0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 0 ...
        for i in 0 to 10 loop
            wait until rising_edge(clk_tb);
            clk_en_tb <= '1';  -- Pulse Enable
            wait until rising_edge(clk_tb);
            clk_en_tb <= '0';
           
            -- Wait a few cycles between counts to see it clearly
            wait until rising_edge(clk_tb);
            wait until rising_edge(clk_tb);
        end loop;
       
        -- 4. CHANGE DIRECTION (Down)
        wait until rising_edge(clk_tb);
        dir_tb <= '1';  -- Down
        updn_tb <= '1'; -- Update
        wait until rising_edge(clk_tb);
        updn_tb <= '0';
       
        -- 5. COUNT DOWN
        -- Should count: 0 -> 5 -> 4 -> 3 ...
        for i in 0 to 10 loop
            wait until rising_edge(clk_tb);
            clk_en_tb <= '1';
            wait until rising_edge(clk_tb);
            clk_en_tb <= '0';
            wait until rising_edge(clk_tb);
            wait until rising_edge(clk_tb);
        end loop;

        -- End Simulation
        wait;
    end process;

end testbench;