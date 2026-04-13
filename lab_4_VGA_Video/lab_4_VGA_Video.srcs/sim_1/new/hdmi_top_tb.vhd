library ieee;
use ieee.std_logic_1164.all;

entity hdmi_top_tb is
end hdmi_top_tb;

architecture behavioral of hdmi_top_tb is
    component hdmi_top is
        generic (
            SIM_BYPASS_CLK_WIZ : boolean := false
        );
        port (
            clk         : in  std_logic;
            hdmi_clk_p  : out std_logic;
            hdmi_clk_n  : out std_logic;
            hdmi_d_p    : out std_logic_vector(2 downto 0);
            hdmi_d_n    : out std_logic_vector(2 downto 0);
            hdmi_out_en : out std_logic
        );
    end component;

    signal clk         : std_logic := '0';
    signal hdmi_clk_p  : std_logic;
    signal hdmi_clk_n  : std_logic;
    signal hdmi_d_p    : std_logic_vector(2 downto 0);
    signal hdmi_d_n    : std_logic_vector(2 downto 0);
    signal hdmi_out_en : std_logic;

    constant CLK_PERIOD : time := 8 ns; -- 125 MHz
begin
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    dut : hdmi_top
        generic map (
            SIM_BYPASS_CLK_WIZ => true
        )
        port map (
            clk         => clk,
            hdmi_clk_p  => hdmi_clk_p,
            hdmi_clk_n  => hdmi_clk_n,
            hdmi_d_p    => hdmi_d_p,
            hdmi_d_n    => hdmi_d_n,
            hdmi_out_en => hdmi_out_en
        );

    stim : process
    begin
        wait for 20 ms;
        wait;
    end process;
end behavioral;

