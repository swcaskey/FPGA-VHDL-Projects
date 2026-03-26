library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
    port (
        clk, en, send, rst  : in std_logic;
        char                : in std_logic_vector (7 downto 0);
        ready, tx           : out std_logic
    );
end uart_tx;

architecture fsm of uart_tx is

    -- state type enumeration and state variable
    type state is (idle, start, data, stop);
    signal curr : state := idle;

    -- register to hold character being transmitted
    signal d : std_logic_vector (7 downto 0) := (others => '0');

    -- counter for data state (counts 0-7 for 8 bits)
    signal count : std_logic_vector(2 downto 0) := (others => '0');

    -- Internal signals for outputs (initialized to idle state values)
    signal ready_int : std_logic := '1';
    signal tx_int : std_logic := '1';

begin

    -- Connect internal signals to outputs
    ready <= ready_int;
    tx <= tx_int;

    -- FSM process (single process implementation)
    process(clk) begin
    if rising_edge(clk) then

        -- resets the state machine and its outputs
        if rst = '1' then

            curr <= idle;
            d <= (others => '0');
            count <= (others => '0');
            ready_int <= '1';
            tx_int <= '1';

        -- usual operation
        elsif en = '1' then
            case curr is

                when idle =>
                    ready_int <= '1';
                    tx_int <= '1';
                    if send = '1' then
                        -- load character and transition to start
                        d <= char;
                        curr <= start;
                    end if;

                when start =>
                    ready_int <= '0';
                    tx_int <= '0';  -- start bit
                    count <= (others => '0');  -- reset bit counter
                    curr <= data;

                when data =>
                    ready_int <= '0';
                    tx_int <= d(0);  -- send LSB
                    if unsigned(count) < 7 then
                        -- shift right to get next bit ready
                        d <= '0' & d(7 downto 1);
                        count <= std_logic_vector(unsigned(count) + 1);
                    else
                        -- all 8 bits sent, go to stop
                        curr <= stop;
                    end if;

                when stop =>
                    ready_int <= '0';
                    tx_int <= '1';  -- stop bit
                    curr <= idle;

                when others =>
                    curr <= idle;

            end case;
        end if;

    end if;
    end process;

end fsm;