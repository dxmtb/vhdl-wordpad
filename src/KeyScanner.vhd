-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.GlobalDefines.all;
-------------------------------------------------------------------------------------
entity KeyScanner is
    port (
        clk     : in    std_logic;      --100MHz
        reset   : in    std_logic;
        PS2clk  : inout std_logic;
        PS2Data : in    std_logic;

        err      : out std_logic;
        keyClk   : out std_logic;
        ascii    : out std_logic_vector(7 downto 0);
        scancode : out std_logic_vector(7 downto 0)
        );
end entity;
-------------------------------------------------------------------------------------
architecture behavior of KeyScanner is
    component PS2KBInterface is
        port (
            clk     : in    std_logic;  --1MHz
            reset   : in    std_logic;
            PS2clk  : inout std_logic;
            PS2Data : in    std_logic;

            received : buffer std_logic;
            data     : buffer std_logic_vector(7 downto 0);
            err      : buffer std_logic
            );
    end component;

    signal clk1     : std_logic;
    signal counter  : integer range 0 to 49;
    signal received : std_logic;
    signal data     : std_logic_vector(7 downto 0);
    signal lastData : std_logic_vector(23 downto 0);
    signal prepare  : std_logic;
    signal shifted  : boolean;
    signal flag     : boolean;
-------------------------------------------------------------------------------------
begin
    scancode <= data;
-------------------------------------------------------------------------------------
    interface : PS2KBInterface port map (
        clk      => clk1,
        reset    => reset,
        PS2clk   => PS2clk,
        PS2Data  => PS2Data,
        received => received,
        data     => data,
        err      => err
        );
-------------------------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '0' then
            counter <= 0;
        elsif clk'event and clk = '1' then
            if counter = 49 then
                counter <= 0;
                clk1    <= not clk1;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;
-------------------------------------------------------------------------------------
    process(clk1, reset)
    begin
        if reset = '0' then
            lastData <= (others => '0');
--                      err <= '0';
            prepare  <= '0';
            shifted  <= false;
        elsif clk1'event and clk1 = '1' then
            keyClk <= prepare;
            if received = '1' then
                lastData(15 downto 8) <= lastData(7 downto 0);
                lastData(7 downto 0)  <= data;

                if lastData(7 downto 0) = X"F0" then
                    if shifted and (data = X"12" or data = X"59") then
                        shifted <= false;
                    end if;
                    prepare <= '0';
                elsif shifted then
                    if flag then
                        case data is
                            when x"1C"  => ascii   <= x"61"; prepare <= '1';  --a
                            when x"32"  => ascii   <= x"62"; prepare <= '1';  --b
                            when x"21"  => ascii   <= x"63"; prepare <= '1';  --c
                            when x"23"  => ascii   <= x"64"; prepare <= '1';  --d
                            when x"24"  => ascii   <= x"65"; prepare <= '1';  --e
                            when x"2B"  => ascii   <= x"66"; prepare <= '1';  --f
                            when x"34"  => ascii   <= x"67"; prepare <= '1';  --g
                            when x"33"  => ascii   <= x"68"; prepare <= '1';  --h
                            when x"43"  => ascii   <= x"69"; prepare <= '1';  --i
                            when x"3B"  => ascii   <= x"6A"; prepare <= '1';  --j
                            when x"42"  => ascii   <= x"6B"; prepare <= '1';  --k
                            when x"4B"  => ascii   <= x"6C"; prepare <= '1';  --l
                            when x"3A"  => ascii   <= x"6D"; prepare <= '1';  --m
                            when x"31"  => ascii   <= x"6E"; prepare <= '1';  --n
                            when x"44"  => ascii   <= x"6F"; prepare <= '1';  --o
                            when x"4D"  => ascii   <= x"70"; prepare <= '1';  --p
                            when x"15"  => ascii   <= x"71"; prepare <= '1';  --q
                            when x"2D"  => ascii   <= x"72"; prepare <= '1';  --r
                            when x"1B"  => ascii   <= x"73"; prepare <= '1';  --s
                            when x"2C"  => ascii   <= x"74"; prepare <= '1';  --t
                            when x"3C"  => ascii   <= x"75"; prepare <= '1';  --u
                            when x"2A"  => ascii   <= x"76"; prepare <= '1';  --v
                            when x"1D"  => ascii   <= x"77"; prepare <= '1';  --w
                            when x"22"  => ascii   <= x"78"; prepare <= '1';  --x
                            when x"35"  => ascii   <= x"79"; prepare <= '1';  --y
                            when x"1A"  => ascii   <= x"7A"; prepare <= '1';  --z
                            when x"16"  => ascii   <= x"21"; prepare <= '1';  --!
                            when x"52"  => ascii   <= x"22"; prepare <= '1';  --"
                            when x"26"  => ascii   <= x"23"; prepare <= '1';  --#
                            when x"25"  => ascii   <= x"24"; prepare <= '1';  --$
                            when x"2E"  => ascii   <= x"25"; prepare <= '1';  --%
                            when x"3D"  => ascii   <= x"26"; prepare <= '1';  --&
                            when x"46"  => ascii   <= x"28"; prepare <= '1';  --(
                            when x"45"  => ascii   <= x"29"; prepare <= '1';  --)
                            when x"3E"  => ascii   <= x"2A"; prepare <= '1';  --*
                            when x"55"  => ascii   <= x"2B"; prepare <= '1';  --+
                            when x"4C"  => ascii   <= x"3A"; prepare <= '1';  --:
                            when x"41"  => ascii   <= x"3C"; prepare <= '1';  --<
                            when x"49"  => ascii   <= x"3E"; prepare <= '1';  -->
                            when x"4A"  => ascii   <= x"3F"; prepare <= '1';  --?
                            when x"1E"  => ascii   <= x"40"; prepare <= '1';  --@
                            when x"36"  => ascii   <= x"5E"; prepare <= '1';  --^
                            when x"4E"  => ascii   <= x"5F"; prepare <= '1';  --_
                            when x"54"  => ascii   <= x"7B"; prepare <= '1';  --{
                            when x"5D"  => ascii   <= x"7C"; prepare <= '1';  --|
                            when x"5B"  => ascii   <= x"7D"; prepare <= '1';  --}
                            when x"0E"  => ascii   <= x"7E"; prepare <= '1';  --~
                            when others => prepare <= '0';
                        end case;
                    else
                        case data is
                            when x"1C"  => ascii   <= x"41"; prepare <= '1';  --A
                            when x"32"  => ascii   <= x"42"; prepare <= '1';  --B
                            when x"21"  => ascii   <= x"43"; prepare <= '1';  --C
                            when x"23"  => ascii   <= x"44"; prepare <= '1';  --D
                            when x"24"  => ascii   <= x"45"; prepare <= '1';  --E
                            when x"2B"  => ascii   <= x"46"; prepare <= '1';  --F
                            when x"34"  => ascii   <= x"47"; prepare <= '1';  --G
                            when x"33"  => ascii   <= x"48"; prepare <= '1';  --H
                            when x"43"  => ascii   <= x"49"; prepare <= '1';  --I
                            when x"3B"  => ascii   <= x"4A"; prepare <= '1';  --J
                            when x"42"  => ascii   <= x"4B"; prepare <= '1';  --K
                            when x"4B"  => ascii   <= x"4C"; prepare <= '1';  --L
                            when x"3A"  => ascii   <= x"4D"; prepare <= '1';  --M
                            when x"31"  => ascii   <= x"4E"; prepare <= '1';  --N
                            when x"44"  => ascii   <= x"4F"; prepare <= '1';  --O
                            when x"4D"  => ascii   <= x"50"; prepare <= '1';  --P
                            when x"15"  => ascii   <= x"51"; prepare <= '1';  --Q
                            when x"2D"  => ascii   <= x"52"; prepare <= '1';  --R
                            when x"1B"  => ascii   <= x"53"; prepare <= '1';  --S
                            when x"2C"  => ascii   <= x"54"; prepare <= '1';  --T
                            when x"3C"  => ascii   <= x"55"; prepare <= '1';  --U
                            when x"2A"  => ascii   <= x"56"; prepare <= '1';  --V
                            when x"1D"  => ascii   <= x"57"; prepare <= '1';  --W
                            when x"22"  => ascii   <= x"58"; prepare <= '1';  --X
                            when x"35"  => ascii   <= x"59"; prepare <= '1';  --Y
                            when x"1A"  => ascii   <= x"5A"; prepare <= '1';  --Z
                            when x"16"  => ascii   <= x"21"; prepare <= '1';  --!
                            when x"52"  => ascii   <= x"22"; prepare <= '1';  --"
                            when x"26"  => ascii   <= x"23"; prepare <= '1';  --#
                            when x"25"  => ascii   <= x"24"; prepare <= '1';  --$
                            when x"2E"  => ascii   <= x"25"; prepare <= '1';  --%
                            when x"3D"  => ascii   <= x"26"; prepare <= '1';  --&
                            when x"46"  => ascii   <= x"28"; prepare <= '1';  --(
                            when x"45"  => ascii   <= x"29"; prepare <= '1';  --)
                            when x"3E"  => ascii   <= x"2A"; prepare <= '1';  --*
                            when x"55"  => ascii   <= x"2B"; prepare <= '1';  --+
                            when x"4C"  => ascii   <= x"3A"; prepare <= '1';  --:
                            when x"41"  => ascii   <= x"3C"; prepare <= '1';  --<
                            when x"49"  => ascii   <= x"3E"; prepare <= '1';  -->
                            when x"4A"  => ascii   <= x"3F"; prepare <= '1';  --?
                            when x"1E"  => ascii   <= x"40"; prepare <= '1';  --@
                            when x"36"  => ascii   <= x"5E"; prepare <= '1';  --^
                            when x"4E"  => ascii   <= x"5F"; prepare <= '1';  --_
                            when x"54"  => ascii   <= x"7B"; prepare <= '1';  --{
                            when x"5D"  => ascii   <= x"7C"; prepare <= '1';  --|
                            when x"5B"  => ascii   <= x"7D"; prepare <= '1';  --}
                            when x"0E"  => ascii   <= x"7E"; prepare <= '1';  --~
                            when others => prepare <= '0';
                        end case;
                    end if;
                else
                    if flag then
                        case data is
                            when X"12"  => shifted <= true;
                            when X"59"  => shifted <= true;
                            when x"58"  => flag    <= false;  --caps
                            when x"29"  => ascii   <= x"20"; prepare <= '1';  --space 32
                            when x"66"  => ascii   <= x"08"; prepare <= '1';  --backspace (BS control code) 8
                            when x"0D"  => ascii   <= x"09"; prepare <= '1';  --tab (HT control code) 9
                            when x"5A"  => ascii   <= x"0D"; prepare <= '1';  --enter (CR control code) 13
                            when x"76"  => ascii   <= x"1B"; prepare <= '1';  --escape (ESC control code) 27
                            when x"1C"  => ascii   <= x"41"; prepare <= '1';  --A
                            when x"32"  => ascii   <= x"42"; prepare <= '1';  --B
                            when x"21"  => ascii   <= x"43"; prepare <= '1';  --C
                            when x"23"  => ascii   <= x"44"; prepare <= '1';  --D
                            when x"24"  => ascii   <= x"45"; prepare <= '1';  --E
                            when x"2B"  => ascii   <= x"46"; prepare <= '1';  --F
                            when x"34"  => ascii   <= x"47"; prepare <= '1';  --G
                            when x"33"  => ascii   <= x"48"; prepare <= '1';  --H
                            when x"43"  => ascii   <= x"49"; prepare <= '1';  --I
                            when x"3B"  => ascii   <= x"4A"; prepare <= '1';  --J
                            when x"42"  => ascii   <= x"4B"; prepare <= '1';  --K
                            when x"4B"  => ascii   <= x"4C"; prepare <= '1';  --L
                            when x"3A"  => ascii   <= x"4D"; prepare <= '1';  --M
                            when x"31"  => ascii   <= x"4E"; prepare <= '1';  --N
                            when x"44"  => ascii   <= x"4F"; prepare <= '1';  --O
                            when x"4D"  => ascii   <= x"50"; prepare <= '1';  --P
                            when x"15"  => ascii   <= x"51"; prepare <= '1';  --Q
                            when x"2D"  => ascii   <= x"52"; prepare <= '1';  --R
                            when x"1B"  => ascii   <= x"53"; prepare <= '1';  --S
                            when x"2C"  => ascii   <= x"54"; prepare <= '1';  --T
                            when x"3C"  => ascii   <= x"55"; prepare <= '1';  --U
                            when x"2A"  => ascii   <= x"56"; prepare <= '1';  --V
                            when x"1D"  => ascii   <= x"57"; prepare <= '1';  --W
                            when x"22"  => ascii   <= x"58"; prepare <= '1';  --X
                            when x"35"  => ascii   <= x"59"; prepare <= '1';  --Y
                            when x"1A"  => ascii   <= x"5A"; prepare <= '1';  --Z
                            when x"45"  => ascii   <= x"30"; prepare <= '1';  --0
                            when x"16"  => ascii   <= x"31"; prepare <= '1';  --1
                            when x"1E"  => ascii   <= x"32"; prepare <= '1';  --2
                            when x"26"  => ascii   <= x"33"; prepare <= '1';  --3
                            when x"25"  => ascii   <= x"34"; prepare <= '1';  --4
                            when x"2E"  => ascii   <= x"35"; prepare <= '1';  --5
                            when x"36"  => ascii   <= x"36"; prepare <= '1';  --6
                            when x"3D"  => ascii   <= x"37"; prepare <= '1';  --7
                            when x"3E"  => ascii   <= x"38"; prepare <= '1';  --8
                            when x"46"  => ascii   <= x"39"; prepare <= '1';  --9
                            when x"52"  => ascii   <= x"27"; prepare <= '1';  --'
                            when x"41"  => ascii   <= x"2C"; prepare <= '1';  --,
                            when x"4E"  => ascii   <= x"2D"; prepare <= '1';  ---
                            when x"49"  => ascii   <= x"2E"; prepare <= '1';  --.
                            when x"4A"  => ascii   <= x"2F"; prepare <= '1';  --/
                            when x"4C"  => ascii   <= x"3B"; prepare <= '1';  --;
                            when x"55"  => ascii   <= x"3D"; prepare <= '1';  --=
                            when x"54"  => ascii   <= x"5B"; prepare <= '1';  --[
                            when x"5D"  => ascii   <= x"5C"; prepare <= '1';  --\
                            when x"5B"  => ascii   <= x"5D"; prepare <= '1';  --]
                            when x"0E"  => ascii   <= x"60"; prepare <= '1';  --`
                            when others => prepare <= '0';
                        end case;
                    else
                        case data is
                            when X"12"  => shifted <= true;
                            when X"59"  => shifted <= true;
                            when x"58"  => flag    <= true;   --caps
                            when x"29"  => ascii   <= x"20"; prepare <= '1';  --space 32
                            when x"66"  => ascii   <= x"08"; prepare <= '1';  --backspace (BS control code) 8
                            when x"0D"  => ascii   <= x"09"; prepare <= '1';  --tab (HT control code) 9
                            when x"5A"  => ascii   <= x"0D"; prepare <= '1';  --enter (CR control code) 13
                            when x"76"  => ascii   <= x"1B"; prepare <= '1';  --escape (ESC control code) 27
                            when x"1C"  => ascii   <= x"61"; prepare <= '1';  --a
                            when x"32"  => ascii   <= x"62"; prepare <= '1';  --b
                            when x"21"  => ascii   <= x"63"; prepare <= '1';  --c
                            when x"23"  => ascii   <= x"64"; prepare <= '1';  --d
                            when x"24"  => ascii   <= x"65"; prepare <= '1';  --e
                            when x"2B"  => ascii   <= x"66"; prepare <= '1';  --f
                            when x"34"  => ascii   <= x"67"; prepare <= '1';  --g
                            when x"33"  => ascii   <= x"68"; prepare <= '1';  --h
                            when x"43"  => ascii   <= x"69"; prepare <= '1';  --i
                            when x"3B"  => ascii   <= x"6A"; prepare <= '1';  --j
                            when x"42"  => ascii   <= x"6B"; prepare <= '1';  --k
                            when x"4B"  => ascii   <= x"6C"; prepare <= '1';  --l
                            when x"3A"  => ascii   <= x"6D"; prepare <= '1';  --m
                            when x"31"  => ascii   <= x"6E"; prepare <= '1';  --n
                            when x"44"  => ascii   <= x"6F"; prepare <= '1';  --o
                            when x"4D"  => ascii   <= x"70"; prepare <= '1';  --p
                            when x"15"  => ascii   <= x"71"; prepare <= '1';  --q
                            when x"2D"  => ascii   <= x"72"; prepare <= '1';  --r
                            when x"1B"  => ascii   <= x"73"; prepare <= '1';  --s
                            when x"2C"  => ascii   <= x"74"; prepare <= '1';  --t
                            when x"3C"  => ascii   <= x"75"; prepare <= '1';  --u
                            when x"2A"  => ascii   <= x"76"; prepare <= '1';  --v
                            when x"1D"  => ascii   <= x"77"; prepare <= '1';  --w
                            when x"22"  => ascii   <= x"78"; prepare <= '1';  --x
                            when x"35"  => ascii   <= x"79"; prepare <= '1';  --y
                            when x"1A"  => ascii   <= x"7A"; prepare <= '1';  --z
                            when x"45"  => ascii   <= x"30"; prepare <= '1';  --0
                            when x"16"  => ascii   <= x"31"; prepare <= '1';  --1
                            when x"1E"  => ascii   <= x"32"; prepare <= '1';  --2
                            when x"26"  => ascii   <= x"33"; prepare <= '1';  --3
                            when x"25"  => ascii   <= x"34"; prepare <= '1';  --4
                            when x"2E"  => ascii   <= x"35"; prepare <= '1';  --5
                            when x"36"  => ascii   <= x"36"; prepare <= '1';  --6
                            when x"3D"  => ascii   <= x"37"; prepare <= '1';  --7
                            when x"3E"  => ascii   <= x"38"; prepare <= '1';  --8
                            when x"46"  => ascii   <= x"39"; prepare <= '1';  --9
                            when x"52"  => ascii   <= x"27"; prepare <= '1';  --'
                            when x"41"  => ascii   <= x"2C"; prepare <= '1';  --,
                            when x"4E"  => ascii   <= x"2D"; prepare <= '1';  ---
                            when x"49"  => ascii   <= x"2E"; prepare <= '1';  --.
                            when x"4A"  => ascii   <= x"2F"; prepare <= '1';  --/
                            when x"4C"  => ascii   <= x"3B"; prepare <= '1';  --;
                            when x"55"  => ascii   <= x"3D"; prepare <= '1';  --=
                            when x"54"  => ascii   <= x"5B"; prepare <= '1';  --[
                            when x"5D"  => ascii   <= x"5C"; prepare <= '1';  --\
                            when x"5B"  => ascii   <= x"5D"; prepare <= '1';  --]
                            when x"0E"  => ascii   <= x"60"; prepare <= '1';  --`
                            when others => prepare <= '0';
                        end case;
                    end if;
                end if;
            end if;
        end if;
    end process;

end;
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
