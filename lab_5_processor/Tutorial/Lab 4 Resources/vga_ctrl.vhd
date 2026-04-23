library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_ctrl is
    port (
        clk : in std_logic;
        enable : in std_logic;
        hcount : out std_logic_vector(9 downto 0);
        vcount : out std_logic_vector(9 downto 0);
        vid : out std_logic;
        hs : out std_logic;
        vs : out std_logic
    );
end vga_ctrl;

architecture behavioral of vga_ctrl is
    signal h_counter : unsigned(9 downto 0) := (others => '0');
    signal v_counter : unsigned(9 downto 0) := (others => '0');
    
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if enable = '1' then
                -- Increment horizontal counter
                if h_counter = 799 then
                    h_counter <= (others => '0');
                    -- Increment vertical counter at end of line
                    if v_counter = 524 then
                        v_counter <= (others => '0');
                    else
                        v_counter <= v_counter + 1;
                    end if;
                else
                    h_counter <= h_counter + 1;
                end if;
            end if;
        end if;
    end process;
    
    -- Output assignments
    hcount <= std_logic_vector(h_counter);
    vcount <= std_logic_vector(v_counter);
    
    -- vid is 1 when display is on (H: 0-639, V: 0-479)
    vid <= '1' when (h_counter < 640 and v_counter < 480) else '0';
    
    -- HS is 0 during sync pulse (H: 656-751), otherwise 1
    hs <= '0' when (h_counter >= 656 and h_counter <= 751) else '1';
    
    -- VS is 0 during sync pulse (V: 490-491), otherwise 1
    vs <= '0' when (v_counter >= 490 and v_counter <= 491) else '1';
    
end behavioral;
