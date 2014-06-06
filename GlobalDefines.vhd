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

    constant BOUND  : integer := 100;

    subtype XCoordinate is integer range 0 to 800;
    subtype YCoordinate is integer range 0 to 600;

    constant Button_Font_Size_Y_START : integer := 10;
    constant Button_Font_Size_Y_END : integer := 45;

    constant Button_Color_Y_START : integer := 55;
    constant Button_Color_Y_END : integer := 90;

    constant Button_Small_X_Start : integer := 10;
    constant Button_Small_X_End : integer := 60;
    constant Button_Big_X_Start : integer := 80;
    constant Button_Big_X_End : integer := 130;

    constant Button_Font1_X_Start : integer := 150;
    constant Button_Font1_X_End : integer := 200;
    constant Button_Font2_X_Start : integer := 220;
    constant Button_Font2_X_End : integer := 270;

    constant Button_Color_X_Start : integer := 10;
    constant Button_Color_X_Width : integer := 30;
    constant Button_Color_X_Dis : integer := 15;

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

    type ALL_COLOR_T is array (0 to 7) of RGBColor;
    constant ALL_COLOR : ALL_COLOR_T :=
		(COLOR_BLACK, COLOR_BLUE, COLOR_GREEN, COLOR_CYAN, COLOR_RED, COLOR_PURPLE, COLOR_YELLOW, COLOR_WHITE);

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
        len : CharPos;
        str    : CharSeqT;
    end record;

    subtype CharRomPtr is std_logic_vector (12 downto 0);
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
