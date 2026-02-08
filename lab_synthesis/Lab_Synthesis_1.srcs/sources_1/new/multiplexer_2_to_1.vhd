library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity multiplexer_2_to_1 is
    Port (
    D1,D0 : in std_logic;
    SEL : in std_logic;
    MX_OUT : out std_logic
    );
end multiplexer_2_to_1;

architecture Behavioral of multiplexer_2_to_1 is
begin
    MX_OUT <= D1 WHEN (SEL = '1') ELSE D0;
end Behavioral;
