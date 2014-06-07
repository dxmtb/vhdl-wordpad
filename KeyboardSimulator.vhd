library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.GlobalDefines.all;

entity KeyboardSimulator is
    port (
        clk  : in  std_logic;
        evt  : buffer EventT
        );
end entity;

architecture structural of KeyboardSimulator is
begin
    process(clk)
    begin
		if clk = '0' then
			evt.e_type <= INSERT_CHAR_AT_CURSOR;
			evt.ascii   <= 73;
		else
			evt.e_type <= NONE;
		end if;
    end process;
end architecture;

