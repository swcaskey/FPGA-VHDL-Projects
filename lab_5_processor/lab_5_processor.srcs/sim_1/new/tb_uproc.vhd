library ieee;
use ieee.std_logic_1164.all;

entity tb_uproc is
end tb_uproc;

architecture behavior of tb_uproc is

    -- Component Declaration for the Unit Under Test (UUT)
    component uproc_top_level
    port(
         clk    : in  std_logic;
         btn_0  : in  std_logic;
         TXD    : in  std_logic;
         RXD    : out std_logic;
         CTS    : inout std_logic;
         RTS    : inout std_logic;
         vga_r  : out std_logic_vector(4 downto 0);
         vga_g  : out std_logic_vector(5 downto 0);
         vga_b  : out std_logic_vector(4 downto 0);
         vga_hs : out std_logic;
         vga_vs : out std_logic
        );
    end component;

    -- Inputs
    signal clk   : std_logic := '0';
    signal btn_0 : std_logic := '0';
    signal TXD   : std_logic := '1'; -- UART idle is high

    -- Outputs and Inouts
    signal RXD    : std_logic;
    signal CTS    : std_logic;
    signal RTS    : std_logic;
    signal vga_r  : std_logic_vector(4 downto 0);
    signal vga_g  : std_logic_vector(5 downto 0);
    signal vga_b  : std_logic_vector(4 downto 0);
    signal vga_hs : std_logic;
    signal vga_vs : std_logic;

    -- Clock period definitions (125 MHz)
    constant clk_period : time := 8 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: uproc_top_level port map (
          clk => clk,
          btn_0 => btn_0,
          TXD => TXD,
          RXD => RXD,
          CTS => CTS,
          RTS => RTS,
          vga_r => vga_r,
          vga_g => vga_g,
          vga_b => vga_b,
          vga_hs => vga_hs,
          vga_vs => vga_vs
        );

    -- Clock process definitions
    clk_process :process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin		
        -- Hold reset state for 50 ms to ensure the debouncer clears
        btn_0 <= '1';
        wait for 50 ms;	
        
        -- Release reset and let the processor run
        btn_0 <= '0';
        
        -- Let the processor execute for a long time
        -- (UART transmission is slow, so we wait 100ms)
        wait for 100 ms;

        wait;
    end process;

end behavior;