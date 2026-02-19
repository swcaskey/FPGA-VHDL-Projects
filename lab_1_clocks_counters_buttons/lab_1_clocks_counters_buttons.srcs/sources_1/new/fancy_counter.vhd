library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fancy_counter is
    port (
        clk     : in  std_logic;
        clk_en  : in  std_logic; -- From clock_div
        dir     : in  std_logic;
        en      : in  std_logic; -- Button
        ld      : in  std_logic; -- Load button
        rst     : in  std_logic; -- Reset button
        updn    : in  std_logic; -- Update direction button
        val     : in  std_logic_vector(3 downto 0); -- Switch input for limit/load
        cnt     : out std_logic_vector(3 downto 0)  -- Output to LEDs
    );
end fancy_counter;

architecture behavioral of fancy_counter is
    signal count_reg : unsigned(3 downto 0) := (others => '0');
    signal dir_reg   : std_logic := '0'; -- 0 = Up, 1 = Down
    signal value_reg : unsigned(3 downto 0) := "1111"; -- Default limit
begin

    process(clk)
    begin
        if rising_edge(clk) then
            -- 1. Synchronous Reset (Highest Priority)
            if (rst = '1') then
                count_reg <= (others => '0');
           
            -- 2. Global Enable Check
            elsif (en = '1') then
               
                -- A. Load Value
                if (ld = '1') then
                    value_reg <= unsigned(val);
                end if;
               
                -- B. Update Direction
                if (updn = '1') then
                    dir_reg <= dir;
                end if;
               
                -- C. Counting Logic (Only happens if clk_en is '1')
                if (clk_en = '1') then
                    if (dir_reg = '0') then -- Count Up
                        if (count_reg >= value_reg) then
                            count_reg <= (others => '0');
                        else
                            count_reg <= count_reg + 1;
                        end if;
                    else -- Count Down
                        if (count_reg = 0) then
                            count_reg <= value_reg;
                        else
                            count_reg <= count_reg - 1;
                        end if;
                    end if;
                end if; -- End clk_en check
               
            end if; -- End enable check
        end if; -- End rising_edge
    end process;

    cnt <= std_logic_vector(count_reg);

end behavioral;