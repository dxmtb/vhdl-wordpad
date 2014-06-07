library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.GlobalDefines.all;

entity TextProcessor is
    port(
        rst, clk           : in     std_logic;
        click 			   : in std_logic; --for reset mode
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
        txt_len                : buffer CharPos := 0;
        cursor             : buffer CharPos := 0;
        --ram
		address_b		: buffer TxtRamPtr;
		data_b		: out STD_LOGIC_VECTOR (15 DOWNTO 0);
		wren_b		: buffer STD_LOGIC  := '0';
		q_b		: in STD_LOGIC_VECTOR (15 DOWNTO 0)        
        );
end entity;

architecture structural of TextProcessor is
    signal format_char        : Char;
    shared variable tmp_char : Char;
    signal lbutton, rbutton  : std_logic;
    signal keyboard_event, mouse_event    : EventT;
    signal rbutton_before    : std_logic := '0';
    signal flag_sel          : boolean;
    signal key_clk_before    : std_logic := '0';
    --signal tmp_char_slv : std_logic_vector(15 downto 0);
    
    type StatusProcessor is (Waiting, Waiting2, Insert, Del, Reset, SetFont, SetFontEnter);
    signal step : CharPos;
    signal status : StatusProcessor;
    signal tmp_pos : CharPos;
begin
    lbutton  <= not error_no_ack and left_button;
    rbutton  <= not error_no_ack and right_button;
    flag_sel <= sel_begin < sel_end;
    

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
    begin
        if rst = '0' then
            if click = '1' then
				txt_len <= 0;
			else
				status <= Reset;
				step <= 0;
				txt_len <= MAX_TEXT_LEN/2;
			end if;
            format_char.size  <= BIG;
            format_char.font  <= FONT1;
            format_char.color <= COLOR_GREEN;
        elsif clk'event and clk = '1' then
			case status is
			when Waiting =>
				status <= Waiting2;
				if lbutton = '1' then
					if mousey >= BOUND then  --click in text area
						if mouse_pos < txt_len then
							cursor <= mouse_pos;
						end if;
					else                     --click in button area
						if y_pos >= Button_Font_Size_Y_START and y_pos < Button_Font_Size_Y_END then
											 --Font and Size
							if x_pos >= Button_Small_X_Start and x_pos < Button_Small_X_End then
								if flag_sel then
									mouse_event.format_type <= 0;
									mouse_event.format <= 0;
									status <= SetFontEnter;
								end if;
								format_char.size <= SMALL;
							elsif x_pos >= Button_Big_X_Start and x_pos < Button_Big_X_End then
								if flag_sel then
									mouse_event.format_type <= 0;
									mouse_event.format <= 1;
									status <= SetFontEnter;
								end if;
								format_char.size <= BIG;
							elsif x_pos >= Button_Font1_X_Start and x_pos < Button_Font1_X_End then
								if flag_sel then
									mouse_event.format_type <= 1;
									mouse_event.format <= 0;
									status <= SetFontEnter;
								end if;
								format_char.font <= FONT1;
							elsif x_pos >= Button_Font2_X_Start and x_pos < Button_Font2_X_End then
								if flag_sel then
									mouse_event.format_type <= 1;
									mouse_event.format <= 1;
									status <= SetFontEnter;
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
										mouse_event.format_type <= 2;
										mouse_event.format <= I;
										status <= SetFontEnter;				
									end if;
								end if;
							end loop;
						end if;
					end if;
				end if;	
			when Waiting2 =>
				status <= Waiting;
				case keyboard_event.e_type is
					when INSERT_CHAR_AT_CURSOR =>
						txt_len               <= txt_len + 1;
						cursor                <= cursor + 1;
						tmp_char := format_char;
						tmp_char.code := keyboard_event.ascii;
						if cursor < txt_len then
							status <= Insert;
							step <= txt_len - 1; --read step write to step+1 dec
							tmp_pos <= cursor;
							wren_b <= '0';
							address_b <= std_logic_vector(to_unsigned(txt_len - 1, TxtRamPtr'length));
						else
							wren_b <= '1';
							address_b <= std_logic_vector(to_unsigned(txt_len, TxtRamPtr'length));
							data_b <= char2raw(tmp_char);
						end if;
					when DELETE_AT_CURSOR =>
						if cursor > 0 then
							if cursor < txt_len then
								step <= cursor - 1; --read step+1 write to step inc
								status <= Del;
								wren_b <= '0';
								address_b <= std_logic_vector(to_unsigned(cursor, TxtRamPtr'length));
							end if;
							txt_len <= txt_len - 1;
							cursor  <= cursor - 1;
						end if;
					when MOVE_CURSOR =>
						case keyboard_event.ascii is
							when 0 =>       -- plus 1
								if cursor < txt_len then
									cursor <= cursor + 1;
								else
									cursor <= 0;
								end if;
							when 1 =>       --minus 1
								if cursor > 0 then
									cursor <= cursor - 1;
								else
									cursor <= txt_len;
								end if;
							when others =>
								null;
						end case;
					when others =>
						null;
				end case;
			when Reset =>
				if step = txt_len then
					wren_b <= '0';
					status <= Waiting;
				else
					tmp_char.code := (step+MAX_TEXT_LEN/2) mod 128;
					tmp_char.size  := BIG;
					tmp_char.font := FONT1;
					tmp_char.color := COLOR_GREEN;
					wren_b <= '1';
					data_b <= char2raw(tmp_char);
					address_b <= std_logic_vector(to_unsigned(step, TxtRamPtr'length));
					step <= step + 1;
				end if;
			when Insert =>
				if step = tmp_pos - 1 then
					wren_b <= '1';
					data_b <= char2raw(tmp_char);
					address_b <= std_logic_vector(to_unsigned(tmp_pos, TxtRamPtr'length));
					status <= Waiting;
				else
					if wren_b = '1' or to_integer(unsigned(address_b)) /= step then
						wren_b <= '0';
						address_b <= std_logic_vector(to_unsigned(step, TxtRamPtr'length));
					else
						wren_b <= '1';
						address_b <= std_logic_vector(to_unsigned(step+1, TxtRamPtr'length));
						data_b <= q_b;
						step <= step - 1;
					end if;
				end if;				
			when Del =>
				if step = txt_len then
					wren_b <= '0';
					status <= Waiting;
				else
					if wren_b = '1' or to_integer(unsigned(address_b)) /= step+1 then
						wren_b <= '0';
						address_b <= std_logic_vector(to_unsigned(step+1, TxtRamPtr'length));
					else
						wren_b <= '1';
						address_b <= std_logic_vector(to_unsigned(step, TxtRamPtr'length));
						data_b <= q_b;
						step <= step + 1;
					end if;
				end if;	
			when SetFontEnter =>
				wren_b <= '0';
				address_b <= std_logic_vector(to_unsigned(sel_begin, TxtRamPtr'length));
				step <= sel_begin;							
			when SetFont =>
				if step >= sel_end or step >= txt_len then
					wren_b <= '0';
					status <= Waiting;
				else
					if wren_b = '1' or to_integer(unsigned(address_b)) /= step then
						wren_b <= '0';
						address_b <= std_logic_vector(to_unsigned(step, TxtRamPtr'length));
					else
						tmp_char := raw2char(q_b);
						  case mouse_event.format_type is
						  when 0 =>
								  if mouse_event.format = 0 then
										  tmp_char.size := SMALL;
								  elsif mouse_event.format = 1 then
										  tmp_char.size := BIG;
								  end if;
						  when 1 =>
								  if mouse_event.format = 0 then
										  tmp_char.font := FONT1;
								  elsif mouse_event.format = 1 then
										  tmp_char.font := FONT2;
								  end if;
						  when 2 =>
								  tmp_char.color := ALL_COLOR(mouse_event.format);
						  when others =>
								  null;
						  end case;
						wren_b <= '1';
						data_b <= char2raw(tmp_char);
						address_b <= std_logic_vector(to_unsigned(step, TxtRamPtr'length));
						step <= step + 1;
					end if;
				end if;
			end case;
        end if;
    end process;
end architecture;
