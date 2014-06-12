library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

package GlobalDefines is

    subtype ASCII is integer range 0 to 127;

    type StatusProcessor is (Waiting, Waiting2, Insert, Del, ResetStatus, SetFont, SetFontEnter, SaveFile, OpenFile);

    constant HOLD_TIME : integer := 100;

    constant BOUND      : integer := 100;
    constant VGA_HEIGHT : integer := 480;
    constant VGA_WIDTH  : integer := 640;

    subtype XCoordinate is integer range 0 to 800;
    subtype YCoordinate is integer range 0 to 600;

    constant Button_Font_Size_Y_START : integer := 10;
    constant Button_Font_Size_Y_END   : integer := 45;

    constant Button_Color_Y_START : integer := 55;
    constant Button_Color_Y_END   : integer := 90;

    constant Button_Small_X_Start : integer := 10;
    constant Button_Small_X_End   : integer := 45;
    constant Button_Big_X_Start   : integer := 80;
    constant Button_Big_X_End     : integer := 115;

    constant Button_Font1_X_Start : integer := 150;
    constant Button_Font1_X_End   : integer := 185;
    constant Button_Font2_X_Start : integer := 220;
    constant Button_Font2_X_End   : integer := 255;

    constant Button_Save_X_Start : integer := 290;
    constant Button_Save_X_End   : integer := 325;
    constant Button_Open_X_Start : integer := 360;
    constant Button_Open_X_End   : integer := 395;

    constant Button_Font3_X_Start : integer := 430;
    constant Button_Font3_X_End   : integer := 465;

    constant Button_Color_X_Start : integer := 10;
    constant Button_Color_X_Width : integer := 30;
    constant Button_Color_X_Dis   : integer := 15;

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

    type     ALL_COLOR_T is array (0 to 5) of RGBColor;
    constant ALL_COLOR : ALL_COLOR_T :=
        (COLOR_BLACK, COLOR_GREEN, COLOR_CYAN, COLOR_RED, COLOR_PURPLE, COLOR_YELLOW);

    type EventType is (
        NONE,
        MOVE_CURSOR,
        MOVE_FIRST,
        INSERT_CHAR_AT_CURSOR,
        DELETE_AT_CURSOR,
        SET_FORMAT
        );

    type EventT is record
        e_type      : EventType;
        ascii       : ASCII;
        format_type : integer range 0 to 2;
        format      : integer range 0 to ALL_COLOR_T'length - 1;
    end record;

    type     CharSizeType is (Small, Big);
    type     CharSizeIndexedArray is array (CharSizeType range Small to Big) of integer;
    constant SizeToPixel : CharSizeIndexedArray := (14, 16);
    constant SizeShift   : CharSizeIndexedArray := (0, 3584);

    type     FontType is (Font1, Font2);
    type     FontTypeIndexedArray is array (FontType range Font1 to Font2) of integer;
    constant FontShift : FontTypeIndexedArray := (0, 1);

    constant MAX_TEXT_LEN : integer := 2047;
    subtype  CharCode is integer range 0 to 127;

    subtype RamData is std_logic_vector (11 downto 0);

    type Char is record
        code  : CharCode;
        size  : CharSizeType;
        font  : FontType;
        color : RGBColor;
    end record;

    subtype CharPos is integer range -1 to MAX_TEXT_LEN;
    type    CharSeqT is array (0 to MAX_TEXT_LEN-1) of Char;
    type    TextArea is record
        len : CharPos;
        str : CharSeqT;
    end record;

    subtype CharRomPtr is std_logic_vector (13 downto 0);
    subtype TxtRamPtr is std_logic_vector (10 downto 0);
    function memAddr(ch    : Char; y : YCoordinate) return CharRomPtr;
    function getWidth(ch   : Char) return XCoordinate;
    function raw2char(data : RamData) return Char;
    function char2raw(ch   : Char) return RamData;
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
    function raw2char(data : RamData) return Char is
        variable ret : Char;
    begin
        ret.code := to_integer(unsigned(data(6 downto 0)));
        if data(7) = '0' then
            ret.size := SMALL;
        else
            ret.size := BIG;
        end if;
        if data(8) = '0' then
            ret.font := FONT1;
        else
            ret.font := FONT2;
        end if;
        ret.color(Blue)  := data(9);
        ret.color(Green) := data(10);
        ret.color(Red)   := data(11);
        return ret;
    end function;
    function char2raw(ch : Char) return RamData is
        variable data : RamData;
        variable tmp  : std_logic_vector(6 downto 0);
    begin
        data(6 downto 0) := std_logic_vector(to_unsigned(ch.code, 7));
        if ch.size = SMALL then
            data(7) := '0';
        else
            data(7) := '1';
        end if;
        if ch.font = FONT1 then
            data(8) := '0';
        else
            data(8) := '1';
        end if;
        data(9)  := ch.color(Blue);
        data(10) := ch.color(Green);
        data(11) := ch.color(Red);
        return data;
    end function;
end GlobalDefines;
