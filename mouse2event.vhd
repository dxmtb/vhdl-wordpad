library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.GlobalDefines.all;

entity mouse2event is
    port (
        clk   : in    std_logic;
        event : inout Event
        ) ;
end entity;  -- mouse2event

architecture arch of mouse2event is
    component ps2_mouse is
        port(clk_in        : in     std_logic;
             reset_in      : in     std_logic;
             ps2_clk       : inout  std_logic;
             ps2_data      : inout  std_logic;
             left_button   : out    std_logic;
             right_button  : out    std_logic;
             middle_button : out    std_logic;
             mousex        : buffer std_logic_vector(9 downto 0);
             mousey        : buffer std_logic_vector(9 downto 0);
             error_no_ack  : out    std_logic);
    end component;

    signal buttons : std_logic;
begin
    buttons <= left_button or right_button or middle_button;

    process(clock)
    begin
        if(rising_edge(clock)) then
            if (buttons) then
                if mousex >= 0 and mousey < 100 then
                    event.e_type <= CLICK_BUTTON;
                    event.args   <= 1;
                end if;
            end if;
        end if;
    end process;

end architecture;  -- arch
