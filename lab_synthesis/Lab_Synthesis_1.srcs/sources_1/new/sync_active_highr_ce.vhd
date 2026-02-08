library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sync_active_highr_ce is
    Port ( 
        CLK : in STD_LOGIC;
        RST : in STD_LOGIC;
        CE  : in STD_LOGIC;
        D   : in STD_LOGIC;
        Q   : out STD_LOGIC
    );
end sync_active_highr_ce;

architecture Behavioral of sync_active_highr_ce is
begin
    process (CLK)
    begin
       if CLK'event and CLK='1' then
          if RST='1' then
             Q <= '0';
          elsif CE ='1' then
             Q <= D;
          end if;
       end if;
    end process;
end Behavioral;