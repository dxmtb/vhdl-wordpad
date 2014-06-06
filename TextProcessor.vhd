library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.GlobalDefines.all;

entity TextProcessor is
    port(
        rst, clk                    : in     std_logic;
        left_button   : in     std_logic;
        right_button  : in     std_logic;
        middle_button : in     std_logic;
        mousex        : in     XCoordinate;
        mousey        : in     YCoordinate;
        error_no_ack  : in     std_logic;
        mouse_pos : in CharPos;
        txt                         : inout    TextArea;
        keyboard_event, mouse_event : inout EventT;
        cursor                      : buffer CharPos
        );
end entity;

architecture structural of TextProcessor is
    signal tmp_char : Char;
    signal button : std_logic;
    signal finished : std_logic := '1';
begin
	button <= not error_no_ack and left_button;
	process(button)
	begin
		if button = '1' then
			if mousey >= BOUND then--click in text area
				if mouse_pos < txt.len then
					cursor <= mouse_pos;
				end if;
			else --click in button area

			end if;
		end if;
	end process;
    process(clk, rst)
    variable tmp_pos : CharPos;
    begin
        if rst = '0' then
            txt.len <= MAX_TEXT_LEN;
            for I in 0 to MAX_TEXT_LEN - 1 loop
                txt.str(I).code  <= I mod 128;
--                                      if I mod 2 = 0 then
                txt.str(I).size  <= BIG;
--                                      else
--                                              txt.str(I).size  <= SMALL;
--                                      end if;
                txt.str(I).color <= COLOR_GREEN;
            end loop;
            finished <= '1';
            tmp_char.size <= BIG;
            tmp_char.font <= FONT1;
            tmp_char.color <= COLOR_GREEN;
        elsif clk'event and clk = '1' and finished = '1' then
            case keyboard_event.e_type is
                when INSERT_CHAR_AT_CURSOR =>
					if cursor < txt.len then
						tmp_pos := cursor;
					else
						tmp_pos := txt.len;
					end if;
                    tmp_char.code <= keyboard_event.args;
                    for I in 1 to MAX_TEXT_LEN - 1 loop
                        if I > tmp_pos then
                            txt.str(I) <= txt.str(I-1);
                        end if;
                    end loop;
                    txt.str(tmp_pos) <= tmp_char;
                when others =>
                    null;
            end case;
        end if;
    end process;
end architecture;
