library ieee;
use ieee.std_logic_1164.all;

entity nav_imu_controller_tb is
end nav_imu_controller_tb;

architecture behavioral of nav_imu_controller_tb is

    component nav_imu_controller is
        port (
            clk        : in  std_logic;
            rst        : in  std_logic;
            start_read : in  std_logic;
            data_valid : out std_logic;
            pitch_out  : out std_logic_vector(15 downto 0);
            roll_out   : out std_logic_vector(15 downto 0);
            yaw_out    : out std_logic_vector(15 downto 0);
            spi_ready  : in  std_logic;
            spi_data_in: in  std_logic_vector(7 downto 0);
            spi_start  : out std_logic;
            spi_data_out: out std_logic_vector(7 downto 0);
            cs_ag      : out std_logic
        );
    end component;

    signal clk        : std_logic := '0';
    signal rst        : std_logic := '0';
    signal start_read : std_logic := '0';
    signal data_valid : std_logic;
    signal pitch_out  : std_logic_vector(15 downto 0);
    signal roll_out   : std_logic_vector(15 downto 0);
    signal yaw_out    : std_logic_vector(15 downto 0);
    
    signal spi_ready  : std_logic := '1';
    signal spi_data_in: std_logic_vector(7 downto 0) := x"00";
    signal spi_start  : std_logic;
    signal spi_data_out: std_logic_vector(7 downto 0);
    signal cs_ag      : std_logic;

    constant CLK_PERIOD : time := 8 ns;

begin

    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    dut : nav_imu_controller
        port map (
            clk => clk, rst => rst, start_read => start_read,
            data_valid => data_valid, pitch_out => pitch_out,
            roll_out => roll_out, yaw_out => yaw_out,
            spi_ready => spi_ready, spi_data_in => spi_data_in,
            spi_start => spi_start, spi_data_out => spi_data_out,
            cs_ag => cs_ag
        );

    -- Mock SPI Master behavior
    spi_mock : process
    begin
        wait until rising_edge(spi_start);
        spi_ready <= '0';
        wait for 1 us; -- Simulate time taken to transfer a byte
        
        -- Feed dummy data back depending on what is being requested
        if spi_data_out = x"98" then
            spi_data_in <= x"00"; -- Address ACK
        else
            -- Just cycle through some dummy bytes: 11, 22, 33, 44, 55, 66
            if spi_data_in = x"00" then spi_data_in <= x"11";
            elsif spi_data_in = x"11" then spi_data_in <= x"22";
            elsif spi_data_in = x"22" then spi_data_in <= x"33";
            elsif spi_data_in = x"33" then spi_data_in <= x"44";
            elsif spi_data_in = x"44" then spi_data_in <= x"55";
            else spi_data_in <= x"66";
            end if;
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