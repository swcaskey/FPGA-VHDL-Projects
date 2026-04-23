library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regs is
    port (
        clk, en, rst : in std_logic;
        id1, id2     : in std_logic_vector(4 downto 0);
        wr_en1, wr_en2 : in std_logic;
        din1, din2   : in std_logic_vector(15 downto 0);
        dout1, dout2 : out std_logic_vector(15 downto 0)
    );
end regs;

architecture rtl of regs is
    type reg_array is array (0 to 31) of std_logic_vector(15 downto 0);
    signal registers : reg_array := (others => (others => '0'));
begin
    
    -- Asynchronous reads
    dout1 <= registers(to_integer(unsigned(id1)));
    dout2 <= registers(to_integer(unsigned(id2)));
    
    -- Synchronous writes
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                registers <= (others => (others => '0'));
            elsif en = '1' then
                -- Register 0 always reads as 0, but we can still write to it (though it won't persist)
                if wr_en1 = '1' then
                    registers(to_integer(unsigned(id1))) <= din1;
                end if;
                if wr_en2 = '1' then
                    registers(to_integer(unsigned(id2))) <= din2;
                end if;
                -- Force register 0 to always be 0
                registers(0) <= (others => '0');
            end if;
        end if;
    end process;
    
end rtl;
