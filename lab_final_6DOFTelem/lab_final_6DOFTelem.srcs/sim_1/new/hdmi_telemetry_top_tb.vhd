library ieee;
use ieee.std_logic_1164.all;

entity hdmi_telemetry_top_tb is
end hdmi_telemetry_top_tb;

architecture behavioral of hdmi_telemetry_top_tb is

    component hdmi_telemetry_top is
        port (
            sysclk      : in  std_logic;
            btn         : in  std_logic_vector(0 downto 0);
            nav_mosi    : out std_logic;
            nav_miso    : in  std_logic;
            nav_sclk    : out std_logic;
            nav_cs      : out std_logic;
            jstk_mosi   : out std_logic;
            jstk_miso   : in  std_logic;
            jstk_sclk   : out std_logic;
            jstk_cs     : out std_logic;
            TMDS_Clk_p  : out std_logic;
            TMDS_Clk_n  : out std_logic;
            TMDS_Data_p : out std_logic_vector(2 downto 0);
            TMDS_Data_n : out std_logic_vector(2 downto 0)
        );
    end component;

    signal sysclk      : std_logic := '0';
    signal btn         : std_logic_vector(0 downto 0) := "1"; -- Start in reset
    
    signal nav_mosi    : std_logic;
    signal nav_miso    : std_logic := '0';
    signal nav_sclk    : std_logic;
    signal nav_cs      : std_logic;
    
    signal jstk_mosi   : std_logic;
    signal jstk_miso   : std_logic := '0';
    signal jstk_sclk   : std_logic;
    signal jstk_cs     : std_logic;
    
    signal TMDS_Clk_p  : std_logic;
    signal TMDS_Clk_n  : std_logic;
    signal TMDS_Data_p : std_logic_vector(2 downto 0);
    signal TMDS_Data_n : std_logic_vector(2 downto 0);

    constant CLK_PERIOD : time := 8 ns;

begin

    clk_process : process
    begin
        sysclk <= '0'; wait for CLK_PERIOD / 2;
        sysclk <= '1'; wait for CLK_PERIOD / 2;
    end process;

    dut : hdmi_telemetry_top port map (
        sysclk => sysclk, btn => btn,
        nav_mosi => nav_mosi, nav_miso => nav_miso, nav_sclk => nav_sclk, nav_cs => nav_cs,
        jstk_mosi => jstk_mosi, jstk_miso => jstk_miso, jstk_sclk => jstk_sclk, jstk_cs => jstk_cs,
        TMDS_Clk_p => TMDS_Clk_p, TMDS_Clk_n => TMDS_Clk_n,
        TMDS_Data_p => TMDS_Data_p, TMDS_Data_n => TMDS_Data_n
    );

    stim : process
    begin
        -- Hold hardware reset for 100ns
        btn(0) <= '1';
        wait for 100 ns;
        
        -- Release reset and let the system boot up
        btn(0) <= '0';
        
        -- Run for 10 microseconds to verify clock wizard lock and FSM startup
        wait for 10 us;
        std.env.stop;
    end process;

end behavioral;