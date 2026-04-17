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
    constant IMAGE_X_START : unsigned(9 downto 0) := to_unsigned(80, 10);
    constant IMAGE_X_END   : unsigned(9 downto 0) := to_unsigned(560, 10); -- exclusive
    signal addr_counter : unsigned(17 downto 0) := (others => '0');
    signal hcount_unsigned : unsigned(9 downto 0);
    signal r_reg : std_logic_vector(4 downto 0) := (others => '0');
    signal g_reg : std_logic_vector(5 downto 0) := (others => '0');
    signal b_reg : std_logic_vector(4 downto 0) := (others => '0');
    
begin
    hcount_unsigned <= unsigned(hcount);
    
    process(clk)
    begin
        if rising_edge(clk) then
            if enable = '1' then
                -- Address counter behavior per lab spec.
                if vs = '0' then
                    addr_counter <= (others => '0');
                elsif vid = '1' and hcount_unsigned >= IMAGE_X_START and hcount_unsigned < IMAGE_X_END then
                    if addr_counter < 230399 then
                        addr_counter <= addr_counter + 1;
                    end if;
                end if;
            end if;

            -- Registered RGB output (stable at VGA pins)
            if enable = '1' and vid = '1' and hcount_unsigned >= IMAGE_X_START and hcount_unsigned < IMAGE_X_END then
                r_reg <= pixel(7 downto 5) & "00";
                g_reg <= pixel(4 downto 2) & "000";
                b_reg <= pixel(1 downto 0) & "000";
            else
                r_reg <= (others => '0');
                g_reg <= (others => '0');
                b_reg <= (others => '0');
            end if;
        end if;
    end process;
    
    -- Output address
    addr <= std_logic_vector(addr_counter);
    
    r <= r_reg;
    g <= g_reg;
    b <= b_reg;
    
end behavioral;
