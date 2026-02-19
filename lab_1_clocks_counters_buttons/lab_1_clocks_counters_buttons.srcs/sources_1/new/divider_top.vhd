library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity divider_top is
    port (
        clk  : in std_logic;
        led0 : out std_logic
    );
end divider_top;

architecture behavioral of divider_top is
   
    component clock_div is
        port (
            clk : in std_logic;
            div : out std_logic
        );
    end component;

    signal div_en : std_logic; -- The 2Hz enable pulse
    signal led_reg : std_logic := '0'; -- Internal register for the LED state

begin

    -- Instantiate the clock divider
    U1: clock_div
    port map (
        clk => clk,
        div => div_en
    );

    -- The Flip-Flop with Clock Enable (Figure 1.3)
    -- This process only updates led_reg when div_en is '1'
    process(clk)
    begin
        if rising_edge(clk) then
            if (div_en = '1') then
                led_reg <= not led_reg; -- Invert the signal (D = NOT Q)
            end if;
        end if;
    end process;

    -- Drive the output port
    led0 <= led_reg;

end behavioral;