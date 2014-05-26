library	ieee;
use		ieee.std_logic_1164.all;
use		ieee.std_logic_unsigned.all;
use		ieee.std_logic_arith.all;

entity VGADisplayer is
    port(
            reset       :         in  STD_LOGIC;
            clk25       :		  out std_logic; 
            rgb		    :		  in RGBColor;
            clk_0       :         in  STD_LOGIC; --100M时钟输入
            hs,vs       :         out STD_LOGIC; --行同步、场同步信号
			r,g,b       :         out STD_LOGIC_vector(2 downto 0)
            x_pos       :           out std_logic_vector(9 downto 0);		--X坐标
            y_pos       : out std_logic_vector(8 downto 0);		--Y坐标
        );
end entity;

architecture behavior of VGADisplayer is

    signal r1,g1,b1   : std_logic_vector(2 downto 0);					
    signal hs1,vs1    : std_logic;				
    signal vector_x : std_logic_vector(9 downto 0);		--X坐标
    signal vector_y : std_logic_vector(8 downto 0);		--Y坐标
    signal clk1	:	 std_logic;
    signal clk :  	 std_logic;
begin
    clk25 <= clk;
    x_pos <= vector_x;
    y_pos <= vector_y;
    -----------------------------------------------------------------------
    process(clk_0)	--对100M输入信号二分频
    begin
        if(clk_0'event and clk_0='1') then 
            clk1 <= not clk1;
        end if;
    end process;
    process(clk1)	--对50M输入信号二分频
    begin
        if(clk1'event and clk1='1') then 
            clk <= not clk;
        end if;
    end process;

    -----------------------------------------------------------------------
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

    -----------------------------------------------------------------------
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

    -----------------------------------------------------------------------	
    process(reset,clk,vector_x,vector_y) -- XY坐标定位控制
    begin  
        if reset='0' then
            r1  <= "000";
            g1	<= "000";
            b1	<= "000";	
        elsif(clk'event and clk='1')then
            r1 <= "111" when rgb(Blue)  = '1' else "000";
            g1 <= "111" when rgb(Green) = '1' else "000";
            b1 <= "111" when rgb(Red)   = '1' else "000";
        end if;		 
    end process;	

    -----------------------------------------------------------------------
    process (hs1, vs1, r1, g1, b1)	--色彩输出
    begin
        if hs1 = '1' and vs1 = '1' then
            r	<= r1;
            g	<= g1;
            b	<= b1;
        else
            r	<= (others => '0');
            g	<= (others => '0');
            b	<= (others => '0');
        end if;
    end process;

end behavior;


