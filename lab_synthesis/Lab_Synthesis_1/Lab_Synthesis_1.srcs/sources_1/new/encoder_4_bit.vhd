library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity encoder_4_bit is
    Port ( 
        input  : in  STD_LOGIC_VECTOR (3 downto 0);
        output : out STD_LOGIC_VECTOR (1 downto 0)
    );
end encoder_4_bit;

architecture Behavioral of encoder_4_bit is
begin
    -- Sensitivity list contains 'input' instead of 'clock'
    process(input)
    begin
        case input is
            when "0001" => output <= "00";
            when "0010" => output <= "01";
            when "0100" => output <= "10";
            when "1000" => output <= "11";
            when others => output <= "00";
        end case;
    end process;
end Behavioral;