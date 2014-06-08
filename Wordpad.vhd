library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.GlobalDefines.all;

entity Wordpad is
    port (
        Clock100M_FPGAE : in std_logic;  --100MHz
        click           : in std_logic;
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

        seg0, seg1, seg2, seg3, seg4, seg5, seg6, seg_7 : out std_logic_vector(6 downto 0)
        ) ;
end entity;  -- MasterController

architecture arch of Wordpad is
    component KeyScanner is
        port (
            clk     : in    std_logic;  --100MHz
            reset   : in    std_logic;
            PS2clk  : inout std_logic;
            PS2Data : in    std_logic;

            keyClk   : out std_logic;
            ascii    : out std_logic_vector(7 downto 0);
            scancode : out std_logic_vector(7 downto 0)
            );
    end component;
    component txt_ram is
        port
            (
                address_a : in  std_logic_vector (10 downto 0);
                address_b : in  std_logic_vector (10 downto 0);
                clock     : in  std_logic;
                data_a    : in  std_logic_vector (11 downto 0);
                data_b    : in  std_logic_vector (11 downto 0);
                wren_a    : in  std_logic := '1';
                wren_b    : in  std_logic := '1';
                q_a       : out std_logic_vector (11 downto 0);
                q_b       : out std_logic_vector (11 downto 0)
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
    end component;

    component TextDisplayer is
        port (
            clk_100            : in     std_logic;
            reset              : in     std_logic;
            --text information
            ram_address        : out    TxtRamPtr;
            ram_data           : in     std_logic_vector (11 downto 0);
            txt_len            : in     CharPos;
            cursor             : in     CharPos;
            sel_begin, sel_end : in     CharPos;
            processor_status   : in     StatusProcessor;
            first_char         : in     CharPos;
            now_size           : in     CharSizeType;
            now_font           : in     FontType;
            now_color          : in     RGBColor;
            --mouse
            mousex             : in     XCoordinate;
            mousey             : in     YCoordinate;
            error_no_ack       : in     std_logic;
            mouse_pos          : buffer CharPos;
            --display output
            x_pos              : in     XCoordinate;
            y_pos              : in     YCoordinate;
            rgb                : out    RGBColor;
            --rom interaction
            rom_address        : out    CharRomPtr;
            rom_data           : in     std_logic_vector (0 to 15)
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
            code    : in  std_logic_vector(3 downto 0);
            seg_out : out std_logic_vector(6 downto 0)
            );
    end component;

    signal left_button, right_button, middle_button, error_no_ack     : std_logic;
    signal mousex_slv, mousey_slv                                     : std_logic_vector(9 downto 0);
    signal mousex, x_pos                                              : XCoordinate;
    signal mousey, y_pos                                              : YCoordinate;
    signal cursor, mouse_pos, txt_len, first_char, sel_begin, sel_end : CharPos;
    signal rom_address                                                : CharRomPtr;
    signal rom_data                                                   : std_logic_vector(15 downto 0);
    signal rgb                                                        : RGBColor;
    signal keyClk                                                     : std_logic;
    signal ascii_int                                                  : ASCII;
    signal ascii, scancode                                            : std_logic_vector(7 downto 0);

    signal address_a        : std_logic_vector (10 downto 0);
    signal address_b        : std_logic_vector (10 downto 0);
    signal data_a           : std_logic_vector (11 downto 0);
    signal data_b           : std_logic_vector (11 downto 0);
    signal wren_b           : std_logic := '0';
    signal q_a              : std_logic_vector (11 downto 0);
    signal q_b              : std_logic_vector (11 downto 0);
    signal txt_len_slv      : std_logic_vector(7 downto 0);
    signal processor_status : StatusProcessor;
    signal now_size         : CharSizeType;
    signal now_font         : FontType;
    signal now_color        : RGBColor;
begin
--u0: Keyboard port map(PS2_keyboard_Data,PS2_keyboard_clk,Clock100M_FPGAE,reset,scancode);
    u1 : seg7 port map(ascii(3 downto 0), seg0);        --show keyboard
    u2 : seg7 port map(ascii(7 downto 4), seg1);
    u3 : seg7 port map(std_logic_vector(to_unsigned(cursor, 4)), seg2);  --cursor
    u4 : seg7 port map(txt_len_slv(7 downto 4), seg3);  --txt len
    u5 : seg7 port map(txt_len_slv(3 downto 0), seg4);

    seg5(6 downto 2) <= "11111";        --for debug
    seg5(0)          <= keyClk;

    mousex      <= to_integer(unsigned(mousex_slv));
    mousey      <= to_integer(unsigned(mousey_slv));
    ascii_int   <= to_integer(unsigned(ascii));
    txt_len_slv <= std_logic_vector(to_unsigned(txt_len, 8));

    --keyClk <= (not click);

    m1 : KeyScanner port map(
        clk      => Clock100M_FPGAE,
        reset    => click and reset,
        PS2clk   => PS2_keyboard_clk,
        PS2Data  => PS2_keyboard_Data,
        keyClk   => keyClk ,
        ascii    => ascii,
        scancode => scancode
        );

    m2 : ps2_mouse port map(
        clk_in        => Clock100M_FPGAE,
        reset_in      => click and reset,
        ps2_clk       => PS2_mouse_clk,
        ps2_data      => PS2_mouse_Data,
        left_button   => left_button,
        right_button  => right_button,
        middle_button => middle_button,
        mousex        => mousex_slv,
        mousey        => mousey_slv,
        error_no_ack  => error_no_ack);

    m3 : TextProcessor port map(
        clk              => Clock100M_FPGAE,
        rst              => reset,
        left_button      => left_button,
        right_button     => right_button,
        middle_button    => middle_button,
        mousex           => mousex,
        mousey           => mousey,
        error_no_ack     => error_no_ack,
        mouse_pos        => mouse_pos,
        keyClk           => keyClk,
        ascii            => ascii_int,
        sel_begin        => sel_begin,
        sel_end          => sel_end,
        txt_len          => txt_len,
        cursor           => cursor,
        address_b        => address_b,
        data_b           => data_b,
        wren_b           => wren_b,
        q_b              => q_b,
        click            => click,
        processor_status => processor_status,
        first_char       => first_char,
        now_size         => now_size,
        now_font         => now_font,
        now_color        => now_color,
        seg6             => seg6,
        seg_7            => seg_7
        );

    m4 : TextDisplayer port map(
        clk_100          => Clock100M_FPGAE,
        reset            => reset,
        --text information
        ram_address      => address_a,
        ram_data         => q_a,
        txt_len          => txt_len,
        cursor           => cursor,
        sel_begin        => sel_begin,
        sel_end          => sel_end,
        processor_status => processor_status,
        --mouse
        mousex           => mousex,
        mousey           => mousey,
        error_no_ack     => error_no_ack,
        mouse_pos        => mouse_pos,
        --display output
        x_pos            => x_pos,
        y_pos            => y_pos,
        rgb              => rgb,
        --rom interaction
        rom_address      => rom_address,
        rom_data         => rom_data,
        first_char       => first_char,
        now_size         => now_size,
        now_font         => now_font,
        now_color        => now_color
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

    m7 : txt_ram port map(
        address_a => address_a,
        address_b => address_b,
        clock     => Clock100M_FPGAE,
        data_a    => (others => '0'),
        data_b    => data_b,
        wren_a    => '0',
        wren_b    => wren_b,
        q_a       => q_a,
        q_b       => q_b
        );


end architecture;  -- arch
