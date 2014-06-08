library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.GlobalDefines.all;

entity TextProcessor is
    port(
        rst, clk           : in     std_logic;
        click              : in     std_logic;  --for reset mode
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
        --txt status
        sel_begin, sel_end : buffer CharPos   := 0;
        txt_len            : buffer CharPos   := 0;
        cursor             : buffer CharPos   := 0;
        first_char         : buffer CharPos   := 0;
        processor_status   : out    StatusProcessor;
        now_size           : buffer CharSizeType;
        now_font           : buffer FontType;
        now_color          : buffer RGBColor;
        --ram
        address_b          : buffer TxtRamPtr;
        data_b             : out    std_logic_vector (11 downto 0);
        wren_b             : buffer std_logic := '0';
        q_b                : in     std_logic_vector (11 downto 0);
        seg6, seg_7        : out    std_logic_vector(6 downto 0)
        );
end entity;

architecture structural of TextProcessor is
    component seg7 is
        port(
            code    : in  std_logic_vector(3 downto 0);
            seg_out : out std_logic_vector(6 downto 0)
            );
    end component;
    shared variable tmp_char           : Char;
    signal lbutton, rbutton            : std_logic;
    signal keyboard_event, mouse_event : EventT;
    signal rbutton_before              : std_logic := '0';
    signal flag_sel                    : boolean;
    signal key_clk_before              : std_logic := '0';
    --signal tmp_char_slv : std_logic_vector(15 downto 0);

    signal step, step_plus, step_minus : CharPos;
    signal status                      : StatusProcessor;
    signal tmp_pos                     : CharPos;
    signal hold                        : integer := 0;
begin
    lbutton          <= not error_no_ack and left_button;
    rbutton          <= not error_no_ack and right_button;
    flag_sel         <= (sel_begin < sel_end);
    processor_status <= status;
    step_plus        <= step + 1;
    step_minus       <= step - 1;
    u6 : seg7 port map(q_b(3 downto 0), seg6);
    u7 : seg7 port map(address_b(3 downto 0), seg_7);

    process(clk, rst)
    begin
        if rst = '0' then
            if click = '1' then
                txt_len <= 0;
                status  <= Waiting;
            else
                status  <= ResetStatus;
                step    <= 0;
                txt_len <= 100;
            end if;
            now_size   <= BIG;
            now_font   <= FONT1;
            now_color  <= COLOR_GREEN;
            cursor     <= 0;
            first_char <= 0;
            wren_b     <= '0';
        elsif clk'event and clk = '1' then
            if hold /= 0 then
                hold <= hold - 1;
            else
                case status is
                    when Waiting =>

                        status <= Waiting2;
                        wren_b <= '0';
                        if lbutton = '1' then
                            if mousey >= BOUND then  --click in text area
                                if mouse_pos < txt_len then
                                    cursor <= mouse_pos;
                                end if;
                            else        --click in button area
                                if mousey >= Button_Font_Size_Y_START and mousey < Button_Font_Size_Y_END then
                                        --Font and Size
                                    if mousex >= Button_Small_X_Start and mousex < Button_Small_X_End then
                                        if flag_sel then
                                            mouse_event.format_type <= 0;
                                            mouse_event.format      <= 0;
                                            status                  <= SetFontEnter;
                                        end if;
                                        now_size <= SMALL;
                                    elsif mousex >= Button_Big_X_Start and mousex < Button_Big_X_End then
                                        if flag_sel then
                                            mouse_event.format_type <= 0;
                                            mouse_event.format      <= 1;
                                            status                  <= SetFontEnter;
                                        end if;
                                        now_size <= BIG;
                                    elsif mousex >= Button_Font1_X_Start and mousex < Button_Font1_X_End then
                                        if flag_sel then
                                            mouse_event.format_type <= 1;
                                            mouse_event.format      <= 0;
                                            status                  <= SetFontEnter;
                                        end if;
                                        now_font <= FONT1;
                                    elsif mousex >= Button_Font2_X_Start and mousex < Button_Font2_X_End then
                                        if flag_sel then
                                            mouse_event.format_type <= 1;
                                            mouse_event.format      <= 1;
                                            status                  <= SetFontEnter;
                                        end if;
                                        now_font <= FONT2;
                                    end if;
                                elsif mousey >= Button_Color_Y_START and mousey < Button_Color_Y_END then
                                    for I in 0 to ALL_COLOR'length - 1 loop
                                        if mousex >= Button_Color_X_Start + I * (Button_Color_X_Width+Button_Color_X_Dis) and
                                            mousex < Button_Color_X_Start +
                                            I * (Button_Color_X_Width+Button_Color_X_Dis) + Button_Color_X_Width then
                                            now_color <= ALL_COLOR(I);
                                            if flag_sel then
                                                mouse_event.format_type <= 2;
                                                mouse_event.format      <= I;
                                                status                  <= SetFontEnter;
                                            end if;
                                        end if;
                                    end loop;
                                end if;
                            end if;
                        end if;
                    when Waiting2 =>
                        status <= Waiting;
                        wren_b <= '0';
                        case keyboard_event.e_type is
                            when INSERT_CHAR_AT_CURSOR =>
                                txt_len        <= txt_len + 1;
                                cursor         <= cursor + 1;
                                tmp_char.code  := keyboard_event.ascii;
                                tmp_char.font  := now_font;
                                tmp_char.size  := now_size;
                                tmp_char.color := now_color;
                                if cursor < txt_len then
                                    status    <= Insert;
                                    step      <= txt_len - 1;  --read step write to step+1 dec
                                    tmp_pos   <= cursor;
                                    wren_b    <= '0';
                                    address_b <= std_logic_vector(to_unsigned(txt_len - 1, TxtRamPtr'length));
                                    hold      <= HOLD_TIME;
                                else
                                    wren_b    <= '1';
                                    address_b <= std_logic_vector(to_unsigned(txt_len, TxtRamPtr'length));
                                    data_b    <= char2raw(tmp_char);
                                    hold      <= HOLD_TIME;
                                end if;
                            when DELETE_AT_CURSOR =>
                                if cursor > 0 then
                                    if cursor < txt_len then
                                        step      <= cursor - 1;  --read step+1 write to step inc
                                        status    <= Del;
                                        wren_b    <= '0';
                                        address_b <= std_logic_vector(to_unsigned(cursor, TxtRamPtr'length));
                                        hold      <= HOLD_TIME;
                                    end if;
                                    txt_len <= txt_len - 1;
                                    cursor  <= cursor - 1;
                                end if;
                            when MOVE_CURSOR =>
                                case keyboard_event.ascii is
                                    when 0 =>        -- plus 1
                                        if cursor < txt_len then
                                            cursor <= cursor + 1;
                                        else
                                            cursor <= 0;
                                        end if;
                                    when 1 =>        --minus 1
                                        if cursor > 0 then
                                            cursor <= cursor - 1;
                                        else
                                            cursor <= txt_len;
                                        end if;
                                    when others =>
                                        null;
                                end case;
                            when MOVE_FIRST =>
                                case keyboard_event.ascii is
                                    when 0 =>        -- plus 1
                                        if first_char + 30 < txt_len then
                                            first_char <= first_char + 30;
                                        else
                                            first_char <= txt_len;
                                        end if;
                                    when 1 =>        --minus 1
                                        if first_char - 30 > 0 then
                                            first_char <= first_char - 30;
                                        else
                                            first_char <= 0;
                                        end if;
                                    when others =>
                                        null;
                                end case;
                            when others =>
                                null;
                        end case;
                    when ResetStatus =>
                        if step >= txt_len then
                            wren_b <= '0';
                            status <= Waiting;
                        else
                            tmp_char.code  := (step+32) mod 128;
                            tmp_char.size  := BIG;
                            tmp_char.font  := FONT1;
                            tmp_char.color := COLOR_GREEN;
                            wren_b         <= '1';
                            data_b         <= char2raw(tmp_char);
                            address_b      <= std_logic_vector(to_unsigned(step, TxtRamPtr'length));
                            step           <= step + 1;
                            hold           <= HOLD_TIME;
                        end if;
                    when Insert =>
                        if step = tmp_pos - 1 then
                            wren_b    <= '1';
                            data_b    <= char2raw(tmp_char);
                            address_b <= std_logic_vector(to_unsigned(tmp_pos, TxtRamPtr'length));
                            hold      <= HOLD_TIME;
                            status    <= Waiting;
                        else
                            if wren_b = '1' then
                                wren_b    <= '0';
                                address_b <= std_logic_vector(to_unsigned(step, TxtRamPtr'length));
                                hold      <= HOLD_TIME;
                            else
                                wren_b    <= '1';
                                data_b    <= q_b;
                                address_b <= std_logic_vector(to_unsigned(step_plus, TxtRamPtr'length));
                                hold      <= HOLD_TIME;
                                step      <= step_minus;
                            end if;
                        end if;
                    when Del =>
                        if step = txt_len then
                            wren_b <= '0';
                            status <= Waiting;
                        else
                            if wren_b = '1' or to_integer(unsigned(address_b)) /= step+1 then
                                wren_b    <= '0';
                                address_b <= std_logic_vector(to_unsigned(step_plus, TxtRamPtr'length));
                                hold      <= HOLD_TIME;
                            else
                                wren_b    <= '1';
                                address_b <= std_logic_vector(to_unsigned(step, TxtRamPtr'length));
                                data_b    <= q_b;
                                step      <= step + 1;
                                hold      <= HOLD_TIME;
                            end if;
                        end if;
                    when SetFontEnter =>
                        wren_b    <= '0';
                        address_b <= std_logic_vector(to_unsigned(sel_begin, TxtRamPtr'length));
                        step      <= sel_begin;
                        status    <= SetFont;
                        hold      <= HOLD_TIME;
                    when SetFont =>
                        if step >= sel_end or step >= txt_len then
                            wren_b <= '0';
                            status <= Waiting;
                        else
                            if wren_b = '1' then
                                wren_b    <= '0';
                                address_b <= std_logic_vector(to_unsigned(step, TxtRamPtr'length));
                                hold      <= HOLD_TIME;
                            else
                                data_b(6 downto 0) <= q_b(6 downto 0);
                                if mouse_event.format_type = 0 then
                                    if mouse_event.format = 0 then
                                        data_b(7) <= '0';
                                    elsif mouse_event.format = 1 then
                                        data_b(7) <= '1';
                                    end if;
                                else
                                    data_b(7) <= q_b(7);
                                end if;
                                if mouse_event.format_type = 1 then
                                    if mouse_event.format = 0 then
                                        data_b(8) <= '0';
                                    elsif mouse_event.format = 1 then
                                        data_b(8) <= '1';
                                    end if;
                                else
                                    data_b(8) <= q_b(8);
                                end if;
                                if mouse_event.format_type = 2 then
                                    data_b(9)  <= now_color(Blue);
                                    data_b(10) <= now_color(Green);
                                    data_b(11) <= now_color(Red);
                                else
                                    data_b(11 downto 9) <= q_b(11 downto 9);
                                end if;

                                wren_b    <= '1';
                                address_b <= std_logic_vector(to_unsigned(step, TxtRamPtr'length));
                                step      <= step + 1;
                                hold      <= HOLD_TIME;
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process;

    process(clk, rst)
    begin
        if rst = '0' then
            sel_begin <= 0;
            sel_end   <= 0;
        elsif clk'event and clk = '1' and mousey >= BOUND and mouse_pos < txt_len then
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
            elsif rbutton = '0' and lbutton = '1' then
                sel_end   <= 0;
                sel_begin <= 0;
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
                    when 91 =>
                        keyboard_event.e_type <= MOVE_FIRST;  --[ for move first
                        keyboard_event.ascii  <= 1;
                    when 93 =>
                        keyboard_event.e_type <= MOVE_FIRST;  --] for move first
                        keyboard_event.ascii  <= 0;
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

end architecture;
