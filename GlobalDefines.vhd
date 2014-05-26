library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

package GlobalDefines is
    type EventType is (
        NONE,
        MOVE_CURSOR,
        INSERT_CHAR,
        DELETE_CURRENT,
        );
    type Event is record
        e_type : EventType;
        args   : std_logic_vector(31 downto 0);
    end record;
	
	subtype	Coordinate		is	std_logic_vector(9 downto 0);
	subtype TxtCoordinateX	is	std_logic_vector(5 downto 0);
	subtype TxtCoordinateY	is	std_logic_vector(3 downto 0);
	
	type	ColorElement	is	(Red, Green, Blue);
	type	RGBColor		is	array (ColorElement range Red to Blue) of std_logic;
	
	constant COLOR_BLACK	:	RGBColor	:=	"000";
	constant COLOR_BLUE		:	RGBColor	:=	"001";
	constant COLOR_GREEN	:	RGBColor	:=	"010";
	constant COLOR_CYAN		:	RGBColor	:=	"011";
	constant COLOR_RED		:	RGBColor	:=	"100";
	constant COLOR_PURPLE	:	RGBColor	:=	"101";
	constant COLOR_YELLOW	:	RGBColor	:=	"110";
	constant COLOR_WHITE	:	RGBColor	:=	"111";
end package;
