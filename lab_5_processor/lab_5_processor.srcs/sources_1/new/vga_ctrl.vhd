library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_ctrl is
    port (
        clk : in std_logic;
        en  : in std_logic;
        hcount : out std_logic_vector(9 downto 0);
        vcount : out std_logic_vector(9 downto 0);
        vid : out std_logic;
        hs, vs : out std_logic
    );
end vga_ctrl;

architecture rtl of vga_ctrl is
    -- 640x480 standard timing with 25MHz clock
    -- Horizontal: 640 pixels + 16 FP + 96 sync + 48 BP = 800 total
    -- Vertical: 480 pixels + 10 FP + 2 sync + 33 BP = 525 total
    constant H_DISP : integer := 640;
    constant H_FP   : integer := 16;
    constant H_SYNC : integer := 96;
    constant H_BP   : integer := 48;
    constant H_TOTAL : integer := 800;
    
    constant V_DISP : integer := 480;
    constant V_FP   : integer := 10;
    constant V_SYNC : integer := 2;
    constant V_BP   : integer := 33;
    constant V_TOTAL : integer := 525;
    
    signal h_cnt : integer range 0 to H_TOTAL-1 := 0;
    signal v_cnt : integer range 0 to V_TOTAL-1 := 0;
begin
    
    process(clk)
    begin
        if rising_edge(clk) then
            if en = '1' then
                if h_cnt < H_TOTAL - 1 then
                    h_cnt <= h_cnt + 1;
                else
                    h_cnt <= 0;
                    if v_cnt < V_TOTAL - 1 then
                        v_cnt <= v_cnt + 1;
                    else
                        v_cnt <= 0;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    -- Map to 64x64 (10x10 pixels per actual pixel)
    -- For simplicity in simulation, we'll just clamp at 64x64
    process(h_cnt, v_cnt)
        variable h_display : integer;
        variable v_display : integer;
    begin
        -- Calculate display coordinates (0-63 for 64x64)
        h_display := h_cnt / 10;
        v_display := v_cnt / 10;
        
        if h_display > 63 then
            h_display := 63;
        end if;
        if v_display > 63 then
            v_display := 63;
        end if;
        
        hcount <= std_logic_vector(to_unsigned(h_display, 10));
        vcount <= std_logic_vector(to_unsigned(v_display, 10));
    end process;
    
    -- Video valid when in active display area (0-639, 0-479)
    vid <= '1' when (h_cnt < H_DISP and v_cnt < V_DISP) else '0';
    
    -- Horizontal sync pulse
    hs <= '0' when (h_cnt >= H_DISP + H_FP and h_cnt < H_DISP + H_FP + H_SYNC) else '1';
    
    -- Vertical sync pulse
    vs <= '0' when (v_cnt >= V_DISP + V_FP and v_cnt < V_DISP + V_FP + V_SYNC) else '1';
    
end rtl;
