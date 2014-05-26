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

    type CharSizeType is (Small, Middle, Big, Huge);
    constant SizeToPixel is array (CharSizeType range Small to Huge) of Integer := (10, 14, 18, 22);
    type FontType is (Font1, Font2, Font3, Font4);

    type Char is record
        code : std_logic_vector(7 downto 0);
        size : CharSizeType;
        font : FontType;
        color : RGBColor;
    end record;

    type CharPos is std_logic_vector(7 downto 0);

    constant MAX_TEXT_LEN : Integer := 256;
    type TextArea is record
        length : CharPos;
        str : array (0 to MAX_TEXT_LEN-1) of Char;
    end record;

	function memAddr(ch : Char, y : std_logic_vector(8 downto 0)) return std_logic_vector(15 downto 0);
end package;
