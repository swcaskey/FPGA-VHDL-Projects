library ieee;
use ieee.std_logic_1164.all;

entity top is
    port (
        clk : in std_logic;
        btn : in std_logic_vector(1 downto 0);
        TXD : in std_logic;              -- From USB-UART adapter (FPGA receives)
        RXD : out std_logic;             -- To USB-UART adapter (FPGA transmits)
        CTS : out std_logic;             -- Clear to send (directly grounded)
        RTS : out std_logic              -- Request to send (directly grounded)
    );
end top;

architecture structural of top is

    -- Debounce component
    component debounce
        generic (
            clk_freq    : integer := 125_000_000;
            stable_time : integer := 20
        );
        port (
            clk  : in  std_logic;
            btn  : in  std_logic;
            dbnc : out std_logic
        );
    end component;

    -- Clock divider component
    component clock_div
        port (
            clk : in std_logic;
            div : out std_logic
        );
    end component;

    -- Sender FSM component
    component sender
        port (
            clk, en, rst, btn, ready : in std_logic;
            send                     : out std_logic;
            char                     : out std_logic_vector(7 downto 0)
        );
    end component;

    -- UART component
    component uart
        port (
            clk, en, send, rx, rst  : in std_logic;
            charSend                : in std_logic_vector(7 downto 0);
            ready, tx, newChar      : out std_logic;
            charRec                 : out std_logic_vector(7 downto 0)
        );
    end component;

    -- Internal signals
    signal rst_dbnc    : std_logic;  -- Debounced reset (from btn(0))
    signal btn_dbnc    : std_logic;  -- Debounced button (from btn(1))
    signal en_115200   : std_logic;  -- 115,200 Hz enable pulse
    signal send_sig    : std_logic;  -- Send signal from sender to uart
    signal char_sig    : std_logic_vector(7 downto 0);  -- Character from sender to uart
    signal ready_sig   : std_logic;  -- Ready signal from uart to sender
    signal tx_sig      : std_logic;  -- TX output from uart
    signal newChar_sig : std_logic;  -- newChar output from uart (unused)
    signal charRec_sig : std_logic_vector(7 downto 0);  -- Received char (unused)

begin

    -- Tie CTS and RTS to ground (no flow control)
    CTS <= '0';
    RTS <= '0';

    -- Connect uart TX to RXD output (FPGA TX -> adapter RXD)
    RXD <= tx_sig;

    -- u1: Debouncer for reset (btn(0))
    u1: debounce port map (
        clk  => clk,
        btn  => btn(0),
        dbnc => rst_dbnc
    );

    -- u2: Debouncer for send button (btn(1))
    u2: debounce port map (
        clk  => clk,
        btn  => btn(1),
        dbnc => btn_dbnc
    );

    -- u3: Clock divider for 115,200 Hz baud rate
    u3: clock_div port map (
        clk => clk,
        div => en_115200
    );

    -- u4: Sender FSM
    u4: sender port map (
        clk   => clk,
        en    => en_115200,
        rst   => rst_dbnc,
        btn   => btn_dbnc,
        ready => ready_sig,
        send  => send_sig,
        char  => char_sig
    );

    -- u5: UART
    u5: uart port map (
        clk      => clk,
        en       => en_115200,
        send     => send_sig,
        rx       => TXD,        -- Adapter TXD -> FPGA RX
        rst      => rst_dbnc,
        charSend => char_sig,
        ready    => ready_sig,
        tx       => tx_sig,
        newChar  => newChar_sig,
        charRec  => charRec_sig
    );

end structural;
