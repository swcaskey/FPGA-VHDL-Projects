library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debounce is
    generic (
        -- 20ms debounce time, based on 125 MHz (Zybo clock)
        clk_freq    : integer := 125_000_000;
        stable_time : integer := 20 -- ms
    );
    port (
        clk  : in  std_logic;
        btn  : in  std_logic;
        dbnc : out std_logic
    );
end debounce;

architecture behavioral of debounce is
    -- Find seconds of debounce. 20ms to seconds: 20ms/1000 = 0.02s.
    -- Find the cycles for the debounce time. 0.02s * 125,000,000cycles/s = 2,500,000 cycles
    constant COUNTER_MAX : integer := (clk_freq / 1000) * stable_time;
    
    -- We need to count up to 2,500,000
    -- Therefre we need 22 bits, 2^22 = 4194304, to hold count
    signal counter : unsigned(21 downto 0) := (others => '0');
   
    -- to sync the input to the clock
    signal shift_reg : std_logic_vector(1 downto 0) := (others => '0');

begin

    process(clk)
    begin
        if rising_edge(clk) then
            dbnc <= '0'; -- Make sure dbnc is put to a known value every clock cycle
            -- Shift the button input into the register (sync) to avoid meta-state
            shift_reg(1) <= shift_reg(0); -- "bit 1 get value at bit 0" pg4
            shift_reg(0) <= btn; -- Actual button input "each clock bit 0 gets new value" pg4
           
            -- "see if the value of the end of the shift register is a 1" pg4
            if (shift_reg(1) = '1') then
               
                -- Start counting
                if (counter < COUNTER_MAX) then
                    counter <= counter + 1;
                    dbnc <= '0'; -- Output 0
                else
                    dbnc <= '1'; -- Output 1 as max counter reached to hit 20ms
                end if;
               
            else
                -- "At any time the counter has not hit its maximum value (bounce or release), the output of the debounce circuit displays 0) pg4
                counter <= (others => '0');
                dbnc <= '0';
            end if;
        end if;
    end process;

end behavioral;