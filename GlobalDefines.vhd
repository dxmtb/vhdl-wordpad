library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

package GlobalDefines is
    type EventType is (
        NONE,
        MOVE_CURSOR,
        INSERT_CHAR_AT_CURSOR,
        DELETE_AT_CURSOR
        );
    subtype ArgsType is integer range 0 to 255;
    type    EventT is record
        e_type : EventType;
        args   : ArgsType;
    end record;

    subtype XCoordinate is integer range 0 to 800;
    subtype YCoordinate is integer range 0 to 600;

    type ColorElement is (Red, Green, Blue);
    type RGBColor is array (ColorElement range Red to Blue) of std_logic;

    constant COLOR_BLACK  : RGBColor := "000";
    constant COLOR_BLUE   : RGBColor := "001";
    constant COLOR_GREEN  : RGBColor := "010";
    constant COLOR_CYAN   : RGBColor := "011";
    constant COLOR_RED    : RGBColor := "100";
    constant COLOR_PURPLE : RGBColor := "101";
    constant COLOR_YELLOW : RGBColor := "110";
    constant COLOR_WHITE  : RGBColor := "111";

    type     CharSizeType is (Small, Big);
    type     CharSizeIndexedArray is array (CharSizeType range Small to Big) of integer;
    constant SizeToPixel : CharSizeIndexedArray := (14, 16);
    constant SizeShift   : CharSizeIndexedArray := (0, 3584);

    type     FontType is (Font1, Font2);
    type     FontTypeIndexedArray is array (FontType range Font1 to Font2) of integer;
    constant FontShift : FontTypeIndexedArray := (0, 1);

    subtype CharCode is integer range 0 to 127;

    type Char is record
        code  : CharCode;
        size  : CharSizeType;
        font  : FontType;
        color : RGBColor;
    end record;

    constant MAX_TEXT_LEN : integer := 255;
    subtype  CharPos is integer range 0 to MAX_TEXT_LEN;
    type     CharSeqT is array (0 to MAX_TEXT_LEN-1) of Char;
    type     TextArea is record
        length : CharPos;
        str    : CharSeqT;
    end record;

    subtype CharRomPtr is STD_LOGIC_VECTOR (12 DOWNTO 0);
    function memAddr(ch  : Char; y : YCoordinate) return CharRomPtr;
    function getWidth(ch : Char) return XCoordinate;
end package;

package body GlobalDefines is
    function memAddr(ch : Char; y : YCoordinate) return CharRomPtr is
    begin
        return std_logic_vector(to_unsigned(SizeShift(ch.size) + (FontShift(ch.font)*128+ch.code)*SizeToPixel(ch.size)+y, CharRomPtr'length));
    end function;
    function getWidth(ch : Char) return XCoordinate is
    begin
        return SizeToPixel(ch.size);
    end function;
end GlobalDefines;
