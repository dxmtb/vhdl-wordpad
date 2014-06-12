library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.GlobalDefines.all;

entity TextDisplayer is
    port (
        clk_100            : in     std_logic;
        reset              : in     std_logic;
        --text information
        ram_address        : out    TxtRamPtr;
        ram_data           : in     std_logic_vector (11 downto 0);
        txt_len            : in     CharPos;
        cursor             : in     CharPos;
        sel_begin, sel_end : in     CharPos;
        processor_status   : in     StatusProcessor;
        first_char         : in     CharPos;
        now_size           : in     CharSizeType;
        now_font           : in     FontType;
        now_color          : in     RGBColor;
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
        rom_data           : in     std_logic_vector (0 to 15);
        button_addr        : out    std_logic_vector (7 downto 0);
        button_data        : in     std_logic_vector (0 to 34);
        font3 : in boolean
        );
end entity;  -- TextDisplayer

architecture arch of TextDisplayer is
    signal clk : std_logic;

    shared variable current_char_pos, left_char : CharPos := 0;
    signal current_char                         : Char;
    signal U, D, row                            : YCoordinate;
    signal L, R                                 : XCoordinate;
    signal flash_counter                        : integer range 0 to 127;
    signal show_cursor                          : std_logic;
    signal button_addr_int                      : integer;
    signal cursor_drawn                         : integer;

begin
    clk <= clk_100;
    R   <= L + getWidth(current_char);
    D   <= U + 16;

    show_cursor <= '1' when flash_counter < 64 else '0';

    current_char <= raw2char(ram_data);
    ram_address  <= std_logic_vector(to_unsigned(current_char_pos, TxtRamPtr'length));
    button_addr  <= std_logic_vector(to_unsigned(button_addr_int, button_addr'length));

    process(clk)
	begin
		if not font3 then
			rom_address <= std_logic_vector(to_unsigned(SizeShift(current_char.size)
						+ (FontShift(current_char.font)*128+current_char.code)*
						SizeToPixel(current_char.size)+row-U, CharRomPtr'length));
		else
			rom_address <= std_logic_vector(to_unsigned(7680 + current_char.code*16+
						row-U, CharRomPtr'length));
		end if;
	end process;

    process(clk, reset)
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

    process(clk)
    begin
        if clk'event and clk = '1' then
            if y_pos >= Button_Font_Size_Y_START-1 and y_pos < Button_Font_Size_Y_END-1 then
                if x_pos = 0 then
                    button_addr_int <= y_pos+1-Button_Font_Size_Y_START;
                end if;
            end if;
            if y_pos >= Button_Font_Size_Y_START and y_pos < Button_Font_Size_Y_END then
                if x_pos = Button_Small_X_End then
                    button_addr_int <= 35+y_pos-Button_Font_Size_Y_START;
                elsif x_pos = Button_Big_X_End then
                    button_addr_int <= 70+y_pos-Button_Font_Size_Y_START;
                elsif x_pos = Button_Font1_X_End then
                    button_addr_int <= 105+y_pos-Button_Font_Size_Y_START;
                elsif x_pos = Button_Font2_X_End then
                    button_addr_int <= 140+y_pos-Button_Font_Size_Y_START;
                elsif x_pos = Button_Save_X_End then
                    button_addr_int <= 175+y_pos-Button_Font_Size_Y_START;
                end if;
            end if;
        end if;
    end process;

    process(clk)  --x_pos, y_pos, rom_data, L, current_char)
    begin
        if clk'event and clk = '1' then
            if x_pos = 0 then
                cursor_drawn <= 7;
            end if;
            if error_no_ack = '0' and ((x_pos = mousex and y_pos >= mousey-5 and y_pos     <= mousey+5) or
                                       (y_pos = mousey-5 and x_pos >= mousex - 1 and x_pos <= mousex + 1) or
                                       (y_pos = mousey+5 and x_pos >= mousex - 1 and x_pos <= mousex + 1)) then  --draw mouse
                rgb <= COLOR_BLACK;
            elsif y_pos < BOUND then    --draw buttons
                rgb <= COLOR_BLUE;
                if y_pos >= Button_Font_Size_Y_START and y_pos < Button_Font_Size_Y_END then
                                        --Font and Size
                    if x_pos >= Button_Small_X_Start and x_pos < Button_Small_X_End then
                        if button_data(x_pos-Button_Small_X_Start) = '1' then
                            if now_size = SMALL then
                                rgb <= COLOR_RED;
                            else
                                rgb <= COLOR_BLACK;
                            end if;
                        else
                            rgb <= COLOR_WHITE;
                        end if;
                    elsif x_pos >= Button_Big_X_Start and x_pos < Button_Big_X_End then
                        if button_data(x_pos-Button_Big_X_Start) = '1' then
                            if now_size = BIG then
                                rgb <= COLOR_RED;
                            else
                                rgb <= COLOR_BLACK;
                            end if;
                        else
                            rgb <= COLOR_WHITE;
                        end if;
                    elsif x_pos >= Button_Font1_X_Start and x_pos < Button_Font1_X_End then
                        if button_data(x_pos-Button_Font1_X_Start) = '1' then
                            if not font3 and now_font = FONT1 then
                                rgb <= COLOR_RED;
                            else
                                rgb <= COLOR_BLACK;
                            end if;
                        else
                            rgb <= COLOR_WHITE;
                        end if;
                    elsif x_pos >= Button_Font2_X_Start and x_pos < Button_Font2_X_End then
                        if button_data(x_pos-Button_Font2_X_Start) = '1' then
                            if not font3 and now_font = FONT2 then
                                rgb <= COLOR_RED;
                            else
                                rgb <= COLOR_BLACK;
                            end if;
                        else
                            rgb <= COLOR_WHITE;
                        end if;
					elsif x_pos >= Button_Font3_X_Start and x_pos < Button_Font3_X_End then
						if font3 then
							rgb <= COLOR_RED;
						else
							rgb <= COLOR_BLUE;
						end if;
                    elsif x_pos >= Button_Save_X_Start and x_pos < Button_Save_X_End then
                        if button_data(x_pos-Button_Save_X_Start) = '1' then
                            rgb <= COLOR_BLACK;
                        else
                            rgb <= COLOR_WHITE;
                        end if;
                    elsif x_pos >= Button_Open_X_Start and x_pos < Button_Open_X_End then
                        if button_data(x_pos-Button_Open_X_Start) = '1' then
                            rgb <= COLOR_BLACK;
                        else
                            rgb <= COLOR_WHITE;
                        end if;
                    end if;
                elsif y_pos >= Button_Color_Y_START and y_pos < Button_Color_Y_END then
                    for I in 0 to ALL_COLOR'length - 1 loop
                        if x_pos >= Button_Color_X_Start + I * (Button_Color_X_Width+Button_Color_X_Dis) and
                            x_pos < Button_Color_X_Start +
                            I * (Button_Color_X_Width+Button_Color_X_Dis) + Button_Color_X_Width then
                            rgb <= ALL_COLOR(I);
                        end if;
                    end loop;
                    if x_pos >= 550 and x_pos < 580 then
                        rgb <= now_color;
                    elsif x_pos >= 600 and x_pos < 630 then
                        case processor_status is
                            when Waiting =>
                                rgb <= COLOR_BLACK;
                            when Waiting2 =>
                                rgb <= COLOR_BLACK;
                            when Insert =>
                                rgb <= COLOR_RED;
                            when Del =>
                                rgb <= COLOR_GREEN;
                            when ResetStatus =>
                                rgb <= COLOR_YELLOW;
                            when SetFont =>
                                rgb <= COLOR_PURPLE;
                            when SetFontEnter =>
                                rgb <= COLOR_CYAN;
                            when others =>
                                rgb <= COLOR_WHITE;
                        end case;
                    end if;
                end if;
            elsif show_cursor = '1' and current_char_pos = cursor and (x_pos = L or x_pos = L + 1) and current_char_pos < txt_len and cursor_drawn > 0 then  --draw cursor
                rgb          <= COLOR_BLACK;
                cursor_drawn <= cursor_drawn-1;
            elsif current_char_pos < txt_len and x_pos - L < getWidth(current_char) then  --draw char
                if rom_data(x_pos-L) = '0' then
                    if current_char_pos >= sel_begin and current_char_pos < sel_end then
                        rgb <= COLOR_BLACK;
                    else
                        rgb <= COLOR_WHITE;
                    end if;
                else
                    rgb <= current_char.color;
                end if;
            else
                rgb <= COLOR_WHITE;
            end if;
        end if;
    end process;

end architecture;  -- arch
