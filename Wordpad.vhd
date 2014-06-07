library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.GlobalDefines.all;

entity Wordpad is
    port (
        Clock100M_FPGAE : in std_logic;  --100MHz
        click : in std_logic;
        reset           : in std_logic;

        PS2_keyboard_clk  : inout std_logic;
        PS2_keyboard_Data : inout std_logic;

        PS2_mouse_clk  : inout std_logic;
        PS2_mouse_Data : inout std_logic;

        hs : out std_logic;
        vs : out std_logic;

        VGA_B : out std_logic_vector(2 downto 0);
        VGA_G : out std_logic_vector(2 downto 0);
        VGA_R : out std_logic_vector(2 downto 0);
        
        debug :inout std_logic_vector(7 downto 0)
        ) ;
end entity;  -- MasterController

architecture arch of Wordpad is
	component KeyScanner is
		port (
		clk			:	in std_logic;			--100MHz
		reset		:	in std_logic;
		PS2clk		:	inout std_logic;
		PS2Data		:	in std_logic;

		keyClk		:	out	std_logic;
		ascii :  out STD_LOGIC_VECTOR(7 DOWNTO 0);
		scancode : out STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
	end component;
	component KeyboardSimulator is
		port (
			clk  : in  std_logic;
			evt  : buffer EventT
			);
	end component;
    component ps2_mouse is
        port(
            clk_in        : in     std_logic;
            reset_in      : in     std_logic;
            ps2_clk       : inout  std_logic;
            ps2_data      : inout  std_logic;
            left_button   : out    std_logic;
            right_button  : out    std_logic;
            middle_button : out    std_logic;
            mousex        : buffer std_logic_vector(9 downto 0);
            mousey        : buffer std_logic_vector(9 downto 0);
            error_no_ack  : out    std_logic
            );
    end component;
    component TextProcessor is
        port(
        rst, clk                    : in     std_logic;
        --mouse in
        left_button   : in     std_logic;
        right_button  : in     std_logic;
        middle_button : in     std_logic;
        mousex        : in     XCoordinate;
        mousey        : in     YCoordinate;
        error_no_ack  : in     std_logic;
        mouse_pos : 	in CharPos;
        --keyboard in
		keyClk		:	in	std_logic;
		ascii		:	in ASCII;
        --vga in
        x_pos         : in     XCoordinate;
        y_pos         : in     YCoordinate;
        sel_begin, sel_end : buffer CharPos;
        sel_mode : 			buffer SelMode;
        txt                         : buffer TextArea;
        cursor                      : buffer CharPos
            );
    end component;

    component TextDisplayer is
        port (
        clk_100       : in     std_logic;
        reset         : in     std_logic;
        --text information
        txt           : in     TextArea;
        cursor        : in     CharPos;
        sel_begin, sel_end : in CharPos;
        sel_mode : in SelMode;
        --mouse
        mousex        : in     XCoordinate;
        mousey        : in     YCoordinate;
        error_no_ack  : in     std_logic;
        mouse_pos 	:   buffer    CharPos;

        --display output
        x_pos         : in     XCoordinate;
        y_pos         : in     YCoordinate;
        rgb           : out    RGBColor;
        --rom interaction
        rom_address   : out    CharRomPtr;
        rom_data      : in     std_logic_vector (0 to 15)
            );
    end component;

    component VGADisplayer is
        port(
            reset   : in  std_logic;
            clk25   : out std_logic;
            rgb     : in  RGBColor;
            clk_0   : in  std_logic;
            hs, vs  : out std_logic;
            r, g, b : out std_logic_vector(2 downto 0);
            x_pos   : out XCoordinate;
            y_pos   : out YCoordinate
            );
    end component;

    component char_rom is
        port
            (
                address : in  CharRomPtr;
                clock   : in  std_logic;
                q       : out std_logic_vector (15 downto 0)
                );
    end component;
    
    component seg7 is
port(
code: in std_logic_vector(3 downto 0);
seg_out : out std_logic_vector(6 downto 0)
);
end component;

    component Keyboard is
port (
	datain, clkin : in std_logic ; -- PS2 clk and data
	fclk, rst : in std_logic ;  -- filter clock
	fok : buffer std_logic ;  -- data output enable signal
	scancode : out std_logic_vector(7 downto 0) -- scan code signal output
	) ;
end component ;

    signal keyboard_event, mouse_event                            : EventT;
    signal left_button, right_button, middle_button, error_no_ack : std_logic;
    signal mousex_slv, mousey_slv                                 : std_logic_vector(9 downto 0);
    signal mousex, x_pos                                          : XCoordinate;
    signal mousey, y_pos                                          : YCoordinate;
    signal txt                                                    : TextArea;
    signal cursor, mouse_pos                                                 : CharPos;
    signal rom_address                                            : CharRomPtr;
    signal rom_data                                               : std_logic_vector(15 downto 0);
    signal rgb                                                    : RGBColor;
    signal keyClk : std_logic;
    signal ascii_int : ASCII;
    signal ascii, scancode : STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal sel_begin, sel_end : CharPos;
	signal sel_mode :  SelMode;

begin

    mousex <= to_integer(unsigned(mousex_slv));
    mousey <= to_integer(unsigned(mousey_slv));
    ascii_int <= to_integer(unsigned(ascii));
    debug <= scancode;
    m1 : KeyScanner port map(
        	clk	=> Clock100M_FPGAE,
			reset => reset,
			PS2clk	=> PS2_keyboard_clk,
			PS2Data	=> PS2_keyboard_Data,
			keyClk => keyClk,
			ascii => ascii,
			scancode => scancode
			);

--    m1 : KeyboardSimulator port map(
--        clk  => click,
--        evt  => keyboard_event);

    m2 : ps2_mouse port map(
        clk_in        => Clock100M_FPGAE,
        reset_in      => reset,
        ps2_clk       => PS2_mouse_clk,
        ps2_data      => PS2_mouse_Data,
        left_button   => left_button,
        right_button  => right_button,
        middle_button => middle_button,
        mousex        => mousex_slv,
        mousey        => mousey_slv,
        error_no_ack  => error_no_ack);

    m3 : TextProcessor port map(
        clk            => Clock100M_FPGAE,
        rst            => reset,
        left_button   => left_button,
        right_button  => right_button,
        middle_button => middle_button,
        mousex        => mousex,
        mousey        => mousey,
        error_no_ack  => error_no_ack,
        mouse_pos => mouse_pos,
		keyClk	=> keyClk,
		ascii => ascii_int,
        x_pos         => x_pos,
        y_pos         => y_pos,
        sel_begin => sel_begin,
		sel_end => sel_end,
        sel_mode => sel_mode,
        txt            => txt,
        cursor         => cursor
        );

    m4 : TextDisplayer port map(
        clk_100       => Clock100M_FPGAE,
        reset         => reset,
        --text information
        txt           => txt,
        cursor        => cursor,
        sel_begin => sel_begin,
		sel_end => sel_end,
        sel_mode => sel_mode,
        --mouse
        mousex        => mousex,
        mousey        => mousey,
        error_no_ack  => error_no_ack,
        mouse_pos => mouse_pos,
        --display output
        x_pos         => x_pos,
        y_pos         => y_pos,
        rgb           => rgb,
        --rom interaction
        rom_address   => rom_address,
        rom_data      => rom_data
        );

    m5 : VGADisplayer port map(
        reset => reset,
        clk25 => open,
        rgb   => rgb,
        clk_0 => Clock100M_FPGAE,
        hs    => hs,
        vs    => vs,
        r     => VGA_R,
        g     => VGA_G,
        b     => VGA_B,
        x_pos => x_pos,
        y_pos => y_pos
        );

    m6 : char_rom port map (
        address => rom_address,
        q       => rom_data,
        clock   => Clock100M_FPGAE
        );


end architecture;  -- arch
