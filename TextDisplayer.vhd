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
        cursor        : in 	   CharPos;
        --mouse
        left_button   : in     std_logic;
        right_button  : in     std_logic;
        middle_button : in     std_logic;
        mousex        : in     XCoordinate;
        mousey        : in     YCoordinate;
        error_no_ack  : in     std_logic;
		mouse_pos 	  : out    CharPos;
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
    constant BOUND  : integer := 0;
    signal   button : std_logic;
    signal   clk    : std_logic;

    shared variable current_char_pos, left_char : CharPos;
    signal current_char                         : Char;
    signal U, D, row                            : YCoordinate;
    signal L, R                                 : XCoordinate;
    signal first_char                           : CharPos := 32;

    constant VGA_HEIGHT : integer := 480;
    constant VGA_WIDTH  : integer := 640;

begin
    button       <= not error_no_ack and (left_button or right_button or middle_button);
    clk          <= clk_100;
    current_char <= txt.str(current_char_pos);
    R            <= L + getWidth(current_char);

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
                    elsif y_pos = row then
                        if L /= R and x_pos >= R then
                            L                <= R;
                            current_char_pos := current_char_pos + 1;
                                        --right_char <= current_char_pos;
                        end if;
                    elsif y_pos = row + 1 then
                        row <= y_pos;   --assert y_pos = row + 1
                        L   <= 0;
                        if y_pos < D then
                            current_char_pos := left_char;
                        else            --y_pos >= high new line of chars
                            U                <= D;
                            current_char_pos := current_char_pos + 1;
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
			mouse_pos <= 0;
		elsif clk'event and clk = '1' then
			if pos_x = mousex and pos_y = mousey then
				mouse_pos <= current_char_pos;
			end if;
		end if;
	end process;	

    process(current_char, row, U, y_pos)
    begin
        rom_address <= memAddr(current_char, row-U);
    end process;

    process(x_pos, y_pos, rom_data, L, current_char)
    begin
		if not error_no_ack and x_pos = mousex and y_pos >= mousey-5 and y_pos <= mousey+5 then
			rgb <= COLOR_BLACK;
        elsif y_pos < BOUND then
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
				end if;
			end if;
--        else
--            if rom_data(x_pos mod 16) = '0' then
--                rgb <= COLOR_WHITE;
--            else
--                rgb <= COLOR_GREEN;
--            end if;                   
--        end if;
        elsif x_pos - L < getWidth(current_char) then
            if rom_data(x_pos-L) = '0' then
                rgb <= COLOR_WHITE;
            else
                rgb <= COLOR_GREEN;
            end if;
        else
            rgb <= COLOR_WHITE;
        end if;
    end process;

    process (clk)
    begin
        if clk'event and clk = '1' then
            if U >= D or getWidth(current_char) > D - U then  --width is same as height
                D <= U + getWidth(current_char);
            end if;
        end if;
    end process;

end architecture;  -- arch
