library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_top is
    port (
        clk  : in  std_logic;
        btn  : in  std_logic_vector(3 downto 0); -- buttons (0 on the right, 3 on the left)
        sw   : in  std_logic_vector(3 downto 0); -- switches (0 on the right, 3 on the left)
        led  : out std_logic_vector(3 downto 0)  -- lEDs (0 on the right, 3 on the left)
    );
end counter_top;

architecture structural of counter_top is -- * Declare Components
    -- Clock Divider
    component clock_div is
        port (
            clk : in  std_logic;
            div : out std_logic
        );
    end component;
    
    -- Debouncer
    component debounce is
        generic (
            clk_freq    : integer := 125_000_000;
            stable_time : integer := 20
        );
        port (
            clk  : in  std_logic;
            btn  : in  std_logic;
            dbnc : out std_logic
        );
    end component;
    
    -- Counter
    component fancy_counter is
        port (
            clk     : in  std_logic;
            clk_en  : in  std_logic;
            dir     : in  std_logic;
            en      : in  std_logic;
            ld      : in  std_logic;
            rst     : in  std_logic;
            updn    : in  std_logic;
            val     : in  std_logic_vector(3 downto 0);
            cnt     : out std_logic_vector(3 downto 0)
        );
    end component;

    -- Signals
    signal div_en_sig : std_logic;                   -- 2Hz clock enable
    signal dbnc_btn   : std_logic_vector(3 downto 0); -- Debounced buttons

begin
    -- * Instantiate Clock Divider
    U1: clock_div
    port map (
        clk => clk,
        div => div_en_sig
    );

    -- * Instantiate Debouncers
    -- Button 0 (_ _ _ x)
    DB0: debounce
    port map (
        clk  => clk,
        btn  => btn(0),
        dbnc => dbnc_btn(0)
    );
    -- Button 1 (_ _ x _)
    DB1: debounce
    port map (
        clk  => clk,
        btn  => btn(1),
        dbnc => dbnc_btn(1)
    );
    -- Button 2 (_ x _ _)
    DB2: debounce
    port map (
        clk  => clk,
        btn  => btn(2),
        dbnc => dbnc_btn(2)
    );
    -- Button 3 (x _ _ _)
    DB3: debounce
    port map (
        clk  => clk,
        btn  => btn(3),
        dbnc => dbnc_btn(3)
    );

    -- * Instantiate Counter
    CT1: fancy_counter -- Match the diagram on pg7
    port map (
        clk     => clk,
        clk_en  => div_en_sig,       -- Pulse from clock_div
        dir     => sw(0),            -- Use Switch 0 for direction
        rst     => dbnc_btn(0),      -- Reset is             _ _ _ x
        en      => dbnc_btn(1),      -- Enable is            _ _ x _
        updn    => dbnc_btn(2),      -- Direction enable is  _ x _ _
        ld      => dbnc_btn(3),      -- Load is              x _ _ _
        val     => sw,               -- Switches set the count limit/value
        cnt     => led               -- Display count on LEDs
    );

end structural;