library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity jstk2_controller is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        
        -- Master FSM triggers this controller
        start_read : in  std_logic;
        data_valid : out std_logic;
        
        -- Reconstructed 10-bit sensor data (padded to 16 for math consistency)
        x_out      : out std_logic_vector(15 downto 0);
        y_out      : out std_logic_vector(15 downto 0);
        joystick_btn : out std_logic; -- The center click button
        
        -- Interface to the SPI Master
        spi_ready  : in  std_logic;
        spi_data_in: in  std_logic_vector(7 downto 0); 
        spi_start  : out std_logic;
        spi_data_out: out std_logic_vector(7 downto 0); 
        
        -- Physical PMOD Pins (Chip Select)
        cs_jstk    : out std_logic
    );
end jstk2_controller;

architecture behavioral of jstk2_controller is

    type state_type is (IDLE, READ_XL, WAIT_XL, READ_XH, WAIT_XH, 
                        READ_YL, WAIT_YL, READ_YH, WAIT_YH, 
                        READ_BTN, WAIT_BTN, DONE);
    signal state : state_type := IDLE;
    
    signal xl, xh, yl, yh, btn : std_logic_vector(7 downto 0) := (others => '0');

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= IDLE;
                cs_jstk <= '1';
                spi_start <= '0';
                data_valid <= '0';
                x_out <= (others => '0');
                y_out <= (others => '0');
                joystick_btn <= '0';
            else
                case state is
                    when IDLE =>
                        data_valid <= '0';
                        cs_jstk <= '1';
                        spi_start <= '0';
                        if start_read = '1' and spi_ready = '1' then
                            cs_jstk <= '0'; -- Start transaction
                            spi_data_out <= x"00"; -- Dummy byte
                            spi_start <= '1';
                            state <= WAIT_XL;
                        end if;
                        
                    when WAIT_XL =>
                        spi_start <= '0';
                        if spi_ready = '1' then
                            xl <= spi_data_in;
                            spi_data_out <= x"00";
                            spi_start <= '1';
                            state <= WAIT_XH;
                        end if;

                    when WAIT_XH =>
                        spi_start <= '0';
                        if spi_ready = '1' then
                            xh <= spi_data_in;
                            spi_data_out <= x"00";
                            spi_start <= '1';
                            state <= WAIT_YL;
                        end if;
                        
                    when WAIT_YL =>
                        spi_start <= '0';
                        if spi_ready = '1' then
                            yl <= spi_data_in;
                            spi_data_out <= x"00";
                            spi_start <= '1';
                            state <= WAIT_YH;
                        end if;

                    when WAIT_YH =>
                        spi_start <= '0';
                        if spi_ready = '1' then
                            yh <= spi_data_in;
                            spi_data_out <= x"00";
                            spi_start <= '1';
                            state <= WAIT_BTN;
                        end if;
                        
                    when WAIT_BTN =>
                        spi_start <= '0';
                        if spi_ready = '1' then
                            btn <= spi_data_in;
                            state <= DONE;
                        end if;

                    when DONE =>
                        cs_jstk <= '1'; -- End transaction
                        
                        -- Concatenate the High and Low bytes directly into the 16-bit outputs
                        x_out <= xh & xl;
                        y_out <= yh & yl;
                        
                        -- Bit 0 of the 5th byte is the joystick center button
                        joystick_btn <= btn(0); 
                        
                        data_valid <= '1';
                        if start_read = '0' then
                            state <= IDLE;
                        end if;
                        
                    when others =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;

end behavioral;