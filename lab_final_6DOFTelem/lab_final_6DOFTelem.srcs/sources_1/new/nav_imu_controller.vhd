library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nav_imu_controller is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        
        -- Master FSM triggers this controller
        start_read : in  std_logic;
        data_valid : out std_logic;
        
        -- Reconstructed 16-bit sensor data
        pitch_out  : out std_logic_vector(15 downto 0);
        roll_out   : out std_logic_vector(15 downto 0);
        yaw_out    : out std_logic_vector(15 downto 0);
        
        -- Interface to the SPI Master
        spi_ready  : in  std_logic;
        spi_data_in: in  std_logic_vector(7 downto 0); -- Data from MISO
        spi_start  : out std_logic;
        spi_data_out: out std_logic_vector(7 downto 0); -- Data to MOSI
        
        -- Physical PMOD Pins (Chip Select)
        cs_ag      : out std_logic
    );
end nav_imu_controller;

architecture behavioral of nav_imu_controller is

    -- LSM9DS1 Gyroscope starting address for X-axis Low byte (OUT_X_L_G) is 0x18
    -- To read, we set MSB to 1: 0x18 OR 0x80 = 0x98
    constant GYRO_READ_ADDR : std_logic_vector(7 downto 0) := x"98";
    
    type state_type is (IDLE, SEND_ADDR, WAIT_ADDR, READ_XL, WAIT_XL, READ_XH, WAIT_XH, 
                        READ_YL, WAIT_YL, READ_YH, WAIT_YH, READ_ZL, WAIT_ZL, READ_ZH, WAIT_ZH, DONE);
    signal state : state_type := IDLE;
    
    -- Internal registers to hold the bytes
    signal xl, xh, yl, yh, zl, zh : std_logic_vector(7 downto 0) := (others => '0');

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= IDLE;
                cs_ag <= '1'; -- Chip select is Active Low
                spi_start <= '0';
                data_valid <= '0';
                pitch_out <= (others => '0');
                roll_out  <= (others => '0');
                yaw_out   <= (others => '0');
            else
                case state is
                    when IDLE =>
                        data_valid <= '0';
                        cs_ag <= '1';
                        spi_start <= '0';
                        if start_read = '1' and spi_ready = '1' then
                            cs_ag <= '0'; -- Start transaction
                            spi_data_out <= GYRO_READ_ADDR;
                            spi_start <= '1';
                            state <= WAIT_ADDR;
                        end if;
                        
                    when WAIT_ADDR =>
                        spi_start <= '0';
                        if spi_ready = '1' then
                            -- Address sent, now request the first byte
                            spi_data_out <= x"00"; -- Send dummy byte to clock MISO
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
                            state <= WAIT_ZL;
                        end if;
                        
                    when WAIT_ZL =>
                        spi_start <= '0';
                        if spi_ready = '1' then
                            zl <= spi_data_in;
                            spi_data_out <= x"00";
                            spi_start <= '1';
                            state <= WAIT_ZH;
                        end if;

                    when WAIT_ZH =>
                        spi_start <= '0';
                        if spi_ready = '1' then
                            zh <= spi_data_in;
                            state <= DONE;
                        end if;

                    when DONE =>
                        cs_ag <= '1'; -- End transaction
                        pitch_out <= xh & xl; -- X axis
                        roll_out  <= yh & yl; -- Y axis
                        yaw_out   <= zh & zl; -- Z axis
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