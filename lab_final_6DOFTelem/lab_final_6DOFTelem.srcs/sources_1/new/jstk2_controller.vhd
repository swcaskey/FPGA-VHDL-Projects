library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity jstk2_controller is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        start_read : in  std_logic;
        data_valid : out std_logic;
        x_out      : out std_logic_vector(15 downto 0);
        y_out      : out std_logic_vector(15 downto 0);
        joystick_btn : out std_logic;
        spi_ready  : in  std_logic;
        spi_data_in: in  std_logic_vector(7 downto 0);
        spi_start  : out std_logic;
        spi_data_out: out std_logic_vector(7 downto 0);
        cs_jstk    : out std_logic
    );
end jstk2_controller;

architecture behavioral of jstk2_controller is
    type state_type is (IDLE, READ_JSTK, DONE);
    signal state : state_type := IDLE;
    signal step  : integer range 0 to 7 := 0;
    
    -- SPI Handshake Bridge FSM
    type spi_state_type is (S_IDLE, S_WAIT_ACK, S_WAIT_READY, S_WAIT_GAP);
    signal spi_state : spi_state_type := S_IDLE;
    signal go_spi    : std_logic := '0';
    signal spi_done  : std_logic := '0';
    signal tx_byte   : std_logic_vector(7 downto 0) := x"00";

    constant CYCLES_15US : integer := 1875; -- 15 us @ 125 MHz
    constant CYCLES_10US : integer := 1250; -- 10 us @ 125 MHz
    signal cs_setup_cnt  : integer range 0 to CYCLES_15US := 0;
    signal cs_setup_done : std_logic := '0';
    signal interbyte_cnt : integer range 0 to CYCLES_10US := 0;
    
    signal x_pos, y_pos : std_logic_vector(7 downto 0);
begin

    -- The SPI Handshake Engine (125 MHz to 1 MHz bridge)
    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                spi_state <= S_IDLE;
                spi_start <= '0';
                spi_done <= '0';
                spi_data_out <= x"00";
                interbyte_cnt <= 0;
            else
                case spi_state is
                    when S_IDLE =>
                        spi_done <= '0';
                        if go_spi = '1' then
                            spi_data_out <= tx_byte;
                            spi_start <= '1';
                            spi_state <= S_WAIT_ACK;
                        end if;
                    when S_WAIT_ACK =>
                        -- HOLD start high until Master drops ready
                        if spi_ready = '0' then
                            spi_start <= '0';
                            spi_state <= S_WAIT_READY;
                        end if;
                    when S_WAIT_READY =>
                        if spi_ready = '1' then
                            interbyte_cnt <= CYCLES_10US;
                            spi_state <= S_WAIT_GAP;
                        end if;
                    when S_WAIT_GAP =>
                        spi_done <= '0';
                        if interbyte_cnt = 0 then
                            spi_done <= '1';
                            spi_state <= S_IDLE;
                        else
                            interbyte_cnt <= interbyte_cnt - 1;
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- The Main Data Controller
    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= IDLE;
                step <= 0;
                go_spi <= '0';
                cs_jstk <= '1';
                data_valid <= '0';
                x_out <= std_logic_vector(to_unsigned(128, 16));
                y_out <= std_logic_vector(to_unsigned(128, 16));
                x_pos <= std_logic_vector(to_unsigned(128, 8));
                y_pos <= std_logic_vector(to_unsigned(128, 8));
                joystick_btn <= '0';
                cs_setup_cnt <= 0;
                cs_setup_done <= '0';
            else
                case state is
                    when IDLE =>
                        data_valid <= '0';
                        cs_jstk <= '1';
                        step <= 0;
                        cs_setup_cnt <= 0;
                        cs_setup_done <= '0';
                        if start_read = '1' then
                            state <= READ_JSTK;
                        end if;

                    when READ_JSTK =>
                        if start_read = '0' then
                            go_spi <= '0';
                            cs_jstk <= '1';
                            step <= 0;
                            cs_setup_cnt <= 0;
                            cs_setup_done <= '0';
                            state <= IDLE;
                        elsif spi_done = '1' then
                            go_spi <= '0';
                            -- JSTK2 CMD_GET_POSITION (0xC0) returns X at byte 5 and Y at byte 6
                            if step = 5 then x_pos <= spi_data_in; end if;
                            if step = 6 then y_pos <= spi_data_in; end if;
                            step <= step + 1;
                        elsif go_spi = '0' then
                            cs_jstk <= '0';
                            if step = 0 then
                                if cs_setup_done = '0' then
                                    cs_setup_done <= '1';
                                    cs_setup_cnt <= CYCLES_15US;
                                elsif cs_setup_cnt > 0 then
                                    cs_setup_cnt <= cs_setup_cnt - 1;
                                else
                                    tx_byte <= x"C0"; -- GET_POSITION command
                                    go_spi <= '1';
                                end if;
                            elsif step < 7 then
                                tx_byte <= x"00"; -- Dummy clocks for response bytes
                                go_spi <= '1';
                            else
                                state <= DONE;
                            end if;
                        end if;

                    when DONE =>
                        cs_jstk <= '1';
                        x_out <= x"00" & x_pos;
                        y_out <= x"00" & y_pos;
                        joystick_btn <= '0';
                        data_valid <= '1';
                        if start_read = '0' then
                            state <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;
end behavioral;
