library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.GlobalDefines.all;

entity TextProcessor is
    port(
        rst, clk                         : in     std_logic;
        txt                         : buffer TextArea;
        keyboard_event, mouse_event : inout  Event;
        cursor                      : buffer     CharPos
        );
end entity;

architecture structural of TextProcessor is
    signal tmp_char : Char;
    signal tmp_pos  : CharPos;
begin
    process(clk, rst)
    begin
        if rst = '0' then
			txt.length <= 0;
        elsif clk'event and clk = '1' then
            case keyboard_event.e_type is
                when INSERT_CHAR_AT_CURSOR =>
                    tmp_pos               <= cursor;
                    tmp_char.code         <= keyboard_event.args;
                    for I in 0 to MAX_TEXT_LEN - 1 loop
                        if I > tmp_pos then
                            txt.str(I+1) <= txt.str(I);
                        end if;
                    end loop;
                    txt.str(tmp_pos) <= tmp_char;
                when others =>
                    null;
            end case;
            keyboard_event.e_type <= NONE;  --mark as done
        end if;
    end process;
end architecture;
