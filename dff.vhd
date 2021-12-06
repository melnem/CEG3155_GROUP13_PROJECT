--d flip flop code 

library ieee;
use ieee.std_logic_1164.all;

entity dff is
	port(
		d, clk, reset : in std_logic;
		q : out std_logic);
end dff;
architecture str_dff of dff is

begin
	process(clk)
	begin
		if (clk'EVENT and clk ='1') then
			q<=d;
		end if;
	end process;
	

end str_dff;