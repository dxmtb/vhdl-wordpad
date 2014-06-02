library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.GlobalDefines.all;

entity VGADisplayer is
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
end entity;

architecture behavior of VGADisplayer is

    signal r1, g1, b1 : std_logic_vector(2 downto 0);
    signal hs1, vs1   : std_logic;
    signal vector_x   : XCoordinate;
    signal vector_y   : YCoordinate;
    signal clk1       : std_logic;
    signal clk        : std_logic;
begin
    clk25 <= clk;
    x_pos <= vector_x;
    y_pos <= vector_y;
    -----------------------------------------------------------------------
    process(clk_0)
    begin
        if(clk_0'event and clk_0 = '1') then
            clk1 <= not clk1;
        end if;
    end process;
    process(clk1)
    begin
        if(clk1'event and clk1 = '1') then
            clk <= not clk;
        end if;
    end process;

    process(clk, reset)
    begin
        if reset = '0' then
            vector_x <= 0;
        elsif clk'event and clk = '1' then
            if vector_x = 799 then
                vector_x <= 0;
            else
                vector_x <= vector_x + 1;
            end if;
        end if;
    end process;

    process(clk, reset)
    begin
        if reset = '0' then
            vector_y <= 0;
        elsif clk'event and clk = '1' then
            if vector_x = 799 then
                if vector_y = 524 then
                    vector_y <= 0;
                else
                    vector_y <= vector_y + 1;
                end if;
            end if;
        end if;
    end process;

    process(clk, reset)
    begin
        if reset = '0' then
            hs1 <= '1';
        elsif clk'event and clk = '1' then
            if vector_x >= 656 and vector_x < 752 then
                hs1 <= '0';
            else
                hs1 <= '1';
            end if;
        end if;
    end process;

    process(clk, reset)
    begin
        if reset = '0' then
            vs1 <= '1';
        elsif clk'event and clk = '1' then
            if vector_y >= 490 and vector_y < 492 then
                vs1 <= '0';
            else
                vs1 <= '1';
            end if;
        end if;
    end process;
    process(clk, reset)
    begin
        if reset = '0' then
            hs <= '0';
        elsif clk'event and clk = '1' then
            hs <= hs1;
        end if;
    end process;

    process(clk, reset)
    begin
        if reset = '0' then
            vs <= '0';
        elsif clk'event and clk = '1' then
            vs <= vs1;
        end if;
    end process;

    -----------------------------------------------------------------------     
    process(reset, clk, vector_x, vector_y)
    begin
        if reset = '0' then
            r1 <= "000";
            g1 <= "000";
            b1 <= "000";
        elsif(clk'event and clk = '1')then
            case rgb(Blue) is
                when '0' => r1 <= "000";
                when '1' => r1 <= "111";
            end case;
            case rgb(Green) is
                when '0' => g1 <= "000";
                when '1' => g1 <= "111";
            end case;
            case rgb(Red) is
                when '0' => b1 <= "000";
                when '1' => b1 <= "111";
            end case;
        end if;
    end process;

    process (hs1, vs1, r1, g1, b1)
    begin
        if hs1 = '1' and vs1 = '1' then
            r <= r1;
            g <= g1;
            b <= b1;
        else
            r <= (others => '0');
            g <= (others => '0');
            b <= (others => '0');
        end if;
    end process;

end behavior;


