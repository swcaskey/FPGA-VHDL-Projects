library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity comparator_8_bit is
    Port ( 
        A, B : in  STD_LOGIC_VECTOR (7 downto 0);
        EQ   : out STD_LOGIC
    );
end comparator_8_bit;

architecture Behavioral of comparator_8_bit is
begin
    -- This matches the "Equal" template in Figure 2
    EQ <= '1' when (A = B) else '0';
end Behavioral;