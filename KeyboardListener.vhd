library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.GlobalDefines.all;

entity KeyboardListener is
	port (
             clk   : inout std_logic;
             data  : inout    std_logic;
             evt : buffer EventT
	);
end entity;

architecture structural of KeyboardListener is
    component Keyboard is
        port (
        datain, clkin : in std_logic ; -- PS2 clk and data
        scancode : out std_logic_vector(7 downto 0) -- scan code signal output
    ) ;
    end component ;
    signal scancode : std_logic_vector(7 downto 0);
begin
    m1: Keyboard port map(datain=>data, clkin=>clk, scancode=>scancode);
    process(scancode)
	begin
		case scancode is
			when "00101110" =>
				evt.e_type <= INSERT_CHAR_AT_CURSOR;
				evt.args <= 73;
			when others =>
				evt.e_type <= NONE;
		end case;
    end process;

end architecture;

