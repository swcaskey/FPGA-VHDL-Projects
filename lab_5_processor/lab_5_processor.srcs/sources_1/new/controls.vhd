library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controls is
    port (
        -- Timing Signals
        clk, en, rst : in std_logic;
        
        -- Register File IO
        rID1, rID2       : out std_logic_vector(4 downto 0);
        wr_enR1, wr_enR2 : out std_logic;
        regrD1, regrD2   : in std_logic_vector(15 downto 0);
        regwD1, regwD2   : out std_logic_vector(15 downto 0);
        
        -- Framebuffer IO
        fbRST    : out std_logic;
        fbAddr1  : out std_logic_vector(11 downto 0);
        fbDin1   : in std_logic_vector(15 downto 0);
        fbDout1  : out std_logic_vector(15 downto 0);
        fbWr_en  : out std_logic;
        
        -- Instruction Memory IO
        irAddr : out std_logic_vector(13 downto 0);
        irWord : in std_logic_vector(31 downto 0);
        
        -- Data Memory IO
        dAddr   : out std_logic_vector(14 downto 0);
        d_wr_en : out std_logic;
        dOut    : out std_logic_vector(15 downto 0);
        dIn     : in std_logic_vector(15 downto 0);
        
        -- ALU IO
        aluA, aluB : out std_logic_vector(15 downto 0);
        aluOp      : out std_logic_vector(3 downto 0);
        aluResult  : in std_logic_vector(15 downto 0);
        
        -- UART IO
        ready, newChar : in std_logic;
        send           : out std_logic;
        charRec        : in std_logic_vector(7 downto 0);
        charSend       : out std_logic_vector(7 downto 0)
    );
end controls;

architecture rtl of controls is
    type state_type is (fetch, decode, Rops, Iops, Jops, calc, jr_op, recv_op, rpix_op, wpix_op, send_op,
                        equals, nequal, ori_op, lw_op, sw_op, jmp_op, jal_op, clrscr_op, store, finish);
    
    signal current_state, next_state : state_type;
    signal pc : std_logic_vector(15 downto 0) := (others => '0');
    signal pc_next : std_logic_vector(15 downto 0);
    signal opcode : std_logic_vector(4 downto 0);
    signal reg1, reg2, reg3 : std_logic_vector(4 downto 0);
    signal imm : std_logic_vector(15 downto 0);
    signal result_val : std_logic_vector(15 downto 0);
    
begin
    
    -- State register
    process(clk, rst)
    begin
        if rst = '1' then
            current_state <= fetch;
            pc <= (others => '0');
        elsif rising_edge(clk) then
            if en = '1' then
                current_state <= next_state;
                pc <= pc_next;
            end if;
        end if;
    end process;
    
    -- Instruction decode
    opcode <= irWord(31 downto 27);
    reg1 <= irWord(26 downto 22);
    reg2 <= irWord(21 downto 17);
    reg3 <= irWord(16 downto 12);
    imm <= irWord(15 downto 0);
    
    -- Combinational logic for next state and outputs
    process(current_state, opcode, reg1, reg2, reg3, regrD1, regrD2, aluResult, 
            ready, newChar, fbDin1, dIn, charRec, pc, result_val)
    begin
        -- Default assignments
        next_state <= current_state;
        pc_next <= pc;
        
        rID1 <= (others => '0');
        rID2 <= (others => '0');
        wr_enR1 <= '0';
        wr_enR2 <= '0';
        regwD1 <= (others => '0');
        regwD2 <= (others => '0');
        
        fbRST <= '0';
        fbAddr1 <= (others => '0');
        fbDout1 <= (others => '0');
        fbWr_en <= '0';
        
        irAddr <= pc(13 downto 0);
        dAddr <= (others => '0');
        d_wr_en <= '0';
        dOut <= (others => '0');
        
        aluA <= (others => '0');
        aluB <= (others => '0');
        aluOp <= (others => '0');
        
        send <= '0';
        charSend <= (others => '0');
        
        result_val <= (others => '0');
        
        case current_state is
            when fetch =>
                -- Fetch instruction at PC
                irAddr <= pc(13 downto 0);
                next_state <= decode;
                
            when decode =>
                -- Decode instruction and fetch operands
                -- Update PC: store PC+1 in register 1 (PC register)
                rID1 <= "00001";
                wr_enR1 <= '1';
                regwD1 <= std_logic_vector(unsigned(pc) + 1);
                pc_next <= std_logic_vector(unsigned(pc) + 1);
                
                -- Read register operands for later use
                rID1 <= reg2;
                rID2 <= reg3;
                
                -- Determine instruction type and route
                if opcode(4 downto 3) = "00" or opcode(4 downto 3) = "01" then
                    next_state <= Rops;
                elsif opcode(4 downto 2) = "100" or opcode(4 downto 2) = "101" then
                    next_state <= Iops;
                else
                    next_state <= Jops;
                end if;
                
            when Rops =>
                -- Route R-type instruction
                case opcode is
                    when "01101" =>      -- jr
                        next_state <= jr_op;
                    when "01100" =>      -- recv
                        next_state <= recv_op;
                    when "01111" =>      -- rpix
                        next_state <= rpix_op;
                    when "01110" =>      -- wpix
                        next_state <= wpix_op;
                    when "01011" =>      -- send
                        next_state <= send_op;
                    when others =>       -- calc
                        next_state <= calc;
                end case;
                
            when Iops =>
                -- Route I-type instruction
                case opcode(2 downto 0) is
                    when "000" =>        -- beq
                        next_state <= equals;
                    when "001" =>        -- bne
                        next_state <= nequal;
                    when "010" =>        -- ori
                        next_state <= ori_op;
                    when "011" =>        -- lw
                        next_state <= lw_op;
                    when "100" =>        -- sw
                        next_state <= sw_op;
                    when others =>
                        next_state <= finish;
                end case;
                
            when Jops =>
                -- Route J-type instruction
                case opcode is
                    when "11000" =>      -- jmp
                        next_state <= jmp_op;
                    when "11001" =>      -- jal
                        next_state <= jal_op;
                    when "11010" =>      -- clrscr
                        next_state <= clrscr_op;
                    when others =>
                        next_state <= finish;
                end case;
                
            when calc =>
                -- ALU calculation (R-type: add, sub, sll, srl, sra, and, or, xor, slt, sgt, seq)
                aluA <= regrD1;
                aluB <= regrD2;
                aluOp <= opcode(3 downto 0);
                result_val <= aluResult;
                next_state <= store;
                
            when jr_op =>
                -- Jump to address in reg1
                pc_next <= regrD1;
                next_state <= finish;
                
            when recv_op =>
                -- Receive character from UART
                if newChar = '1' then
                    result_val <= x"00" & charRec;
                    next_state <= store;
                else
                    next_state <= recv_op;
                end if;
                
            when rpix_op =>
                -- Read pixel from framebuffer at address in reg2
                fbAddr1 <= regrD2(11 downto 0);
                result_val <= fbDin1;
                next_state <= store;
                
            when wpix_op =>
                -- Write reg2 value to framebuffer at address in reg1
                fbAddr1 <= reg1(11 downto 0);
                fbDout1 <= regrD2;
                fbWr_en <= '1';
                next_state <= finish;
                
            when send_op =>
                -- Send reg1 value over UART
                send <= '1';
                charSend <= regrD1(7 downto 0);
                if ready = '1' then
                    next_state <= finish;
                else
                    next_state <= send_op;
                end if;
                
            when equals =>
                -- Branch if reg2 equals immediate
                if regrD2 = std_logic_vector(resize(unsigned(imm), 16)) then
                    result_val <= pc;
                    rID1 <= "00001";
                    next_state <= store;
                else
                    next_state <= finish;
                end if;
                
            when nequal =>
                -- Branch if reg2 not equal to immediate
                if regrD2 /= std_logic_vector(resize(unsigned(imm), 16)) then
                    result_val <= pc;
                    rID1 <= "00001";
                    next_state <= store;
                else
                    next_state <= finish;
                end if;
                
            when ori_op =>
                -- Bitwise OR: reg1 = reg2 | immediate
                result_val <= regrD2 or std_logic_vector(resize(unsigned(imm), 16));
                next_state <= store;
                
            when lw_op =>
                -- Load word from data memory: reg1 = dmem[reg2 + imm]
                dAddr <= std_logic_vector(resize(unsigned(regrD2(14 downto 0)) + unsigned(imm(14 downto 0)), 15));
                result_val <= dIn;
                next_state <= store;
                
            when sw_op =>
                -- Store word to data memory: dmem[reg2 + imm] = reg1
                dAddr <= std_logic_vector(resize(unsigned(regrD2(14 downto 0)) + unsigned(imm(14 downto 0)), 15));
                dOut <= regrD1;
                d_wr_en <= '1';
                next_state <= finish;
                
            when jmp_op =>
                -- Unconditional jump
                pc_next <= imm;
                next_state <= finish;
                
            when jal_op =>
                -- Jump and link: save PC to reg 31 (RA register)
                rID1 <= "11111";
                wr_enR1 <= '1';
                regwD1 <= pc;
                pc_next <= imm;
                next_state <= finish;
                
            when clrscr_op =>
                -- Clear screen (reset framebuffer)
                fbRST <= '1';
                next_state <= finish;
                
            when store =>
                -- Store result into destination register
                rID1 <= reg1;
                wr_enR1 <= '1';
                regwD1 <= result_val;
                next_state <= finish;
                
            when finish =>
                -- All control signals deasserted, loop back to fetch
                next_state <= fetch;
                
            when others =>
                next_state <= fetch;
                
        end case;
    end process;
    
end rtl;
