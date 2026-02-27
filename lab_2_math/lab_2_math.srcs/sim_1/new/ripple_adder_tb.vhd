library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ripple_adder_tb is
end ripple_adder_tb;

architecture behavior of ripple_adder_tb is
    component ripple_adder is
        port(
            a, b : in  std_logic_vector(3 downto 0);
            cin : in  std_logic;
            s : out std_logic_vector(3 downto 0);
            cout : out std_logic
        );
    end component;
    signal tb_a : std_logic_vector(3 downto 0) := (others => '0');
    signal tb_b : std_logic_vector(3 downto 0) := (others => '0');
    signal tb_cin : std_logic := '0';
    signal tb_s : std_logic_vector(3 downto 0);
    signal tb_cout : std_logic;
begin
    UUT: ripple_adder port map (
        a => tb_a,
        b => tb_b,
        cin => tb_cin,
        s => tb_s,
        cout => tb_cout
    );
    stim_proc: process
    begin
        -- Test 1: 0+0+0=0,  S="0000", Cout='0'
        tb_a <= "0000"; tb_b <= "0000"; tb_cin <= '0'; wait for 20 ns;

        -- Test 2: 1+1+0=2,  S="0010", Cout='0'
        tb_a <= "0001"; tb_b <= "0001"; tb_cin <= '0'; wait for 20 ns;

        -- Test 3: 5+3+0=8,  S="1000", Cout='0'
        tb_a <= "0101"; tb_b <= "0011"; tb_cin <= '0'; wait for 20 ns;

        -- Test 4: 9+6+0=15, S="1111", Cout='0'
        tb_a <= "1001"; tb_b <= "0110"; tb_cin <= '0'; wait for 20 ns;

        -- Test 5: 15+1+0=16 (overflow), S="0000", Cout='1'
        tb_a <= "1111"; tb_b <= "0001"; tb_cin <= '0'; wait for 20 ns;

        -- Test 6: 15+15+0=30, S="1110", Cout='1'
        tb_a <= "1111"; tb_b <= "1111"; tb_cin <= '0'; wait for 20 ns;

        -- Test 7: 7+8+1=16 (overflow), S="0000", Cout='1'
        tb_a <= "0111"; tb_b <= "1000"; tb_cin <= '1'; wait for 20 ns;

        -- Test 8: 3+4+1=8,  S="1000", Cout='0'
        tb_a <= "0011"; tb_b <= "0100"; tb_cin <= '1'; wait for 20 ns;

        -- Test 9: 15+15+1=31, S="1111", Cout='1'
        tb_a <= "1111"; tb_b <= "1111"; tb_cin <= '1'; wait for 20 ns;

        -- Test 10: 0+0+1=1, S="0001", Cout='0'
        tb_a <= "0000"; tb_b <= "0000"; tb_cin <= '1'; wait for 20 ns;

        wait; -- end simulation
    end process;
end behavior;