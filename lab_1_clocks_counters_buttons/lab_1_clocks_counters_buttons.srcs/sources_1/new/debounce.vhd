library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debounce is
    generic (
        -- Default to 2.5 million cycles (20 ms @ 125 MHz) for implementation
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
    -- Calculate the number of cycles to wait: (Freq * Time_ms) / 1000
    constant COUNTER_MAX : integer := (clk_freq / 1000) * stable_time;
   
    -- Counter needs to be large enough to hold COUNTER_MAX.
    -- 22 bits covers up to ~4 million, which is enough for 2,500,000.
    signal counter : unsigned(21 downto 0) := (others => '0');
   
    -- 2-bit shift register for synchronizing the input to the clock
    -- ensuring we don't get metastability issues (as per Lab text 2.1)
    signal shift_reg : std_logic_vector(1 downto 0) := (others => '0');

begin

    process(clk)
    begin
        if rising_edge(clk) then
            -- 1. Shift the button input into the register (synchronizer)
            shift_reg(1) <= shift_reg(0);
            shift_reg(0) <= btn;
           
            -- 2. Check if the synchronized input is high ('1')
            if (shift_reg(1) = '1') then
               
                -- If it's high, start counting (or keep counting)
                if (counter < COUNTER_MAX) then
                    counter <= counter + 1;
                    dbnc <= '0'; -- Not stable yet
                else
                    dbnc <= '1'; -- Stable! Max count reached
                end if;
               
            else
                -- If input drops to '0' (bounce or release), reset everything
                counter <= (others => '0');
                dbnc <= '0';
            end if;
        end if;
    end process;

end behavioral;