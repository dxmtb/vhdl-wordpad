-------------------------------------------------------------------------------------
-- PS2 keyboard interface
-------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
-------------------------------------------------------------------------------------
entity PS2KBInterface is
    port (
        clk     : in    std_logic;      --1MHz
        reset   : in    std_logic;
        PS2clk  : inout std_logic;
        PS2Data : in    std_logic;

        received : buffer std_logic;
        data     : buffer std_logic_vector(7 downto 0);
        err      : buffer std_logic
        );
end entity;
-------------------------------------------------------------------------------------
architecture behavior of PS2KBInterface is

    type   STATES is (ST_WAITING, ST_READING, ST_CHECKING, ST_ENDING, ST_REFUSING);
    signal state   : STATES;
    signal pos     : integer range 0 to 7;
    signal hits    : integer range 0 to 255;
    signal lastClk : std_logic;
-------------------------------------------------------------------------------------
begin
-------------------------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '0' then
            hits   <= 0;
            pos    <= 0;
            state  <= ST_WAITING;
            err    <= '0';
            PS2clk <= 'Z';
        elsif clk'event and clk = '1' then
            lastClk <= PS2clk;
            if received = '1' then
                received <= '0';
            elsif lastClk = '1' and PS2clk = '0' then
                hits <= 0;
                case state is
                    when ST_WAITING =>
                        data(0) <= '1';
                        if PS2Data = '0' then
                            state <= ST_READING;
                            pos   <= 0;
                        else
                            state  <= ST_REFUSING;
                            err    <= '1';
                            PS2Clk <= '0';
                        end if;

                    when ST_READING =>
                        data(pos) <= PS2Data;
                        hits      <= 0;
                        if pos = 7 then
                            state <= ST_CHECKING;
                        else
                            pos <= pos + 1;
                        end if;

                    when ST_CHECKING =>
                        if (data(0) xor data(1) xor data(2) xor data(3) xor data(4)
                            xor data(5) xor data(6) xor data(7) xor PS2Data) = '1' then
                            state <= ST_ENDING;
                        else
                            state  <= ST_REFUSING;
                            err    <= '1';
                            ps2Clk <= '0';
                        end if;

                    when ST_ENDING =>
                        if PS2Data = '1' then
                            state    <= ST_WAITING;
                            received <= '1';
                        else
                            state  <= ST_REFUSING;
                            err    <= '1';
                            ps2Clk <= '0';
                        end if;

                    when ST_REFUSING =>

                end case;
            elsif state /= ST_WAITING then
                hits <= hits + 1;
                if hits = 200 then
                    if state = ST_REFUSING then
                        state  <= ST_WAITING;
                        err    <= '0';
                        ps2Clk <= 'Z';
                    else
                        state  <= ST_REFUSING;
                        err    <= '1';
                        ps2Clk <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture;
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
