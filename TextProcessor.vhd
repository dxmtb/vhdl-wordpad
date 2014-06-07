library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.GlobalDefines.all;

entity TextProcessor is
    port(
        rst, clk           : in     std_logic;
        --mouse in
        left_button        : in     std_logic;
        right_button       : in     std_logic;
        middle_button      : in     std_logic;
        mousex             : in     XCoordinate;
        mousey             : in     YCoordinate;
        error_no_ack       : in     std_logic;
        mouse_pos          : in     CharPos;
        --keyboard in
        keyClk             : in     std_logic;
        ascii              : in     ASCII;
        --vga in
        x_pos              : in     XCoordinate;
        y_pos              : in     YCoordinate;
        sel_begin, sel_end : buffer CharPos := 0;
        txt                : buffer TextArea;
        cursor             : buffer CharPos := 0
        );
end entity;

architecture structural of TextProcessor is
    signal format_char       : Char;
    signal lbutton, rbutton  : std_logic;
    shared variable finished : std_logic := '1';
    signal keyboard_event    : EventT;
    signal rbutton_before    : std_logic := '0';
    signal flag_sel          : boolean;
    signal key_clk_before    : std_logic := '0';
begin
    lbutton  <= not error_no_ack and left_button;
    rbutton  <= not error_no_ack and right_button;
    flag_sel <= sel_begin < sel_end;

    process(clk, rst)
    begin
        if rst = '0' then
            sel_begin <= 0;
            sel_end   <= 0;
        elsif clk'event and clk = '1' and mousey >= BOUND and mouse_pos < txt.len then
            if rbutton = '1' then
                if rbutton_before = '0' then
                    sel_begin      <= mouse_pos;
                    sel_end        <= mouse_pos + 1;
                    rbutton_before <= '1';
                else
                    sel_end <= mouse_pos + 1;
                end if;
            elsif rbutton = '0' and rbutton_before = '1' then
                sel_end        <= mouse_pos + 1;
                rbutton_before <= '0';
            end if;
        end if;
    end process;

    process(clk, rst)
    begin
        if rst = '0' then
            keyboard_event.e_type <= NONE;
        elsif clk'event and clk = '1' then
            if keyClk = '1' and key_clk_before = '0' then
                case ascii is
                    when 27 =>          --esc for left
                        keyboard_event.e_type <= MOVE_CURSOR;
                        keyboard_event.ascii  <= 1;
                    when 9 =>           --tab for right
                        keyboard_event.e_type <= MOVE_CURSOR;
                        keyboard_event.ascii  <= 0;
                    when 8 =>           --backspace for del
                        keyboard_event.e_type <= DELETE_AT_CURSOR;
                    when others =>
                        keyboard_event.e_type <= INSERT_CHAR_AT_CURSOR;
                        keyboard_event.ascii  <= ascii;
                end case;
            else
                keyboard_event.e_type <= NONE;
            end if;
            key_clk_before <= keyClk;
        end if;
    end process;

    process(clk, rst)
        variable tmp_pos     : CharPos;
        variable change_font : std_logic;
    begin
        if rst = '0' then
            txt.len <= MAX_TEXT_LEN/2;
            for I in 0 to MAX_TEXT_LEN/2 - 1 loop
                txt.str(I).code  <= (I+MAX_TEXT_LEN/2) mod 128;
                txt.str(I).size  <= BIG;
                txt.str(I).color <= COLOR_GREEN;
            end loop;
            format_char.size  <= BIG;
            format_char.font  <= FONT1;
            format_char.color <= COLOR_GREEN;
            finished          := '1';
        elsif clk'event and clk = '1' and finished = '1' then
            finished := '0';
--                      case mouse_event.e_type is
--                      when SET_FORMAT =>
--                              for I in 0 to MAX_TEXT_LEN - 1 loop
--                                      if I >= sel_begin and I < sel_end then
--                                              case mouse_event.format_type is
--                                              when 0 =>
--                                                      if mouse_event.format = 0 then
--                                                              txt.str(I).size <= SMALL;
--                                                      elsif mouse_event.format = 1 then
--                                                              txt.str(I).size <= BIG;
--                                                      end if;
--                                              when 1 =>
--                                                      if mouse_event.format = 0 then
--                                                              txt.str(I).font <= FONT1;
--                                                      elsif mouse_event.format = 1 then
--                                                              txt.str(I).font <= FONT2;
--                                                      end if;
--                                              when 2 =>
--                                                      txt.str(I).color <= ALL_COLOR(mouse_event.format);
--                                              when others =>
--                                                      null;
--                                              end case;
--                                      end if;
--                              end loop;
--                      when others =>
--                              null;
--                      end case;
--                      mouse_event.e_type <= NONE;
            if lbutton = '1' then
                if mousey >= BOUND then  --click in text area
                    if mouse_pos < txt.len then
                        cursor <= mouse_pos;
                    end if;
                else                     --click in button area
                    if y_pos >= Button_Font_Size_Y_START and y_pos < Button_Font_Size_Y_END then
                                         --Font and Size
                        if x_pos >= Button_Small_X_Start and x_pos < Button_Small_X_End then
                            if flag_sel then
                                for J in 0 to MAX_TEXT_LEN - 1 loop
                                    if J >= sel_begin and J < sel_end then
                                        txt.str(J).size <= SMALL;
                                    end if;
                                end loop;
                            end if;
                            format_char.size <= SMALL;
                        elsif x_pos >= Button_Big_X_Start and x_pos < Button_Big_X_End then
                            if flag_sel then
                                for J in 0 to MAX_TEXT_LEN - 1 loop
                                    if J >= sel_begin and J < sel_end then
                                        txt.str(J).size <= BIG;
                                    end if;
                                end loop;
                            end if;
                            format_char.size <= BIG;
                        elsif x_pos >= Button_Font1_X_Start and x_pos < Button_Font1_X_End then
                            if flag_sel then
                                for J in 0 to MAX_TEXT_LEN - 1 loop
                                    if J >= sel_begin and J < sel_end then
                                        txt.str(J).font <= FONT1;
                                    end if;
                                end loop;
                            end if;
                            format_char.font <= FONT1;
                        elsif x_pos >= Button_Font2_X_Start and x_pos < Button_Font2_X_End then
                            if flag_sel then
                                for J in 0 to MAX_TEXT_LEN - 1 loop
                                    if J >= sel_begin and J < sel_end then
                                        txt.str(J).font <= FONT2;
                                    end if;
                                end loop;
                            end if;
                            format_char.font <= FONT2;
                        end if;
                    elsif y_pos >= Button_Color_Y_START and y_pos < Button_Color_Y_END then
                        for I in 0 to ALL_COLOR'length - 1 loop
                            if x_pos >= Button_Color_X_Start + I * (Button_Color_X_Width+Button_Color_X_Dis) and
                                x_pos < Button_Color_X_Start +
                                I * (Button_Color_X_Width+Button_Color_X_Dis) + Button_Color_X_Width then
                                format_char.color <= ALL_COLOR(I);
                                if flag_sel then
                                    for J in 0 to MAX_TEXT_LEN - 1 loop
                                        if J >= sel_begin and J < sel_end then
                                            txt.str(J).color <= ALL_COLOR(I);
                                        end if;
                                    end loop;
                                end if;
                            end if;
                        end loop;
                    end if;
                end if;
            end if;

            case keyboard_event.e_type is
                when INSERT_CHAR_AT_CURSOR =>
                    if cursor < txt.len then
                        tmp_pos := cursor;
                    else
                        tmp_pos := txt.len;
                    end if;
                    for I in MAX_TEXT_LEN - 1 downto 1 loop
                        if I > tmp_pos then
                            txt.str(I) <= txt.str(I-1);
                        end if;
                    end loop;
                    txt.str(tmp_pos)      <= format_char;
                    txt.str(tmp_pos).code <= keyboard_event.ascii;
                    txt.len               <= txt.len + 1;
                    cursor                <= cursor + 1;
                when DELETE_AT_CURSOR =>
                    if cursor > 0 then
                        if cursor < txt.len then
                            tmp_pos := cursor - 1;
                        else
                            tmp_pos := txt.len - 1;
                        end if;
                        for I in 0 to MAX_TEXT_LEN - 2 loop
                            if I < txt.len and I >= tmp_pos then
                                txt.str(I) <= txt.str(I+1);
                            end if;
                        end loop;
                        txt.len <= txt.len - 1;
                        cursor  <= cursor - 1;
                    end if;
                when MOVE_CURSOR =>
                    case keyboard_event.ascii is
                        when 0 =>       -- plus 1
                            if cursor < txt.len then
                                cursor <= cursor + 1;
                            else
                                cursor <= 0;
                            end if;
                        when 1 =>       --minus 1
                            if cursor > 0 then
                                cursor <= cursor - 1;
                            else
                                cursor <= txt.len;
                            end if;
                        when others =>
                            null;
                    end case;
                when others =>
                    null;
            end case;

            finished := '1';
        end if;
    end process;
end architecture;
