library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fancy_counter is
    port (
        clk     : in  std_logic; -- Zybo clock
        clk_en  : in  std_logic; -- clock_div (2 Hz)
        
        en      : in  std_logic; -- enable BUTTON *allows for ld, updn, counting logic
        ld      : in  std_logic; -- load BUTTON, *loads val onto value_reg
        rst     : in  std_logic; -- reset BUTTON. *loads 0 onto count_reg
        updn    : in  std_logic; -- allow for update direction BUTTON *when pressed you can change dir (see dir)
        
        val     : in  std_logic_vector(3 downto 0); -- *the 4 bit number you make based on the 4 switches
        dir     : in  std_logic; -- *one of the switches you switch to change the direction
        cnt     : out std_logic_vector(3 downto 0)  -- *LED output for each of the 4 LEDs
    );
end fancy_counter;

architecture behavioral of fancy_counter is
    signal count_reg : unsigned(3 downto 0) := (others => '0');
    signal dir_reg   : std_logic := '0'; -- 0 = count up, 1 = count down
    signal value_reg : unsigned(3 downto 0) := "1111"; -- sets the max value
begin

    process(clk)
    begin
        if rising_edge(clk) then -- Everything has to occur on the rising clock edge pg6
            -- * Reset Button pressed
            if (rst = '1') then
                count_reg <= (others => '0');
                    
            -- * Load button pressed
            elsif (ld = '1') then
                value_reg <= unsigned(val);
           
            -- * Allow for direction change button pressed
            elsif (updn = '1') then
                dir_reg <= dir;
                
            -- * Enable button pressed
            elsif (en = '1') then
               
                -- * The actual counting (ONLY WHEN clock_div (2 Hz) is high
                if (clk_en = '1') then
                    if (dir_reg = '0') then -- Do count up
                        if (count_reg >= value_reg) then -- if the current count is bigger than the max number
                            count_reg <= (others => '0'); -- reset the count register
                        else
                            count_reg <= count_reg + 1; -- count up by 1
                        end if;
                    else -- Do count down
                        if (count_reg = 0) then -- if the current count reaches 0
                            count_reg <= value_reg; -- set the count register to the max number
                        else
                            count_reg <= count_reg - 1; -- count down by 1
                        end if;
                    end if;
                end if; -- End clock_div if statement for counting
               
            end if; -- End enable if statement
        end if; -- End rising_edge if statement
    end process; -- Stop checking Zybo clock

    cnt <= std_logic_vector(count_reg); -- Set the LEDs

end behavioral;