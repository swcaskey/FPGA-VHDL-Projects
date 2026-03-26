library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_tb is
end top_tb;

architecture tb of top_tb is

    component top port (
        clk : in std_logic;
        btn : in std_logic_vector(1 downto 0);
        TXD : in std_logic;
        RXD : out std_logic;
        CTS : out std_logic;
        RTS : out std_logic
    );
    end component;

    signal clk : std_logic := '0';
    signal btn : std_logic_vector(1 downto 0) := (others => '0');
    signal TXD : std_logic := '1';  -- Idle high
    signal RXD : std_logic;
    signal CTS : std_logic;
    signal RTS : std_logic;

    -- For capturing received data
    signal received_char : std_logic_vector(7 downto 0);
    signal char_count : integer := 0;

begin

    -- Instantiate the top-level design
    dut: top port map(
        clk => clk,
        btn => btn,
        TXD => TXD,
        RXD => RXD,
        CTS => CTS,
        RTS => RTS
    );

    -- Clock process @125 MHz (8ns period)
    process begin
        clk <= '0';
        wait for 4 ns;
        clk <= '1';
        wait for 4 ns;
    end process;

    -- Main stimulus process
    process
        -- Procedure to press and release button with debounce time
        procedure press_button(btn_idx : integer; hold_time : time) is
        begin
            btn(btn_idx) <= '1';
            wait for hold_time;
            btn(btn_idx) <= '0';
            wait for 25 ms;  -- Wait for debounce + transmission
        end procedure;

    begin
        -- Initialize
        btn <= "00";
        TXD <= '1';
        wait for 100 ns;

        -- Apply reset (btn[0])
        report "Applying reset...";
        press_button(0, 25 ms);
        wait for 10 ms;

        report "Starting NetID transmission test...";

        -- Press send button 5 times to send "swc70"
        for i in 0 to 4 loop
            report "Pressing send button for character " & integer'image(i + 1) & " of 5";
            press_button(1, 25 ms);
        end loop;

        -- Wait for final character to finish transmitting
        wait for 10 ms;

        report "End of testbench" severity FAILURE;
        wait;

    end process;

    -- Process to monitor RXD and display transmitted characters
    -- This captures and reports each UART frame sent
    process
        variable bit_time : time := 8680 ns;  -- ~115200 baud (1/115200 sec)
        variable rx_byte : std_logic_vector(7 downto 0);
    begin
        wait until RXD = '0';  -- Wait for start bit
        wait for bit_time / 2;  -- Move to middle of start bit
        
        if RXD = '0' then  -- Confirm start bit
            wait for bit_time;  -- Move to first data bit
            
            -- Sample 8 data bits (LSB first)
            for i in 0 to 7 loop
                rx_byte(i) := RXD;
                wait for bit_time;
            end loop;
            
            -- Check stop bit
            if RXD = '1' then
                char_count <= char_count + 1;
                received_char <= rx_byte;
                report "Received character #" & integer'image(char_count + 1) & 
                       ": '" & character'val(to_integer(unsigned(rx_byte))) & "'" &
                       " (0x" & integer'image(to_integer(unsigned(rx_byte))) & ")";
            else
                report "Framing error - stop bit not detected" severity WARNING;
            end if;
        end if;
    end process;

end tb;
