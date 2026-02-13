library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity clock_div is
    port(
        clk  : in std_logic;        -- 125 Mhz clock
        div : out std_logic         -- div, '1' = bit
    );
end clock_div;

architecture behavioral of clock_div is
    signal counter : std_logic_vector(26 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- count one full led period (1 Hz)
            if (unsigned(counter) < (124999999 / 2)) then
                counter <= std_logic_vector(unsigned(counter) + 1);
            else
                counter <= (others => '0');
            end if;
            -- div is 1 for half of the period (50% duty cycle)
            if (unsigned(counter) < (62500000 / 2)) then
                div <= '1';
            else
                div <= '0';
            end if;
        end if;
    end process;
end behavioral;
