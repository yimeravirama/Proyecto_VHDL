library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity clock_25 is
	Port(
		clk : in std_logic;
		clk_vga : out std_logic
	);
end clock_25;

architecture Behavioral of clock_25 is
signal cont: std_logic := '0';
begin
	process(clk)
	begin		
		if(clk'event and clk='1') then
			cont <= not cont;
		end if;	
		clk_vga <= cont;
	end process;	
end Behavioral;