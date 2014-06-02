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
        rom_address		: out STD_LOGIC_VECTOR (13 DOWNTO 0);
		rom_data		: in STD_LOGIC_VECTOR (15 DOWNTO 0)
        );
end entity;  -- TextDisplayer

architecture arch of TextDisplayer is
    constant BOUNDARY : integer := 100;
    signal   button   : std_logic;
    signal   clk      : std_logic;

    signal current_char_pos, leftChar : CharPos;
    signal current_char, next_char    : Char;
    signal U, D, row             : YCoordinate;
    signal L, R                : XCoordinate;
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
    variable tmp_pos : CharPos;
    begin
        if reset = '0' then
            current_char_pos <= MAX_TEXT_LEN-1;
            leftChar <= 0;
            row <= 0;
        elsif clk'event and clk = '1' then
            if y_pos = row then
                if x_pos >= R then  --and left + getWidth(txt(current_char+1)) <= VGA_WIDTH then
                    L            <= R;
                    R            <= L + getWidth(next_char);
                    current_char_pos <= current_char_pos + 1;
                end if;
            else
                row   <= y_pos;         --assert y_pos = row + 1
                L  <= 0;
                R <= 0;
                if y_pos < D then
                    current_char_pos <= leftChar - 1;
                else                    --y_pos >= high new line of chars
                    U <= D;
                    tmp_pos := current_char_pos + 1;
                    current_char_pos <= tmp_pos;
                    leftChar <= tmp_pos;
                end if;
            end if;
        end if;
    end process;

    process(current_char, row, U)
    begin
        rom_address <= std_logic_vector(to_unsigned(memAddr(current_char, row-U), 14));
    end process;

    process(x_pos, y_pos, rom_data, L)
    begin
        if y_pos < BOUNDARY then
            rgb <= COLOR_BLUE;
        elsif x_pos - L < getWidth(current_char) then
            if rom_data(x_pos-L) = '0' then
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
        if getWidth(current_char) > D - U then  --width is same as height
            D <= U + getWidth(current_char);
        end if;
    end process;

end architecture;  -- arch
