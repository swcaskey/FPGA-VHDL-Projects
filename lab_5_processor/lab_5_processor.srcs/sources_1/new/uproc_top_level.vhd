library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uproc_top_level is
    port (
        clk    : in std_logic;
        btn_0  : in std_logic;
        
        -- UART PMOD
        TXD    : in std_logic;  -- Receive from PC
        RXD    : out std_logic; -- Transmit to PC
        CTS    : inout std_logic;
        RTS    : inout std_logic;
        
        -- VGA
        vga_r  : out std_logic_vector(4 downto 0);
        vga_g  : out std_logic_vector(5 downto 0);
        vga_b  : out std_logic_vector(4 downto 0);
        vga_hs : out std_logic;
        vga_vs : out std_logic
    );
end uproc_top_level;

architecture structural of uproc_top_level is

    -- Component Declarations
    component clock_div
        port ( CLK : in std_logic; DIV : out std_logic );
    end component;

    component clock_div_25
        port ( CLK : in std_logic; DIV : out std_logic );
    end component;

    component debounce
        port ( clk : in std_logic; btn : in std_logic; dbnc : out std_logic );
    end component;

    component controls
        port (
            clk, en, rst     : in std_logic;
            rID1, rID2       : out std_logic_vector(4 downto 0);
            wr_enR1, wr_enR2 : out std_logic;
            regrD1, regrD2   : in std_logic_vector(15 downto 0);
            regwD1, regwD2   : out std_logic_vector(15 downto 0);
            fbRST            : out std_logic;
            fbAddr1          : out std_logic_vector(11 downto 0);
            fbDin1           : in std_logic_vector(15 downto 0);
            fbDout1          : out std_logic_vector(15 downto 0);
            fbWr_en          : out std_logic;
            irAddr           : out std_logic_vector(13 downto 0);
            irWord           : in std_logic_vector(31 downto 0);
            dAddr            : out std_logic_vector(14 downto 0);
            d_wr_en          : out std_logic;
            dOut             : out std_logic_vector(15 downto 0);
            dIn              : in std_logic_vector(15 downto 0);
            aluA, aluB       : out std_logic_vector(15 downto 0);
            aluOp            : out std_logic_vector(3 downto 0);
            aluResult        : in std_logic_vector(15 downto 0);
            ready, newChar   : in std_logic;
            send             : out std_logic;
            charRec          : in std_logic_vector(7 downto 0);
            charSend         : out std_logic_vector(7 downto 0)
        );
    end component;

    component my_alu
        port (
            clk, en : in std_logic;
            A, B    : in std_logic_vector(15 downto 0);
            Opcode  : in std_logic_vector(3 downto 0);
            Outp    : out std_logic_vector(15 downto 0)
        );
    end component;

    component regs
        port (
            clk, en, rst   : in std_logic;
            id1, id2       : in std_logic_vector(4 downto 0);
            wr_en1, wr_en2 : in std_logic;
            din1, din2     : in std_logic_vector(15 downto 0);
            dout1, dout2   : out std_logic_vector(15 downto 0)
        );
    end component;

    component uart
        port (
            clk, en, send, rx, rst : in std_logic;
            charSend               : in std_logic_vector(7 downto 0);
            ready, tx, newChar     : out std_logic;
            charRec                : out std_logic_vector(7 downto 0)
        );
    end component;

    component framebuffer
        port (
            clk1, en1, en2, ld : in std_logic;
            addr1, addr2       : in std_logic_vector(11 downto 0);
            wr_en1             : in std_logic;
            din1               : in std_logic_vector(15 downto 0);
            dout1, dout2       : out std_logic_vector(15 downto 0)
        );
    end component;

    component pixel_pusher
        port (
            clk, en : in std_logic;
            hcount, vcount : in std_logic_vector(9 downto 0);
            vid, vs : in std_logic;
            pixel : in std_logic_vector(15 downto 0);
            addr : out std_logic_vector(11 downto 0);
            R : out std_logic_vector(4 downto 0);
            G : out std_logic_vector(5 downto 0);
            B : out std_logic_vector(4 downto 0)
        );
    end component;

    component vga_ctrl
        port (
            clk, en : in std_logic;
            hcount, vcount : out std_logic_vector(9 downto 0);
            vid, hs, vs : out std_logic
        );
    end component;

    -- Block Memory Generators (IP Catalog)
    component irMem
        port (
            clka  : in std_logic;
            addra : in std_logic_vector(13 downto 0);
            douta : out std_logic_vector(31 downto 0)
        );
    end component;

    component dMem
        port (
            clka  : in std_logic;
            wea   : in std_logic_vector(0 downto 0);
            addra : in std_logic_vector(14 downto 0);
            dina  : in std_logic_vector(15 downto 0);
            douta : out std_logic_vector(15 downto 0)
        );
    end component;

    -- Internal Routing Signals
    signal en_115200, en_25mhz, rst_net : std_logic;
    
    -- ALU
    signal aluA_net, aluB_net, aluResult_net : std_logic_vector(15 downto 0);
    signal aluOp_net : std_logic_vector(3 downto 0);
    
    -- Registers
    signal rID1_net, rID2_net : std_logic_vector(4 downto 0);
    signal wr_enR1_net, wr_enR2_net : std_logic;
    signal regwD1_net, regwD2_net, regrD1_net, regrD2_net : std_logic_vector(15 downto 0);
    
    -- UART
    signal send_net, ready_net, newChar_net : std_logic;
    signal charSend_net, charRec_net : std_logic_vector(7 downto 0);
    
    -- Memories
    signal irAddr_net : std_logic_vector(13 downto 0);
    signal irWord_net : std_logic_vector(31 downto 0);
    signal dAddr_net : std_logic_vector(14 downto 0);
    signal d_wr_en_net : std_logic;
    signal dOut_net, dIn_net : std_logic_vector(15 downto 0);
    
    -- Framebuffer
    signal fbRST_net, fbWr_en_net : std_logic;
    signal fbAddr1_net, fbAddr2_net : std_logic_vector(11 downto 0);
    signal fbDin1_net, fbDout1_net, fbDout2_net : std_logic_vector(15 downto 0);
    
    -- VGA
    signal hcount_net, vcount_net : std_logic_vector(9 downto 0);
    signal vid_net, vs_net : std_logic;

begin

    -- Tie unused UART PMOD signals to high impedance
    CTS <= 'Z';
    RTS <= 'Z';

    -- Clocking & Reset
    clk_div_inst : clock_div port map (
        CLK => clk, DIV => en_115200
    );

    clk_div_25_inst : clock_div_25 port map (
        CLK => clk, DIV => en_25mhz
    );

    debounce_inst : debounce port map (
        clk => clk, btn => btn_0, dbnc => rst_net
    );

    -- Central Controller
    controls_inst : controls port map (
        clk => clk, en => en_115200, rst => rst_net,
        rID1 => rID1_net, rID2 => rID2_net,
        wr_enR1 => wr_enR1_net, wr_enR2 => wr_enR2_net,
        regrD1 => regrD1_net, regrD2 => regrD2_net,
        regwD1 => regwD1_net, regwD2 => regwD2_net,
        fbRST => fbRST_net, fbAddr1 => fbAddr1_net,
        fbDin1 => fbDin1_net, fbDout1 => fbDout1_net, fbWr_en => fbWr_en_net,
        irAddr => irAddr_net, irWord => irWord_net,
        dAddr => dAddr_net, d_wr_en => d_wr_en_net,
        dOut => dOut_net, dIn => dIn_net,
        aluA => aluA_net, aluB => aluB_net,
        aluOp => aluOp_net, aluResult => aluResult_net,
        ready => ready_net, newChar => newChar_net,
        send => send_net, charRec => charRec_net, charSend => charSend_net
    );

    -- ALU
    my_alu_inst : my_alu port map (
        clk => clk, en => en_115200,
        A => aluA_net, B => aluB_net, Opcode => aluOp_net, Outp => aluResult_net
    );

    -- Register File
    regs_inst : regs port map (
        clk => clk, en => en_115200, rst => rst_net,
        id1 => rID1_net, id2 => rID2_net,
        wr_en1 => wr_enR1_net, wr_en2 => wr_enR2_net,
        din1 => regwD1_net, din2 => regwD2_net,
        dout1 => regrD1_net, dout2 => regrD2_net
    );

    -- UART Interface
    uart_inst : uart port map (
        clk => clk, en => en_115200, rst => rst_net,
        send => send_net, rx => TXD, tx => RXD,
        charSend => charSend_net, ready => ready_net,
        newChar => newChar_net, charRec => charRec_net
    );

    -- Memory IPs
    irMem_inst : irMem port map (
        clka => clk, addra => irAddr_net, douta => irWord_net
    );

    dMem_inst : dMem port map (
        clka => clk, wea(0) => d_wr_en_net, addra => dAddr_net,
        dina => dOut_net, douta => dIn_net
    );

    -- Video Subsystem
    framebuffer_inst : framebuffer port map (
        clk1   => clk, 
        en1    => en_115200, 
        en2    => en_25mhz, 
        ld     => fbRST_net,
        addr1  => fbAddr1_net, 
        addr2  => fbAddr2_net,
        wr_en1 => fbWr_en_net, 
        
        -- FIX: Connect CPU Output to RAM Input
        din1   => fbDout1_net, 
        
        -- FIX: Connect RAM Output to CPU Input
        dout1  => fbDin1_net,  
        
        dout2  => fbDout2_net
    );

    vga_ctrl_inst : vga_ctrl port map (
        clk => clk, en => en_25mhz,
        hcount => hcount_net, vcount => open, -- Unconnected per instructions
        vid => vid_net, hs => vga_hs, vs => vs_net
    );
    
    -- Drive top level vs port with internal vs_net
    vga_vs <= vs_net;

    pixel_pusher_inst : pixel_pusher port map (
        clk => clk, en => en_25mhz,
        hcount => hcount_net, vcount => (others => '0'), -- vcount is open on ctrl, tie off here
        vid => vid_net, vs => vs_net,
        pixel => fbDout2_net, addr => fbAddr2_net,
        R => vga_r, G => vga_g, B => vga_b
    );

end structural;