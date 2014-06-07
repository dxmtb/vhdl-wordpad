library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.GlobalDefines.all;

entity TextDisplayer is
    port (
        clk_100            : in     std_logic;
        reset              : in     std_logic;
        --text information
        ram_address			: out TxtRamPtr;
        ram_data 			: in STD_LOGIC_VECTOR (15 DOWNTO 0);
        txt_len				: in CharPos;
        cursor             : in     CharPos;
        sel_begin, sel_end : in     CharPos;
        --mouse
        mousex             : in     XCoordinate;
        mousey             : in     YCoordinate;
        error_no_ack       : in     std_logic;
        mouse_pos          : buffer CharPos;
        --display output
        x_pos              : in     XCoordinate;
        y_pos              : in     YCoordinate;
        rgb                : out    RGBColor;
        --rom interaction
        rom_address        : out    CharRomPtr;
        rom_data           : in     std_logic_vector (0 to 15)
        );
end entity;  -- TextDisplayer

architecture arch of TextDisplayer is
    signal button : std_logic;
    signal clk    : std_logic;

    shared variable current_char_pos, left_char : CharPos;
    signal current_char                         : Char;
    signal U, D, row                            : YCoordinate;
    signal L, R                                 : XCoordinate;
    signal first_char                           : CharPos := 0;
    signal flash_counter                        : integer range 0 to 127;
    signal show_cursor                          : std_logic;

begin
    clk          <= clk_100;
    current_char <= raw2char(ram_data);
    R            <= L + getWidth(current_char);
    D            <= U + 16;
    rom_address <= std_logic_vector(to_unsigned(SizeShift(current_char.size) + (FontShift(current_char.font)*128+current_char.code)*SizeToPixel(current_char.size)
                                                +row-U, CharRomPtr'length));
    show_cursor <= '1' when flash_counter < 64 else '0';

    process(clk, reset)
        --variable tmp_pos : CharPos;
    begin
        if reset = '0' then
            current_char_pos := MAX_TEXT_LEN-1;
            left_char        := 0;
            row              <= 0;
        elsif clk'event and clk = '1' then
            if x_pos < 640 and y_pos < 480 then
                if y_pos >= BOUND then
                    if y_pos = BOUND and x_pos = 0 then
                                        --init displayer
                        U                <= BOUND;
                        row              <= BOUND;
                        L                <= 0;
                        current_char_pos := first_char;
                        left_char        := first_char;
                        flash_counter    <= flash_counter + 1;
                    elsif y_pos = row then
                        if L /= R and x_pos >= R then
                            L <= R;
                            if current_char_pos < txt_len and current_char.code /= 13 then
                                current_char_pos := current_char_pos + 1;
                            end if;
                                        --right_char <= current_char_pos;
                        end if;
                    elsif y_pos = row + 1 then
                        row <= y_pos;   --assert y_pos = row + 1
                        L   <= 0;
                        if y_pos < D then
                            current_char_pos := left_char;
                        else            --y_pos >= high new line of chars
                            U <= D;
                            if current_char_pos < txt_len then
                                current_char_pos := current_char_pos + 1;
                            end if;
                            left_char := current_char_pos;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process(clk, reset)
    begin
        if reset = '0' then
            mouse_pos <= 0;
        elsif clk'event and clk = '1' then
            if x_pos = mousex and y_pos = mousey and current_char_pos /= txt_len then
                mouse_pos <= current_char_pos;
            end if;
        end if;
    end process;


    process(x_pos, y_pos, rom_data, L, current_char)
    begin
        if error_no_ack = '0' and ((x_pos = mousex and y_pos >= mousey-5 and y_pos     <= mousey+5) or
                                   (y_pos = mousey-5 and x_pos >= mousex - 1 and x_pos <= mousex + 1) or
                                   (y_pos = mousey+5 and x_pos >= mousex - 1 and x_pos <= mousex + 1)) then  --draw mouse
            rgb <= COLOR_BLACK;
        elsif y_pos < BOUND then        --draw buttons
            rgb <= COLOR_BLUE;
            if y_pos >= Button_Font_Size_Y_START and y_pos < Button_Font_Size_Y_END then
                --Font and Size
                if x_pos >= Button_Small_X_Start and x_pos < Button_Small_X_End then
                    rgb <= COLOR_RED;
                elsif x_pos >= Button_Big_X_Start and x_pos < Button_Big_X_End then
                    rgb <= COLOR_RED;
                elsif x_pos >= Button_Font1_X_Start and x_pos < Button_Font1_X_End then
                    rgb <= COLOR_RED;
                elsif x_pos >= Button_Font2_X_Start and x_pos < Button_Font2_X_End then
                    rgb <= COLOR_RED;
                end if;
            elsif y_pos >= Button_Color_Y_START and y_pos < Button_Color_Y_END then
                for I in 0 to ALL_COLOR'length - 1 loop
                    if x_pos >= Button_Color_X_Start + I * (Button_Color_X_Width+Button_Color_X_Dis) and
                        x_pos < Button_Color_X_Start +
                        I * (Button_Color_X_Width+Button_Color_X_Dis) + Button_Color_X_Width then
                        rgb <= ALL_COLOR(I);
                    end if;
                end loop;
            end if;
        elsif show_cursor = '1' and current_char_pos = cursor and (x_pos = L or x_pos = L + 1) then  --draw cursor
            rgb <= COLOR_BLACK;
        elsif current_char_pos < txt_len and x_pos - L < getWidth(current_char) then  --draw char
            if rom_data(x_pos-L) = '0' then
                if current_char_pos >= sel_begin and current_char_pos < sel_end then
                    rgb <= COLOR_BLACK;
                else
                    rgb <= COLOR_WHITE;
                end if;
            else
                --rgb <= current_char.color;
                rgb <= COLOR_GREEN;
            end if;
        else
            rgb <= COLOR_WHITE;
        end if;
    end process;

end architecture;  -- arch
