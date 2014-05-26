library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.GlobalDefines.all;
-------------------------------------------------------------------------------------
entity Controller is
	port (
            rst, clk            : in     std_logic;
            txt           : buffer TextArea;
            keyboard_event, mouse_event : inout  Event
	);
end entity;

architecture structural of Controller is
    signal tmp_char : Char;
    signal tmp_pos : CharPos;
begin
    process(clk,rst)	--行区间像素数（含消隐区）
    begin
        if rst='0' then
        elsif clk'event and clk='1' then
            if keyboard_event.e_type \= NONE then
                tmp_pos <= keyboard_event.args(31 downto 16);
                tmp_char.code <= keyboard_event.args(7 downto 0);
                keyboard_event.e_type <= NONE;
                for I in 0 to MAX_TEXT_LEN - 1 loop
                    if I > tmp_pos then
                        txt.str(I+1) <= txt.str(I);
                    end if;
                end loop;
                txt.str(I) <= tmp_char;
            end if;
        end if;
    end process;
end architecture;
