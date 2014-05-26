library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use works.GlobalDefines.all;

entity MasterController is
    port (
        clk         : in    std_logic;
        left_button : out std_logic;
        right_button : out std_logic;
		middle_button : out std_logic;
        mousex: buffer std_logic_vector(9 downto 0);
        mousey: buffer std_logic_vector(9 downto 0);
		keyboard_event : inout Event
		sel_begin, sel_end : buffer std_logic_vector(31 downto 0)
        ) ;
end entity;  -- MasterController

architecture arch of MasterController is
	type State is (wait_event, insert, delete, format, )
	
	signal text_cursor, step : std_logic_vector(31 downto 0) ;
	signal current_state : State;

begin
	
	main : process( clk )
	begin
		if( rising_edge(clk) ) then
			case keyboard_event is
				when NONE => 
				null;
				when MOVE_CURSOR =>
				text_cursor <= text_cursor + keyboard_event.args;
				when INSERT_CHAR =>
				-- first step: move memory
				-- second step: insert
				null;
		end if ;
	end process ; -- main

end architecture;  -- arch
