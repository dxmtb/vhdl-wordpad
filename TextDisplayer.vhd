library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.GlobalDefines.all;

entity TextDisplayer is
    port (
        clk_100       : in     std_logic;
        reset         : in     std_logic;
        --text information
        txt           : in     TextArea;
        cursor        : in     CharPos;
        --mouse
        left_button   : in     std_logic;
        right_button  : in     std_logic;
        middle_button : in     std_logic;
        mousex        : in     XCoordinate;
        mousey        : in     YCoordinate;
        error_no_ack  : in     std_logic;
        mouse_pos 	:   out    CharPos;
        --display output
        x_pos         : in     XCoordinate;
        y_pos         : in     YCoordinate;
        rgb           : out    RGBColor;
        --rom interaction
        rom_address   : out    CharRomPtr;
        rom_data      : in     std_logic_vector (0 to 15)
        );
end entity;  -- TextDisplayer

architecture arch of TextDisplayer is
    signal   button : std_logic;
    signal   clk    : std_logic;

    shared variable current_char_pos, left_char : CharPos;
    signal current_char                         : Char;
    signal U, D, row                            : YCoordinate;
    signal L, R                                 : XCoordinate;
    signal first_char                           : CharPos := 0;
    signal flash_counter : integer range 0 to 127;
    signal show_cursor : std_logic;
    signal sel_begin, sel_end : CharPos := 0;
    signal my_mouse_pos : CharPos;

    type SelMode is (NO, BEGIN_SEL, END_SEL);
    signal sel_mode : SelMode := NO;

    constant VGA_HEIGHT : integer := 480;
    constant VGA_WIDTH  : integer := 640;

begin
    button       <= not error_no_ack and right_button;
    clk          <= clk_100;
    current_char <= txt.str(current_char_pos);
    R            <= L + getWidth(current_char);
    D <= U + 16;
    rom_address <= memAddr(current_char, row-U);
    show_cursor <= '1' when flash_counter < 64 else '0';
    mouse_pos <= my_mouse_pos;

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
                        flash_counter <= flash_counter + 1;
                    elsif y_pos = row then
                        if L /= R and x_pos >= R then
                            L                <= R;
                            if current_char_pos < txt.len then
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
                            U                <= D;
                            if current_char_pos < txt.len then
								current_char_pos := current_char_pos + 1;
							end if;
                            left_char        := current_char_pos;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

	process(clk, reset)
	begin
		if reset = '0' then
			my_mouse_pos <= 0;
		elsif clk'event and clk = '1' then
			if x_pos = mousex and y_pos = mousey and current_char_pos /= txt.len then
				my_mouse_pos <= current_char_pos;
			end if;
		end if;
	end process;

	process(button)
	begin
		if button'event and button = '1' and mousey >= BOUND and my_mouse_pos < txt.len then
			case sel_mode is
			when NO =>
				sel_begin <= my_mouse_pos;
				sel_end <= my_mouse_pos;
				sel_mode <= BEGIN_SEL;
			when END_SEL =>
				sel_mode <= NO;
			when BEGIN_SEL =>
				sel_end <= my_mouse_pos;
				sel_mode <= END_SEL;
			end case;
		end if;
	end process;

    process(x_pos, y_pos, rom_data, L, current_char)
    begin
		if error_no_ack = '0' and ((x_pos = mousex and y_pos >= mousey-5 and y_pos <= mousey+5) or
				(y_pos = mousey-5 and x_pos >= mousex - 1 and x_pos <= mousex + 1) or
				(y_pos = mousey+5 and x_pos >= mousex - 1 and x_pos <= mousex + 1)) then --draw mouse
			rgb <= COLOR_BLACK;
        elsif y_pos < BOUND then --draw buttons
            rgb <= COLOR_BLUE;
			if y_pos >= 10 and y_pos < 45 then
				--Font and Size
				if x_pos >= 10 and x_pos < 60 then
					rgb <= COLOR_RED;
				elsif x_pos >= 80 and x_pos < 130 then
					rgb <= COLOR_RED;
				elsif x_pos >= 150 and x_pos < 200 then
					rgb <= COLOR_RED;
				elsif x_pos >= 220 and x_pos < 270 then
					rgb <= COLOR_RED;
				end if;
			elsif y_pos >= 55 and y_pos < 90 then
				if x_pos >= 10 and x_pos < 60 then
					rgb <= COLOR_BLACK;
				elsif x_pos >= 80 and x_pos < 130 then
					rgb <= COLOR_BLUE;
				elsif x_pos >= 400 and x_pos < 445 then
					case sel_mode is
					when NO =>
						rgb <= COLOR_CYAN;
					when BEGIN_SEL =>
						rgb <= COLOR_RED;
					when END_SEL =>
						rgb <= COLOR_PURPLE;
					end case;
				end if;
			end if;
        elsif show_cursor = '1' and current_char_pos = cursor and (x_pos = L or x_pos = L + 1) then --draw cursor
			rgb <= COLOR_BLACK;
		elsif current_char_pos < txt.len and x_pos - L < getWidth(current_char) then --draw char
            if rom_data(x_pos-L) = '0' then
                if sel_mode = END_SEL and sel_begin /= sel_end and current_char_pos >= sel_begin and current_char_pos <= sel_end then
					rgb <= COLOR_BLACK;
				else
					rgb <= COLOR_WHITE;
				end if;
            else
                rgb <= COLOR_GREEN;
            end if;
        else
            rgb <= COLOR_WHITE;
        end if;
    end process;

end architecture;  -- arch
