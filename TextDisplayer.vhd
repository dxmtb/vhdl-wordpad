library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TextDisplayer is
    port (
             clk_100       : in     std_logic;
             reset           : in     std_logic;
             clk_25 : out std_logic;
        --text information
             text          : buffer TextArea;
        --mouse
             left_button   : in     std_logic;
             right_button  : in     std_logic;
             middle_button : in     std_logic;
             mousex        : buffer std_logic_vector(9 downto 0);
             mousey        : buffer std_logic_vector(9 downto 0);
             error_no_ack  : in     std_logic;
        --vga out
             hs            : out    std_logic;
             vs            : out    std_logic;

             VGA_B : out std_logic_vector(2 downto 0);
             VGA_G : out std_logic_vector(2 downto 0);
             VGA_R : out std_logic_vector(2 downto 0)
         ) ;
end entity;  -- TextDisplayer

architecture arch of TextDisplayer is
    signal r1, g1, b1 : std_logic_vector(2 downto 0);
    signal hs1, vs1   : std_logic;
    signal vector_x   : std_logic_vector(9 downto 0);  --X坐标
    signal vector_y   : std_logic_vector(8 downto 0);  --Y坐标
    signal clk1       : std_logic;
    signal clk        : std_logic;
    signal counter : std_logic_vector(1 downto 0) ;
begin
    clk25 <= clk;

    process(clk_100)
    begin
        if(clk_100'event and clk_100='1') then 
            counter <= counter + 1;
        end if;
    end process;

    process(counter)
    begin
        if (counter == "00") then
            clk25 = not clk25;
        end if;
    end process;

    process(clk,reset)	--行区间像素数（含消隐区）
    begin
        if reset='0' then
            vector_x <= (others=>'0');
        elsif clk'event and clk='1' then
            if vector_x=799 then
                vector_x <= (others=>'0');
            else
                vector_x <= vector_x + 1;
            end if;
        end if;
    end process;

     -----------------------------------------------------------------------
    process(clk,reset)	--场区间行数（含消隐区）
    begin
        if reset='0' then
            vector_y <= (others=>'0');
        elsif clk'event and clk='1' then
            if vector_x=799 then
                if vector_y=524 then
                    vector_y <= (others=>'0');
                else
                    vector_y <= vector_y + 1;
                end if;
            end if;
        end if;
    end process;
    process(clk,reset) --行同步信号产生（同步宽度96，前沿16）
    begin
        if reset='0' then
            hs1 <= '1';
        elsif clk'event and clk='1' then
            if vector_x>=656 and vector_x<752 then
                hs1 <= '0';
            else
                hs1 <= '1';
            end if;
        end if;
    end process;

     -----------------------------------------------------------------------
    process(clk,reset) --场同步信号产生（同步宽度2，前沿10）
    begin
        if reset='0' then
            vs1 <= '1';
        elsif clk'event and clk='1' then
            if vector_y>=490 and vector_y<492 then
                vs1 <= '0';
            else
                vs1 <= '1';
            end if;
        end if;
    end process;
     -----------------------------------------------------------------------
    process(clk,reset) --行同步信号输出
    begin
        if reset='0' then
            hs <= '0';
        elsif clk'event and clk='1' then
            hs <=  hs1;
        end if;
    end process;

 -----------------------------------------------------------------------
	 process(clk,reset) --场同步信号输出
	 begin
	  	if reset='0' then
	   		vs <= '0';
	  	elsif clk'event and clk='1' then
	   		vs <=  vs1;
	  	end if;
	 end process;
end architecture;  -- arch
