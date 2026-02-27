library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity alu_tester is
    port(
        clk : in  std_logic;
        sw : in  std_logic_vector(3 downto 0);
        btn : in  std_logic_vector(3 downto 0);
        led : out std_logic_vector(3 downto 0)
    );
end alu_tester;

architecture structural of alu_tester is
    component my_alu is
        port(
            opcode : in  std_logic_vector(3 downto 0);
            A : in  std_logic_vector(3 downto 0);
            B : in  std_logic_vector(3 downto 0);
            result : out std_logic_vector(3 downto 0)
        );
    end component;
    component debounce is -- from debouncer.vhd
        generic(
            clk_freq : integer := 125_000_000;
            stable_time : integer := 20
        );
        port(
            clk : in  std_logic;
            btn : in  std_logic;
            dbnc : out std_logic
        );
    end component;
    signal db_btn : std_logic_vector(3 downto 0);
    signal reg_opcode : std_logic_vector(3 downto 0) := (others => '0');
    signal reg_A : std_logic_vector(3 downto 0) := (others => '0');
    signal reg_B : std_logic_vector(3 downto 0) := (others => '0');
    signal alu_result : std_logic_vector(3 downto 0);
    signal reg_result : std_logic_vector(3 downto 0) := (others => '0');
begin
    DB0: debounce port map (clk => clk, btn => btn(0), dbnc => db_btn(0));
    DB1: debounce port map (clk => clk, btn => btn(1), dbnc => db_btn(1));
    DB2: debounce port map (clk => clk, btn => btn(2), dbnc => db_btn(2));
    DB3: debounce port map (clk => clk, btn => btn(3), dbnc => db_btn(3));
    ALU: my_alu port map (
        opcode => reg_opcode,
        A => reg_A,
        B => reg_B,
        result => alu_result
    );
    reg_proc: process(clk)
    begin
        if rising_edge(clk) then
            if db_btn(3) = '1' then
                reg_opcode <= (others => '0');
                reg_A <= (others => '0');
                reg_B <= (others => '0');
            else
                if db_btn(2) = '1' then
                    reg_opcode <= sw;
                end if;
                if db_btn(1) = '1' then
                    reg_A <= sw;
                end if;
                if db_btn(0) = '1' then
                    reg_B <= sw;
                end if;
            end if;
            reg_result <= alu_result;
        end if;
    end process;
    led <= reg_result;
end structural;