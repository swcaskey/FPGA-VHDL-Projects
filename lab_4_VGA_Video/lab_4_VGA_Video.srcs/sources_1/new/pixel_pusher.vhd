library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pixel_pusher is
    port (
        clk : in std_logic;
        enable : in std_logic;
        vs : in std_logic;
        pixel : in std_logic_vector(7 downto 0);
        hcount : in std_logic_vector(9 downto 0);
        vid : in std_logic;
        addr : out std_logic_vector(17 downto 0);
        r : out std_logic_vector(4 downto 0);
        g : out std_logic_vector(5 downto 0);
        b : out std_logic_vector(4 downto 0)
    );
end pixel_pusher;

architecture behavioral of pixel_pusher is
    signal addr_counter : unsigned(17 downto 0) := (others => '0');
    signal hcount_unsigned : unsigned(9 downto 0);
    
begin
    hcount_unsigned <= unsigned(hcount);
    
    process(clk)
    begin
        if rising_edge(clk) then
            -- Reset address synchronously when VS is 0
            if vs = '0' then
                addr_counter <= (others => '0');
            elsif enable = '1' and vid = '1' and hcount_unsigned < 480 and addr_counter < 229999 then
                -- Increment counter during active video display (max 480x480 pixels = addresses 0-229999)
                addr_counter <= addr_counter + 1;
            end if;
        end if;
    end process;
    
    -- Output address
    addr <= std_logic_vector(addr_counter);
    
    -- Convert 8-bit pixel to RGB output
    -- When display is on, output the color data
    -- Otherwise output black (0)
    process(vid, pixel)
    begin
        if vid = '1' then
            -- R: bits 7-5 (3 bits), shifted left 2 to make 5 bits
            r <= pixel(7 downto 5) & "00";
            -- G: bits 4-2 (3 bits), shifted left 3 to make 6 bits
            g <= pixel(4 downto 2) & "000";
            -- B: bits 1-0 (2 bits), shifted left 3 to make 5 bits
            b <= pixel(1 downto 0) & "000";
        else
            r <= (others => '0');
            g <= (others => '0');
            b <= (others => '0');
        end if;
    end process;
    
end behavioral;