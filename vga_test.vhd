-- Test for vga_driver

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_test is
	Port(
		clk_50: in std_logic;
		reset: in std_logic;
		VGA_HS: out std_logic;
		VGA_VS: out std_logic;
		VGA_R: out std_logic_vector(3 downto 0);
		VGA_G: out std_logic_vector(3 downto 0);
		VGA_B: out std_logic_vector(3 downto 0)
	);
end vga_test;

architecture hardware of vga_test is
	signal clk_25: std_logic;
	
	component clock_25 is
		Port(
			clk : in std_logic;
			clk_vga : out std_logic
		);
	end component;
	
	component driver_vga is
		generic(
			-- Default VGA 640-by-480 display parameters
			H_back_porch: 	natural:=48; 	
			H_display: 		natural:=640; 
			H_front_porch: natural:=16; 	
			H_retrace: 		natural:=96; 	
			V_back_porch: 	natural:=33; 	
			V_display: 		natural:=480; 
			V_front_porch: natural:=10; 
			V_retrace: 		natural:=2;
			Color_bits:		natural:=4;
			H_counter_size: natural:= 10;		--  depends on above generic values
			V_counter_size: natural:= 10;		--  depends on above generic values
			H_sync_polarity: std_logic:= '0';		--  depends on standard (negative -> 0), (positive -> 1)
			V_sync_polarity: std_logic:= '0'			--  depends on standard (negative -> 0), (positive -> 1)
		);
		Port(
			vid_clk: 		in std_logic;
			reset: 			in std_logic;
			h_sync:			out std_logic;
			v_sync:			out std_logic;
 			pixel_x: 		out integer;
			pixel_y: 		out integer;
			vid_display:	out std_logic	:= '0';
			red_in:     in std_logic_vector((Color_bits - 1) downto 0);
			green_in:	in	std_logic_vector((Color_bits - 1) downto 0);
			blue_in:		in	std_logic_vector((Color_bits - 1) downto 0);
			red_out:			out	std_logic_vector((Color_bits - 1) downto 0) := (others => '0');
			green_out:		out	std_logic_vector((Color_bits - 1) downto 0) := (others => '0');
			blue_out: out	std_logic_vector((Color_bits - 1) downto 0) := (others => '0')			
		);
	end component;

begin

	clock: clock_25
		port map(
			clk => clk_50,
			clk_vga => clk_25
		);
	
	vga: driver_vga
		generic map(
			H_back_porch => 48, 	
			H_display => 640, 
			H_front_porch => 16, 	
			H_retrace => 96, 	
			V_back_porch => 33, 	
			V_display => 480, 
			V_front_porch => 10, 
			V_retrace => 2,
			Color_bits => 4,
			H_counter_size => 10,
			V_counter_size => 10,	
			H_sync_polarity => '0',
			V_sync_polarity => '0'
		)
		port map(
			vid_clk => clk_25,
			reset => reset,
			h_sync => VGA_HS,
			v_sync => VGA_VS,
 			--pixel_x => 	
			--pixel_y =>	
			--vid_display 
			red_in => "0000",
			green_in => "0000",
			blue_in => "1111",
			red_out => VGA_R,	
			green_out => VGA_G,
			blue_out =>	VGA_B 
		);
	
end architecture;