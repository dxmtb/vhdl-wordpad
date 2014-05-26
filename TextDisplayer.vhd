library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TextDisplayer is
    port (
        clk_100       : in     std_logic;
        reset           : in     std_logic;
        --text information
        txt          : buffer TextArea;
        --mouse
        left_button   : in     std_logic;
        right_button  : in     std_logic;
        middle_button : in     std_logic;
        mousex        : in std_logic_vector(9 downto 0);
        mousey        : in std_logic_vector(8 downto 0);
        error_no_ack  : in     std_logic;
        --display output
        x_pos       :           in std_logic_vector(9 downto 0);		--X坐标
        y_pos       : in std_logic_vector(8 downto 0);		--Y坐标
        rgb : out RGBColor;
    --rom interaction
        address : out std_logic_vector(15 downto 0);
        bitmap : in std_logic_vector(63 downto 0);
);
end entity;  -- TextDisplayer

architecture arch of TextDisplayer is
    type State is (output, waiting);
    signal state : State;
    constant BOUNDARY: Integer := 100;
    signal button : std_logic;

    variable current_char, leftChar: CharPos;
    variable low, high : std_logic_vector(8 downto 0);
    variable left, right : std_logic_vector(9 downto 0);
    signal col_mod : integer;
    signal rgb_4bit : std_logic_vector(3 downto 0);
    variable keep_char : std_logic;

begin
    button <= left_button or right_button or middle_button;
    rgb <= rgb_4bit(3 downto 1);
    col_mod <= x_pos mod 22;
    process(clk_100,reset)
    begin
        if reset='0' then
            current_char <= (others => '1');
            line_begin <= (others => '0');
            low <= (others => '0');
            high <= (others => '0');
            left <= (others => '0');
            right <= (others => '0');
        elsif clk'event and clk='1' then
            if y_pos = row then
                if left <= x_pos and x_pos < right then
                    rgb_4bit <= bitmap((x_pos-left)*4 to (x_pos-left+1)*4);
                else
                    current_char <= current_char + 1;
                    if left + SizeToPixel(txt(current_char).size) >= 640 then
                        current_char = leftChar;
                        right <= 800;
                    end if;
                    if getWidth(txt, current_char) > high - low then
                        high <= low + getWidth(txt, current_char);
                    end if;
                end if;
            else
                row <= y_pos; --assert y_pos = row + 1
                left <= 0;
                right <= 0;

                if y_pos < high then
                    current_char <= leftChar - 1;
                else --y_pos >= high new line of chars
                    low <= high;
                    high <= high;
                    current_char <= current_char + 1;
                end if;
            end if;
        end if;
    end process;

    process(current_char)
    begin
        address <= memAddr(txt.str(current_char), row_mod);
    end process;

end architecture;  -- arch
