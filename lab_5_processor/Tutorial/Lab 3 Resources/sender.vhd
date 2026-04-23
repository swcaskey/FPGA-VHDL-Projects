library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sender is
    port (
        clk, en, rst, btn, ready : in std_logic;
        send                     : out std_logic;
        char                     : out std_logic_vector(7 downto 0)
    );
end sender;

architecture fsm of sender is

    -- My NetID swc70 in ASCII
    constant N : integer := 5;
    type netid_array is array (0 to N-1) of std_logic_vector(7 downto 0);
    constant NETID : netid_array := (
        x"73",  -- 's'
        x"77",  -- 'w'
        x"63",  -- 'c'
        x"37",  -- '7'
        x"30"   -- '0'
    );

    -- State type enumeration
    type state is (idle, busyA, busyB, busyC);
    signal curr : state := idle;

    -- Counter to index through NETID array
    signal i : integer range 0 to N := 0;

    -- Internal signals for outputs (initialized)
    signal send_int : std_logic := '0';
    signal char_int : std_logic_vector(7 downto 0) := (others => '0');

begin

    -- Connect internal signals to outputs
    send <= send_int;
    char <= char_int;

    process(clk) begin
    if rising_edge(clk) then

        -- Synchronous reset
        if rst = '1' then
            curr <= idle;
            i <= 0;
            send_int <= '0';
            char_int <= (others => '0');

        elsif en = '1' then
            case curr is

                when idle =>
                    if ready = '1' and btn = '1' then
                        if i < N then
                            -- Send next character
                            send_int <= '1';
                            char_int <= NETID(i);
                            i <= i + 1;
                            curr <= busyA;
                        else
                            -- All characters sent, reset counter
                            i <= 0;
                            -- Stay in idle
                        end if;
                    end if;

                when busyA =>
                    -- One clock delay, transition to busyB
                    curr <= busyB;

                when busyB =>
                    -- Deassert send, transition to busyC
                    send_int <= '0';
                    curr <= busyC;

                when busyC =>
                    -- Wait for button release and ready
                    if ready = '1' and btn = '0' then
                        curr <= idle;
                    end if;

                when others =>
                    curr <= idle;

            end case;
        end if;

    end if;
    end process;

end fsm;