library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pixel_pusher_hdmi is
    port (
        clk    : in  std_logic;
        enable : in  std_logic;
        vs     : in  std_logic;
        pixel  : in  std_logic_vector(7 downto 0);
        hcount : in  std_logic_vector(9 downto 0);
        vid    : in  std_logic;
        addr   : out std_logic_vector(17 downto 0);
        r      : out std_logic_vector(7 downto 0);
        g      : out std_logic_vector(7 downto 0);
        b      : out std_logic_vector(7 downto 0)
    );
end pixel_pusher_hdmi;

architecture behavioral of pixel_pusher_hdmi is
    constant IMAGE_X_START : unsigned(9 downto 0) := to_unsigned(80, 10);
    constant IMAGE_X_END   : unsigned(9 downto 0) := to_unsigned(560, 10); -- exclusive

    signal addr_counter   : unsigned(17 downto 0) := (others => '0');
    signal hcount_u       : unsigned(9 downto 0);
    signal active_pixel   : std_logic;
    signal r_reg          : std_logic_vector(7 downto 0) := (others => '0');
    signal g_reg          : std_logic_vector(7 downto 0) := (others => '0');
    signal b_reg          : std_logic_vector(7 downto 0) := (others => '0');
begin
    hcount_u <= unsigned(hcount);
    active_pixel <= '1' when (vid = '1' and hcount_u >= IMAGE_X_START and hcount_u < IMAGE_X_END) else '0';

    process(clk)
    begin
        if rising_edge(clk) then
            if enable = '1' then
                if vs = '0' then
                    addr_counter <= (others => '0');
                elsif active_pixel = '1' then
                    if addr_counter < to_unsigned(230399, 18) then
                        addr_counter <= addr_counter + 1;
                    end if;
                end if;

                if active_pixel = '1' then
                    --R, G: 3 bits (max 7) to 8 bits (max 255)
                    r_reg <= std_logic_vector(to_unsigned((to_integer(unsigned(pixel(7 downto 5))) * 255) / 7, 8));
                    g_reg <= std_logic_vector(to_unsigned((to_integer(unsigned(pixel(4 downto 2))) * 255) / 7, 8));
                    
                    --B: 2 bits (max 3) to 8 bits (max 255)
                    b_reg <= std_logic_vector(to_unsigned((to_integer(unsigned(pixel(1 downto 0))) * 255) / 3, 8));
                else
                    r_reg <= (others => '0');
                    g_reg <= (others => '0');
                    b_reg <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    addr <= std_logic_vector(addr_counter);
    r <= r_reg;
    g <= g_reg;
    b <= b_reg;
end behavioral;

