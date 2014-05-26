library ieee ;
	use ieee.std_logic_1164.all ;
	use ieee.numeric_std.all ;

entity Keyboard2Event is
  port (
	datain, clkin : in std_logic ; -- PS2 clk and data
	fclk, rst : in std_logic ;  -- filter clock
--	fok : out std_logic ;  -- data output enable signal
	scancode : out std_logic_vector(7 downto 0); -- scan code signal output
	event : inout Event
  ) ;
end entity ; -- Keyboard2Event

architecture arch of Keyboard2Event is

begin

end architecture ; -- arch