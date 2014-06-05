library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.GlobalDefines.all;

entity Wordpad is
    port (
        Clock100M_FPGAE : in std_logic;  --100MHz
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

        debug0 : out CharCode;
        error : out std_logic
        ) ;
end entity;  -- MasterController

architecture arch of Wordpad is
    component KeyboardListener is
        port(
            clk  : inout  std_logic;
            data : inout  std_logic;
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
            txt                         : out TextArea;
            keyboard_event, mouse_event : buffer EventT;
            cursor                      : buffer CharPos
            );
    end component;

    component TextDisplayer is
        port (
            clk_100       : in     std_logic;
            reset         : in     std_logic;
            --text information
            txt           : in TextArea;
            cursor        : buffer CharPos;
            --mouse
            left_button   : in     std_logic;
            right_button  : in     std_logic;
            middle_button : in     std_logic;
            mousex        : in     XCoordinate;
            mousey        : in     YCoordinate;
            error_no_ack  : in     std_logic;
            --display output
            x_pos         : in     XCoordinate;
            y_pos         : in     YCoordinate;
            rgb           : out    RGBColor;
            --rom interaction
            rom_address   : out    CharRomPtr;
            rom_data      : in     std_logic_vector (15 downto 0)
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

    signal keyboard_event, mouse_event                            : EventT;
    signal left_button, right_button, middle_button, error_no_ack : std_logic;
    signal mousex_slv, mousey_slv                                 : std_logic_vector(9 downto 0);
    signal mousex, x_pos                                          : XCoordinate;
    signal mousey, y_pos                                          : YCoordinate;
    signal txt                                                    : TextArea;
    signal cursor                                                 : CharPos;
    signal rom_address                                            : CharRomPtr;
    signal rom_data                                               : std_logic_vector(15 downto 0);
    signal rgb                                                    : RGBColor;

begin
	error <= '1';
    mousex <= to_integer(unsigned(mousex_slv));
    mousey <= to_integer(unsigned(mousey_slv));
    m1 : KeyboardListener port map(
        clk  => PS2_keyboard_clk,
        data => PS2_keyboard_Data,
        evt  => keyboard_event);

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
        txt            => txt,
        keyboard_event => keyboard_event,
        mouse_event    => mouse_event,
        cursor         => cursor
        );

    m4 : TextDisplayer port map(
        clk_100       => Clock100M_FPGAE,
        reset         => reset,
        --text information
        txt           => txt,
        cursor        => cursor,
        --mouse
        left_button   => left_button,
        right_button  => right_button,
        middle_button => middle_button,
        mousex        => mousex,
        mousey        => mousey,
        error_no_ack  => error_no_ack,
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
