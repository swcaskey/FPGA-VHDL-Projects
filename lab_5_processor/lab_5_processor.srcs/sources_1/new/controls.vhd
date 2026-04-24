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
    signal pc, pc_next : std_logic_vector(15 downto 0) := (others => '0');
    signal dest_reg, dest_reg_next : std_logic_vector(4 downto 0) := (others => '0');
    
    -- THE FIX: Latch the instruction so it survives the PC increment
    signal irWord_reg : std_logic_vector(31 downto 0) := (others => '0');
    
    -- aliases point to the LATCHED instruction, not the raw memory output
    signal opcode : std_logic_vector(4 downto 0);
    signal reg1, reg2, reg3 : std_logic_vector(4 downto 0);
    signal imm : std_logic_vector(15 downto 0);

begin
    -- decode signals
    opcode <= irWord_reg(31 downto 27);
    reg1   <= irWord_reg(26 downto 22);
    reg2   <= irWord_reg(21 downto 17);
    reg3   <= irWord_reg(16 downto 12);
    imm    <= irWord_reg(15 downto 0);

    process(clk, rst)
    begin
        if rst = '1' then
            current_state <= fetch;
            pc <= (others => '0');
            dest_reg <= (others => '0');
            irWord_reg <= (others => '0');
        elsif rising_edge(clk) then
            if en = '1' then
                current_state <= next_state;
                pc <= pc_next;
                dest_reg <= dest_reg_next;
                
                -- Capture the instruction while it is valid
                if current_state = fetch then
                    irWord_reg <= irWord;
                end if;
            end if;
        end if;
    end process;

    process(current_state, opcode, reg1, reg2, reg3, imm, regrD1, regrD2, aluResult,
            ready, newChar, fbDin1, dIn, charRec, pc, dest_reg)
    begin
        -- Default assignments
        next_state <= current_state;
        pc_next <= pc;
        dest_reg_next <= dest_reg;

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

        case current_state is
            when fetch =>
                irAddr <= pc(13 downto 0);
                next_state <= decode;

            when decode =>
                -- Update PC in register file
                rID1 <= "00001";
                wr_enR1 <= '1';
                regwD1 <= std_logic_vector(unsigned(pc) + 1);
                pc_next <= std_logic_vector(unsigned(pc) + 1);
                
                -- Default destination register is reg1
                dest_reg_next <= reg1; 

                if opcode(4 downto 3) = "00" or opcode(4 downto 3) = "01" then
                    next_state <= Rops;
                elsif opcode(4 downto 2) = "100" or opcode(4 downto 2) = "101" then
                    next_state <= Iops;
                else
                    next_state <= Jops;
                end if;

            when Rops =>
                case opcode is
                    when "01101" => next_state <= jr_op;
                    when "01100" => next_state <= recv_op;
                    when "01111" => next_state <= rpix_op;
                    when "01110" => next_state <= wpix_op;
                    when "01011" => next_state <= send_op;
                    when others =>  next_state <= calc;
                end case;

            when Iops =>
                case opcode(2 downto 0) is
                    when "000" => next_state <= equals;
                    when "001" => next_state <= nequal;
                    when "010" => next_state <= ori_op;
                    when "011" => next_state <= lw_op;
                    when "100" => next_state <= sw_op;
                    when others => next_state <= finish;
                end case;

            when Jops =>
                case opcode is
                    when "11000" => next_state <= jmp_op;
                    when "11001" => next_state <= jal_op;
                    when "11010" => next_state <= clrscr_op;
                    when others => next_state <= finish;
                end case;

            when calc =>
                rID1 <= reg2;
                rID2 <= reg3;
                aluA <= regrD1;
                aluB <= regrD2;
                aluOp <= opcode(3 downto 0);
                next_state <= store;

            when jr_op =>
                rID1 <= reg1;
                pc_next <= regrD1;
                next_state <= finish;

            when recv_op =>
                if newChar = '1' then
                    next_state <= store;
                else
                    next_state <= recv_op;
                end if;

            when rpix_op =>
                rID2 <= reg2;
                fbAddr1 <= regrD2(11 downto 0);
                next_state <= store;

            when wpix_op =>
                rID1 <= reg1;
                rID2 <= reg2;
                fbAddr1 <= regrD1(11 downto 0);
                fbDout1 <= regrD2;
                fbWr_en <= '1';
                next_state <= finish;

            when send_op =>
                rID1 <= reg1;
                send <= '1';
                charSend <= regrD1(7 downto 0);
                if ready = '1' then
                    next_state <= finish;
                else
                    next_state <= send_op;
                end if;

            when equals =>
                rID1 <= reg1;
                rID2 <= reg2;
                if regrD1 = regrD2 then
                    pc_next <= imm; 
                    dest_reg_next <= "00001"; 
                    next_state <= store;
                else
                    next_state <= finish;
                end if;

            when nequal =>
                rID1 <= reg1;
                rID2 <= reg2;
                if regrD1 /= regrD2 then
                    pc_next <= imm; 
                    dest_reg_next <= "00001"; 
                    next_state <= store;
                else
                    next_state <= finish;
                end if;

            when ori_op =>
                rID2 <= reg2;
                aluA <= regrD2;
                aluB <= std_logic_vector(resize(unsigned(imm), 16));
                aluOp <= x"9"; -- OR
                next_state <= store;

            when lw_op =>
                rID2 <= reg2;
                dAddr <= std_logic_vector(resize(unsigned(regrD2(14 downto 0)) + unsigned(imm(14 downto 0)), 15));
                next_state <= store;

            when sw_op =>
                rID1 <= reg1;
                rID2 <= reg2;
                dAddr <= std_logic_vector(resize(unsigned(regrD2(14 downto 0)) + unsigned(imm(14 downto 0)), 15));
                dOut <= regrD1;
                d_wr_en <= '1';
                next_state <= finish;

            when jmp_op =>
                pc_next <= imm;
                next_state <= finish;

            when jal_op =>
                rID1 <= "11111"; -- RA register
                wr_enR1 <= '1';
                regwD1 <= pc;
                pc_next <= imm;
                next_state <= finish;

            when clrscr_op =>
                fbRST <= '1';
                next_state <= finish;

            when store =>
                rID1 <= dest_reg;
                wr_enR1 <= '1';
                
                if opcode = "01100" then -- recv
                    regwD1 <= x"00" & charRec;
                elsif opcode = "01111" then -- rpix
                    rID2 <= reg2;
                    fbAddr1 <= regrD2(11 downto 0);
                    regwD1 <= fbDin1;
                elsif opcode = "10011" then -- lw
                    rID2 <= reg2;
                    dAddr <= std_logic_vector(resize(unsigned(regrD2(14 downto 0)) + unsigned(imm(14 downto 0)), 15));
                    regwD1 <= dIn;
                elsif opcode = "10000" or opcode = "10001" then -- beq, bne
                    regwD1 <= imm;
                else -- calc, ori
                    regwD1 <= aluResult;
                end if;
                
                next_state <= finish;

            when finish =>
                next_state <= fetch;

            when others =>
                next_state <= fetch;
        end case;
    end process;
end rtl;