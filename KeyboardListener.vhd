library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.GlobalDefines.all;

entity KeyboardListener is
	port (
             clk   : inout std_logic;
             data  : in    std_logic;
             event : inout Event
	);
end entity;

architecture structural of Controller is
    component Keyboard is
        port (
        datain, clkin : in std_logic ; -- PS2 clk and data
        scancode : out std_logic_vector(7 downto 0) -- scan code signal output
    ) ;
    end component ;
    signal scancode : std_logic_vector(7 downto 0);
begin
    m1: Keyboard port map(datain=>data, clkin=>clk, scancode);
    case scancode is
        when "00101110" =>
            event.e_type <= INSERT_CHAR;
            event.args <= (others => '0');
            event.args(7 downto 0) <= "01110100";
        when "others" =>
            event.e_type <= NONE;
    end case;

end architecture;

