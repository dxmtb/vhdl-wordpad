library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.GlobalDefines.all;

entity TextDisplayer is
    port (
        clk_100       : in     std_logic;
        reset         : in     std_logic;
        --text information
        txt           : buffer TextArea;
        cursor        : buffer CharPos;
        --mouse
        left_button   : in     std_logic;
        right_button  : in     std_logic;
        middle_button : in     std_logic;
        mousex        : in     XCoordinate;
        mousey        : in     YCoordinate;
        error_no_ack  : in     std_logic;
        --display output
        x_pos         : in     XCoordinate;
        y_pos         : in     YCoordinate;
        rgb           : out    RGBColor;
        --rom interaction
        address       : out    Pointer;
        bitmap        : in     std_logic_vector(63 downto 0)
        );
end entity;  -- TextDisplayer

architecture arch of TextDisplayer is
    constant BOUNDARY : integer := 100;
    signal   button   : std_logic;
    signal   clk      : std_logic;

    signal current_char_pos, leftChar : CharPos;
    signal current_char, next_char    : Char;
    signal low, high, row             : YCoordinate;
    signal left, right                : XCoordinate;
    signal col_mod                    : integer;

    constant VGA_HEIGHT : integer := 480;
    constant VGA_WIDTH  : integer := 640;

begin
    button       <= left_button or right_button or middle_button;
    col_mod      <= x_pos mod 22;
    clk          <= clk_100;
    current_char <= txt.str(current_char_pos);
    next_char    <= txt.str(current_char_pos+1);
    process(clk, reset)
    begin
        if reset = '0' then
            current_char_pos <= MAX_TEXT_LEN-1;
        elsif clk'event and clk = '1' then
            if y_pos = row then
                if x_pos >= right then  --and left + getWidth(txt(current_char+1)) <= VGA_WIDTH then
                    left             <= right;
                    right            <= left + getWidth(next_char);
                    current_char_pos <= current_char_pos + 1;
                end if;
            else
                row   <= y_pos;         --assert y_pos = row + 1
                left  <= 0;
                right <= 0;
                if y_pos < high then
                    current_char_pos <= leftChar - 1;
                else                    --y_pos >= high new line of chars
                    low              <= high;
                    current_char_pos <= current_char_pos + 1;
                    leftChar         <= current_char_pos;
                end if;
            end if;
        end if;
    end process;

    process(current_char)
    begin
        address <= memAddr(current_char, col_mod);
    end process;

    process(x_pos, bitmap, left)
    begin
        if y_pos < BOUNDARY then
            rgb <= COLOR_BLUE;
        elsif x_pos - left < getWidth(current_char) then
            if bitmap(x_pos-left) = '0' then
                rgb <= COLOR_WHITE;
            else
                rgb <= current_char.color;
            end if;
        else
            rgb <= COLOR_WHITE;
        end if;
    end process;

    process (current_char)
    begin
        if getWidth(current_char) > high - low then  --width is same as height
            high <= low + getWidth(current_char);
        end if;
    end process;

end architecture;  -- arch
