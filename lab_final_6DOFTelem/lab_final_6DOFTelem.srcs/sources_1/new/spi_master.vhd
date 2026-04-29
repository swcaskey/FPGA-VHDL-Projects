library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_master is
    port (
        clk      : in  std_logic; -- 125 MHz
        spi_en   : in  std_logic; -- 1 MHz enable pulse
        rst      : in  std_logic;
        
        -- Internal FSM Interface
        start    : in  std_logic;
        data_in  : in  std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0);
        ready    : out std_logic;
        
        -- Physical SPI Pins
        mosi     : out std_logic;
        miso     : in  std_logic;
        sclk     : out std_logic
    );
end spi_master;

architecture behavioral of spi_master is
    type state_type is (IDLE, SHIFT);
    signal state : state_type := IDLE;
    
    signal bit_cnt  : integer range 0 to 7 := 7;
    signal tx_shift : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_shift : std_logic_vector(7 downto 0) := (others => '0');
    
    signal sclk_reg : std_logic := '0';
begin
    sclk <= sclk_reg;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= IDLE;
                ready <= '1';
                mosi <= '0';
                sclk_reg <= '0';
                bit_cnt <= 7;
            elsif spi_en = '1' then
                case state is
                    when IDLE =>
                        sclk_reg <= '0';
                        if start = '1' then
                            tx_shift <= data_in;
                            ready <= '0';
                            bit_cnt <= 7;
                            state <= SHIFT;
                        else
                            ready <= '1';
                        end if;
                        
                    when SHIFT =>
                        -- SPI Mode 0: Data changes on falling edge, sampled on rising edge
                        if sclk_reg = '0' then
                            -- Clock is going high (Rising Edge) -> Sample MISO
                            sclk_reg <= '1';
                            rx_shift(bit_cnt) <= miso;
                        else
                            -- Clock is going low (Falling Edge) -> Shift MOSI
                            sclk_reg <= '0';
                            if bit_cnt = 0 then
                                -- Finished 8 bits
                                data_out <= rx_shift;
                                ready <= '1';
                                state <= IDLE;
                            else
                                bit_cnt <= bit_cnt - 1;
                            end if;
                        end if;
                end case;
            end if;
            
            -- Drive MOSI asynchronously to the clock edge for setup time
            if state = SHIFT and sclk_reg = '0' then
                mosi <= tx_shift(bit_cnt);
            end if;
        end if;
    end process;
end behavioral;