library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity my_alu is
    port (
        clk    : in std_logic;
        en     : in std_logic;
        A      : in std_logic_vector(15 downto 0);
        B      : in std_logic_vector(15 downto 0);
        Opcode : in std_logic_vector(3 downto 0);
        Outp   : out std_logic_vector(15 downto 0)
    );
end my_alu;

architecture rtl of my_alu is
    signal result : std_logic_vector(15 downto 0);
begin
    
    process(clk)
    begin
        if rising_edge(clk) then
            if en = '1' then
                case Opcode is
                    when x"0" =>
                        result <= std_logic_vector(signed(A) + signed(B));
                    when x"1" =>
                        result <= std_logic_vector(signed(A) - signed(B));
                    when x"2" =>
                        result <= std_logic_vector(signed(A) + 1);
                    when x"3" =>
                        result <= std_logic_vector(signed(A) - 1);
                    when x"4" =>
                        result <= std_logic_vector(-signed(A));
                    when x"5" =>
                        result <= A(14 downto 0) & '0';
                    when x"6" =>
                        result <= '0' & A(15 downto 1);
                    when x"7" =>
                        result <= A(15) & A(15 downto 1);
                    when x"8" =>
                        result <= A and B;
                    when x"9" =>
                        result <= A or B;
                    when x"A" =>
                        result <= A xor B;
                    when x"B" =>
                        if signed(A) < signed(B) then
                            result <= (0 => '1', others => '0');
                        else
                            result <= (others => '0');
                        end if;
                    when x"C" =>
                        if signed(A) > signed(B) then
                            result <= (0 => '1', others => '0');
                        else
                            result <= (others => '0');
                        end if;
                    when x"D" =>
                        if A = B then
                            result <= (0 => '1', others => '0');
                        else
                            result <= (others => '0');
                        end if;
                    when x"E" =>
                        if unsigned(A) < unsigned(B) then
                            result <= (0 => '1', others => '0');
                        else
                            result <= (others => '0');
                        end if;
                    when x"F" =>
                        if unsigned(A) > unsigned(B) then
                            result <= (0 => '1', others => '0');
                        else
                            result <= (others => '0');
                        end if;
                    when others =>
                        result <= (others => '0');
                end case;
            end if;
        end if;
    end process;
    
    Outp <= result;
    
end rtl;
