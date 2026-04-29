library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_master_tb is
end spi_master_tb;

architecture behavioral of spi_master_tb is
    component spi_master is
        port (
            clk      : in  std_logic;
            spi_en   : in  std_logic;
            rst      : in  std_logic;
            start    : in  std_logic;
            data_in  : in  std_logic_vector(7 downto 0);
            data_out : out std_logic_vector(7 downto 0);
            ready    : out std_logic;
            mosi     : out std_logic;
            miso     : in  std_logic;
            sclk     : out std_logic
        );
    end component;

    signal clk      : std_logic := '0';
    signal spi_en   : std_logic := '0';
    signal rst      : std_logic := '0';
    signal start    : std_logic := '0';
    signal data_in  : std_logic_vector(7 downto 0) := x"C3"; -- 11000011
    signal data_out : std_logic_vector(7 downto 0);
    signal ready    : std_logic;
    signal mosi     : std_logic;
    signal miso     : std_logic := '0';
    signal sclk     : std_logic;

    constant CLK_PERIOD : time := 8 ns;
    signal clk_count : integer := 0;

begin

    -- 125 MHz Clock Generator
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- 1 MHz spi_en Generator (Simulating your spi_clock_en.vhd)
    spi_en_process : process(clk)
    begin
        if rising_edge(clk) then
            if clk_count = 124 then
                clk_count <= 0;
                spi_en <= '1';
            else
                clk_count <= clk_count + 1;
                spi_en <= '0';
            end if;
        end if;
    end process;

    -- Fake Slave Device (Sends 0xAA = 10101010)
    slave_process : process(sclk)
        variable dummy_data : std_logic_vector(7 downto 0) := x"AA";
        variable bit_idx : integer := 7;
    begin
        if falling_edge(sclk) then
            miso <= dummy_data(bit_idx);
            if bit_idx = 0 then
                bit_idx := 7;
            else
                bit_idx := bit_idx - 1;
            end if;
        end if;
    end process;

    dut : spi_master
        port map (
            clk => clk, spi_en => spi_en, rst => rst,
            start => start, data_in => data_in, data_out => data_out,
            ready => ready, mosi => mosi, miso => miso, sclk => sclk
        );

    -- Stimulus
    stim : process
    begin
        rst <= '1';
        wait for 2 us;
        rst <= '0';
        wait for 2 us;
        
        -- Start transmission
        start <= '1';
        wait for 2 us;
        start <= '0';
        
        -- Wait for transaction to finish (16 us total for 8 bits at 500 kHz)
        wait for 20 us;
        std.env.stop;
    end process;

end behavioral;