library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity framebuffer is
    port (
        clk1, en1, en2, ld : in std_logic;
        addr1, addr2       : in std_logic_vector(11 downto 0);
        wr_en1             : in std_logic;
        din1               : in std_logic_vector(15 downto 0);
        dout1, dout2       : out std_logic_vector(15 downto 0)
    );
end framebuffer;

architecture rtl of framebuffer is
    type mem_type is array (0 to 4095) of std_logic_vector(15 downto 0);
    signal mem : mem_type := (others => (others => '0'));
    signal reset_counter : integer := 0;
begin
    
    -- Asynchronous reads
    dout1 <= mem(to_integer(unsigned(addr1)));
    dout2 <= mem(to_integer(unsigned(addr2)));
    
    -- Synchronous writes with gradual reset
    process(clk1)
    begin
        if rising_edge(clk1) then
            if ld = '1' then
                -- Gradual reset - zero out one location per clock cycle
                if reset_counter < 4096 then
                    mem(reset_counter) <= (others => '0');
                    reset_counter <= reset_counter + 1;
                end if;
            elsif en1 = '1' then
                if wr_en1 = '1' then
                    mem(to_integer(unsigned(addr1))) <= din1;
                end if;
            end if;
        end if;
    end process;
    
end rtl;
