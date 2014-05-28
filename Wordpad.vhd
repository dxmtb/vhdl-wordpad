library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.GlobalDefines.all;

entity MasterController is
    port (
        Clock100M_FPGAE : in std_logic;  --100MHz
        reset           : in std_logic;

        PS2_keyboard_clk  : inout std_logic;
        PS2_keyboard_Data : in    std_logic;

        PS2_mouse_clk  : inout std_logic;
        PS2_mouse_Data : in    std_logic;

        hs : out std_logic;
        vs : out std_logic;

        VGA_B : out std_logic_vector(2 downto 0);
        VGA_G : out std_logic_vector(2 downto 0);
        VGA_R : out std_logic_vector(2 downto 0);

        char_len : out CharPos
        ) ;
end entity;  -- MasterController

architecture arch of MasterController is
    component KeyboardListener is
        port(
            clk   : inout std_logic;
            data  : in    std_logic;
            event : inout Event
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
            mousex        : buffer XCoordinate;
            mousey        : buffer YCoordinate;
            error_no_ack  : out    std_logic
            );
    end component;
    component TextProcessor is
        port(
            rst                         : in     std_logic;
            txt                         : buffer TextArea;
            keyboard_event, mouse_event : inout  Event;
            cursor                      : buffer     CharPos
            );
    end component;

    component TextDisplayer is
        port(
            clk_100       : in     std_logic;
            reset         : in     std_logic;
            --text information
            txt           : buffer TextArea;
			cursor      : buffer CharPos;
            --mouse
            left_button   : in     std_logic;
            right_button  : in     std_logic;
            middle_button : in     std_logic;
            mousex        : in     std_logic_vector(9 downto 0);
            mousey        : in     std_logic_vector(8 downto 0);
            error_no_ack  : in     std_logic;
            --display output
            x_pos         : in     std_logic_vector(9 downto 0);
            y_pos         : in     std_logic_vector(8 downto 0);
            rgb           : out    RGBColor;
            --rom interaction
            address       : out    std_logic_vector(15 downto 0);
            bitmap        : in     std_logic_vector(63 downto 0)
            );
    end component;

    component char_rom is
        port
            (
                address : in  std_logic_vector (13 downto 0);
                clock   : in  std_logic;
                q       : out std_logic_vector (31 downto 0)
                );
    end component;

begin

end architecture;  -- arch
