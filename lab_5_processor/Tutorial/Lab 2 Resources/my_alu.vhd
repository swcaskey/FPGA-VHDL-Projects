library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity my_alu is
    port(
        opcode : in  std_logic_vector(3 downto 0);
        A : in  std_logic_vector(3 downto 0);
        B : in  std_logic_vector(3 downto 0);
        result : out std_logic_vector(3 downto 0)
    );
end my_alu;

architecture behavioral of my_alu is
begin
    process(opcode, A, B)
        variable uA : unsigned(3 downto 0);
        variable uB : unsigned(3 downto 0);
    begin
        uA := unsigned(A);
        uB := unsigned(B);
        case opcode is
            when x"0" =>  -- A + B
                result <= std_logic_vector(uA + uB);
            when x"1" =>  -- A - B
                result <= std_logic_vector(uA - uB);
            when x"2" =>  -- A + 1
                result <= std_logic_vector(uA + 1);
            when x"3" =>  -- A - 1
                result <= std_logic_vector(uA - 1);
            when x"4" =>  -- 0 - A
                result <= std_logic_vector(0 - uA);
            when x"5" =>  -- A > B
                if uA > uB then
                    result <= "0001";
                else
                    result <= "0000";
                end if;
            when x"6" =>  -- A << 1
                result <= A(2 downto 0) & '0';
            when x"7" =>  -- A >> 1 logical
                result <= '0' & A(3 downto 1);
            when x"8" =>  -- A >>> 1 arithmetic
                result <= std_logic_vector(shift_right(uA, 1));
            when x"9" =>  -- not A
                result <= not A;
            when x"A" =>  -- A and B
                result <= A and B;
            when x"B" =>  -- A or B
                result <= A or B;
            when x"C" =>  -- A xor B
                result <= A xor B;
            when x"D" =>  -- A xnor B
                result <= A xnor B;
            when x"E" =>  -- A nand B
                result <= A nand B;
            when x"F" =>  -- A nor B
                result <= A nor B;
            when others =>
                result <= (others => '0');
        end case;
    end process;
end behavioral;