library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debounce is
    generic (
        clk_freq    : integer := 125_000_000;
        stable_time : integer := 20
    );
    port (
        clk  : in  std_logic;
        btn  : in  std_logic;
        dbnc : out std_logic
    );
end debounce;

architecture behavioral of debounce is
    constant COUNTER_MAX : integer := (clk_freq / 1000) * stable_time;
    signal counter : unsigned(21 downto 0) := (others => '0');
    signal shift_reg : std_logic_vector(1 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            dbnc <= '0';
            shift_reg(1) <= shift_reg(0);
            shift_reg(0) <= btn;
            
            if (shift_reg(1) = '1') then
                if (counter < COUNTER_MAX) then
                    counter <= counter + 1;
                    dbnc <= '0';
                else
                    dbnc <= '1';
                end if;
            else
                counter <= (others => '0');
                dbnc <= '0';
            end if;
        end if;
    end process;
end behavioral;
