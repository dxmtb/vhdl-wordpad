-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.GlobalDefines.all;
-------------------------------------------------------------------------------------
entity KeyScanner is
	port (
		clk			:	in std_logic;			--100MHz
		reset		:	in std_logic;
		PS2clk		:	inout std_logic;
		PS2Data		:	in std_logic;

		err			:	out std_logic;
		keyClk		:	out	std_logic;
		ascii :  out STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
end entity;
-------------------------------------------------------------------------------------
architecture behavior of KeyScanner is
	component PS2KBInterface is
		port (
			clk			:	in std_logic;		--1MHz
			reset		:	in std_logic;
			PS2clk		:	inout std_logic;
			PS2Data		:	in std_logic;

			received	:	buffer std_logic;
			data		:	buffer std_logic_vector(7 downto 0);
			err			:	buffer std_logic
		);
	end component;

	signal clk1			:	std_logic;
	signal counter		:	integer range 0 to 49;
	signal received		:	std_logic;
	signal data			:	std_logic_vector(7 downto 0);
	signal lastData		:	std_logic_vector(15 downto 0);
	signal prepare		:	std_logic;
	signal shifted		:	boolean;
-------------------------------------------------------------------------------------
begin
-------------------------------------------------------------------------------------
	interface	:	PS2KBInterface port map	(
		clk			=>	clk1,
		reset		=>	reset,
		PS2clk		=>	PS2clk,
		PS2Data		=>	PS2Data,
		received	=>	received,
		data		=>	data,
		err			=>	err
	);
-------------------------------------------------------------------------------------
	process(clk, reset) begin
		if reset = '0' then
			counter <= 0;
		elsif clk'event and clk = '1' then
			if counter = 49 then
				counter <= 0;
				clk1 <= not clk1;
			else
				counter <= counter + 1;
			end if;
		end if;
	end process;
-------------------------------------------------------------------------------------
	process(clk1, reset) begin
		if reset = '0' then
			lastData <= (others => '0');
--			err <= '0';
			prepare <= '0';
			shifted <= false;
		elsif clk1'event and clk1 = '1' then
			keyClk <= prepare;
			if received = '1' then
				lastData(15 downto 8) <= lastData(7 downto 0);
				lastData(7 downto 0) <= data;

				if lastData(7 downto 0) = X"F0" then
					if shifted and (data = X"12" or data = X"59") then
						shifted <= false;
					end if;
					prepare <= '0';
				else
					prepare <= '1';
					  CASE data IS
						WHEN x"29" => ascii <= x"20"; --space
						WHEN x"66" => ascii <= x"08"; --backspace (BS control code)
						WHEN x"0D" => ascii <= x"09"; --tab (HT control code)
						WHEN x"5A" => ascii <= x"0D"; --enter (CR control code)
						WHEN x"76" => ascii <= x"1B"; --escape (ESC control code)
						WHEN OTHERS => prepare <= '0';
					  END CASE;
					if shifted then

						CASE data IS              
						  WHEN x"1C" => ascii <= x"41"; --A
						  WHEN x"32" => ascii <= x"42"; --B
						  WHEN x"21" => ascii <= x"43"; --C
						  WHEN x"23" => ascii <= x"44"; --D
						  WHEN x"24" => ascii <= x"45"; --E
						  WHEN x"2B" => ascii <= x"46"; --F
						  WHEN x"34" => ascii <= x"47"; --G
						  WHEN x"33" => ascii <= x"48"; --H
						  WHEN x"43" => ascii <= x"49"; --I
						  WHEN x"3B" => ascii <= x"4A"; --J
						  WHEN x"42" => ascii <= x"4B"; --K
						  WHEN x"4B" => ascii <= x"4C"; --L
						  WHEN x"3A" => ascii <= x"4D"; --M
						  WHEN x"31" => ascii <= x"4E"; --N
						  WHEN x"44" => ascii <= x"4F"; --O
						  WHEN x"4D" => ascii <= x"50"; --P
						  WHEN x"15" => ascii <= x"51"; --Q
						  WHEN x"2D" => ascii <= x"52"; --R
						  WHEN x"1B" => ascii <= x"53"; --S
						  WHEN x"2C" => ascii <= x"54"; --T
						  WHEN x"3C" => ascii <= x"55"; --U
						  WHEN x"2A" => ascii <= x"56"; --V
						  WHEN x"1D" => ascii <= x"57"; --W
						  WHEN x"22" => ascii <= x"58"; --X
						  WHEN x"35" => ascii <= x"59"; --Y
						  WHEN x"1A" => ascii <= x"5A"; --Z
						  WHEN OTHERS => prepare <= '0';
						END CASE;
					else
						CASE data IS              
						  WHEN x"1C" => ascii <= x"61"; --a
						  WHEN x"32" => ascii <= x"62"; --b
						  WHEN x"21" => ascii <= x"63"; --c
						  WHEN x"23" => ascii <= x"64"; --d
						  WHEN x"24" => ascii <= x"65"; --e
						  WHEN x"2B" => ascii <= x"66"; --f
						  WHEN x"34" => ascii <= x"67"; --g
						  WHEN x"33" => ascii <= x"68"; --h
						  WHEN x"43" => ascii <= x"69"; --i
						  WHEN x"3B" => ascii <= x"6A"; --j
						  WHEN x"42" => ascii <= x"6B"; --k
						  WHEN x"4B" => ascii <= x"6C"; --l
						  WHEN x"3A" => ascii <= x"6D"; --m
						  WHEN x"31" => ascii <= x"6E"; --n
						  WHEN x"44" => ascii <= x"6F"; --o
						  WHEN x"4D" => ascii <= x"70"; --p
						  WHEN x"15" => ascii <= x"71"; --q
						  WHEN x"2D" => ascii <= x"72"; --r
						  WHEN x"1B" => ascii <= x"73"; --s
						  WHEN x"2C" => ascii <= x"74"; --t
						  WHEN x"3C" => ascii <= x"75"; --u
						  WHEN x"2A" => ascii <= x"76"; --v
						  WHEN x"1D" => ascii <= x"77"; --w
						  WHEN x"22" => ascii <= x"78"; --x
						  WHEN x"35" => ascii <= x"79"; --y
						  WHEN x"1A" => ascii <= x"7A"; --z
						  WHEN OTHERS => prepare <= '0';
						END CASE;
					end if;
				end if;
			end if;
		end if;
	end process;
-------------------------------------------------------------------------------------
end;
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
