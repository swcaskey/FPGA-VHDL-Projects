library ieee;
use ieee.std_logic_1164.all;

entity jstk2_controller_tb is
end jstk2_controller_tb;

architecture behavioral of jstk2_controller_tb is

    component jstk2_controller is
        port (
            clk        : in  std_logic;
            rst        : in  std_logic;
            start_read : in  std_logic;
            data_valid : out std_logic;
            x_out      : out std_logic_vector(15 downto 0);
            y_out      : out std_logic_vector(15 downto 0);
            joystick_btn : out std_logic;
            spi_ready  : in  std_logic;
            spi_data_in: in  std_logic_vector(7 downto 0);
            spi_start  : out std_logic;
            spi_data_out: out std_logic_vector(7 downto 0);
            cs_jstk    : out std_logic
        );
    end component;

    signal clk        : std_logic := '0';
    signal rst        : std_logic := '0';
    signal start_read : std_logic := '0';
    signal data_valid : std_logic;
    signal x_out      : std_logic_vector(15 downto 0);
    signal y_out      : std_logic_vector(15 downto 0);
    signal joystick_btn : std_logic;
    
    signal spi_ready  : std_logic := '1';
    signal spi_data_in: std_logic_vector(7 downto 0) := x"00";
    signal spi_start  : std_logic;
    signal spi_data_out: std_logic_vector(7 downto 0);
    signal cs_jstk    : std_logic;

    constant CLK_PERIOD : time := 8 ns;

begin

    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    dut : jstk2_controller
        port map (
            clk => clk, rst => rst, start_read => start_read,
            data_valid => data_valid, x_out => x_out, y_out => y_out,
            joystick_btn => joystick_btn,
            spi_ready => spi_ready, spi_data_in => spi_data_in,
            spi_start => spi_start, spi_data_out => spi_data_out,
            cs_jstk => cs_jstk
        );

    -- Mock SPI Master behavior
    spi_mock : process
    begin
        wait until rising_edge(spi_start);
        spi_ready <= '0';
        wait for 1 us; 
        
        -- Feed dummy JSTK2 bytes: X_L, X_H, Y_L, Y_H, Buttons
        if spi_data_in = x"00" then spi_data_in <= x"AA"; -- X Low
        elsif spi_data_in = x"AA" then spi_data_in <= x"03"; -- X High
        elsif spi_data_in = x"03" then spi_data_in <= x"BB"; -- Y Low
        elsif spi_data_in = x"BB" then spi_data_in <= x"01"; -- Y High
        else spi_data_in <= x"01"; -- Button byte (Center button pressed)
        end if;
        
        spi_ready <= '1';
    end process;

    -- Stimulus
    stim : process
    begin
        rst <= '1';
        wait for 1 us;
        rst <= '0';
        wait for 1 us;
        
        -- Trigger a read
        start_read <= '1';
        wait until data_valid = '1';
        start_read <= '0';
        
        wait for 2 us;
        std.env.stop;
    end process;

end behavioral;