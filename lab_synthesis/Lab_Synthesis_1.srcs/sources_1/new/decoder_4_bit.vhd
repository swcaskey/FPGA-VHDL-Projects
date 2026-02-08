library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity decoder_4_bit is
    Port ( 
        input  : in  STD_LOGIC_VECTOR (1 downto 0); -- 2-bit input
        output : out STD_LOGIC_VECTOR (3 downto 0)  -- 4-bit output
    );
end decoder_4_bit;

architecture Behavioral of decoder_4_bit is
begin
    -- Sensitivity list contains 'input' instead of 'clock'
    process(input)
    begin
        case input is
            when "00" => output <= "0001";
            when "01" => output <= "0010";
            when "10" => output <= "0100";
            when "11" => output <= "1000";
            when others => output <= "0000";
         end case;
    end process;
end Behavioral;