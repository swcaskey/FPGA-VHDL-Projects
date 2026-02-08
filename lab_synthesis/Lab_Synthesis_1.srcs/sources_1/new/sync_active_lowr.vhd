library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sync_active_lowr is
    Port ( 
        CLK : in STD_LOGIC;
        RST : in STD_LOGIC;
        D   : in STD_LOGIC;
        Q   : out STD_LOGIC
    );
end sync_active_lowr;

architecture Behavioral of sync_active_lowr is
begin
    process (CLK)
    begin
       if CLK'event and CLK='1' then
          if RST='0' then
             Q <= '0';
          else
             Q <= D;
          end if;
       end if;
    end process;
end Behavioral;