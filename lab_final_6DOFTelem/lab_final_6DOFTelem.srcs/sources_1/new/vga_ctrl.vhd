library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_ctrl is
    port (
        clk : in  std_logic; -- 25 MHz pixel clock
        en  : in  std_logic;
        vid : out std_logic; -- Video Active (VDE)
        hs  : out std_logic; -- Horizontal Sync
        vs  : out std_logic; -- Vertical Sync
        hc  : out std_logic_vector(9 downto 0);
        vc  : out std_logic_vector(9 downto 0)
    );
end vga_ctrl;

architecture behavioral of vga_ctrl is
    -- 640x480 @ 60Hz Industry Standard Timing Parameters (25 MHz Clock)
    constant H_DISPLAY : integer := 640;
    constant H_FP      : integer := 16;
    constant H_SYNC    : integer := 96;
    constant H_BP      : integer := 48;
    constant H_MAX     : integer := H_DISPLAY + H_FP + H_SYNC + H_BP - 1; -- 799

    constant V_DISPLAY : integer := 480;
    constant V_FP      : integer := 10;
    constant V_SYNC    : integer := 2;
    constant V_BP      : integer := 33;
    constant V_MAX     : integer := V_DISPLAY + V_FP + V_SYNC + V_BP - 1; -- 524

    signal h_counter : integer range 0 to H_MAX := 0;
    signal v_counter : integer range 0 to V_MAX := 0;
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if en = '1' then
                -- Horizontal Counter
                if h_counter = H_MAX then
                    h_counter <= 0;
                    -- Vertical Counter (increments when horizontal finishes a line)
                    if v_counter = V_MAX then
                        v_counter <= 0;
                    else
                        v_counter <= v_counter + 1;
                    end if;
                else
                    h_counter <= h_counter + 1;
                end if;
            end if;
        end if;
    end process;

    -- Horizontal Sync (Active Low for 640x480)
    hs <= '0' when (h_counter >= (H_DISPLAY + H_FP) and h_counter < (H_DISPLAY + H_FP + H_SYNC)) else '1';

    -- Vertical Sync (Active Low for 640x480)
    vs <= '0' when (v_counter >= (V_DISPLAY + V_FP) and v_counter < (V_DISPLAY + V_FP + V_SYNC)) else '1';

    -- Video Active (High when in the visible 640x480 area)
    vid <= '1' when (h_counter < H_DISPLAY and v_counter < V_DISPLAY) else '0';

    -- Output the coordinate counters to the rest of the system
    hc <= std_logic_vector(to_unsigned(h_counter, 10));
    vc <= std_logic_vector(to_unsigned(v_counter, 10));

end behavioral;