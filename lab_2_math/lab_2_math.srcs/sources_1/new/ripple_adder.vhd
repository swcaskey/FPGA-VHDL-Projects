library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ripple_adder is
    port(
    a, b : in std_logic_vector (3 downto 0);
    cin : in std_logic;
    
    s : out std_logic_vector (3 downto 0);
    cout : out std_logic
    );
end ripple_adder;

architecture structural of ripple_adder is
    component adder is
        port(
        a, b, cin : in std_logic;
        s, cout : out std_logic
        );
    end component;
    signal c1, c2, c3 : std_logic;
begin
    adder0: adder port map ( -- rightmost bit
    a => a(0),
    b => b(0),
    cin => cin,
    s => s(0),
    cout => c1
    );
    adder1: adder port map (
    a => a(1),
    b => b(1),
    cin => c1,
    s => s(1),
    cout => c2
    );
    adder2: adder port map (
    a => a(2),
    b => b(2),
    cin => c2,
    s => s(2),
    cout => c3
    );
    adder3: adder port map ( -- leftmost bit
    a => a(3),
    b => b(3),
    cin => c3,
    s => s(3),
    cout => cout
    );
end structural;