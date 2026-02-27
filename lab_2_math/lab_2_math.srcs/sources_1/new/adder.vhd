library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity adder is
    port(
    a, b, cin : in std_logic;
    s, cout : out std_logic
    );
end adder;

architecture behavioral of adder is
    signal abcin : std_logic_vector (2 downto 0);
begin
    abcin <= a & b & cin;
adding: process (abcin)
    begin
        case (abcin) is
        when "001" =>
            s <= '1';
            cout <= '0';
        when "010" =>
            s <= '1';
            cout <= '0';
        when "011" =>
            s <= '0';
            cout <= '1';
        when "100" =>
            s <= '1';
            cout <= '0';   
        when "101" =>
            s <= '0';
            cout <= '1';
        when "110" =>
            s <= '0';
            cout <= '1';
        when "111" =>
            s <= '1';
            cout <= '1';
        when others =>
            s <= '0';
            cout <= '0';
        end case;
end process;
end behavioral;
