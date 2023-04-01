--------------------
--
-- VGA_tj.vhdl
-- Created: 9/14/16
-- By: tj
-- For: EE3921
--
-- Rev 1 - modified for DE10 Lite - 7/24/17
--
--------------------
--  Overview
--
-- VGA sync driver
--
--
-- Creates the necessary v-sync and h-sync signals to drive a VGA display
-- Creates pixel X and Y coordinates to indicate the current raster location
-- Creates a "display on" signal to indicate data is being displayed  (optional usage)
-- Provides a buffer path for the RGB signal to ensure syncronization (optional usage)
-- 	NOTE: If using the RGB buffering, the RGB output is already blanked
--				by the display on signal
--------------------------
--- Details 
--
-- Default is:
--					25MHz clock
--					640 x 480 display
--
-- Override default by using generics
--
-- Uses whatever the standard requies for a pixel clock
--     eg. default operation requires a 25MHz input (pixel) clock
--				which can be created via PLL of the DE10 Lite base 50MHz clk
-- 
--  Note that different display resolutions require:
--		Different pixel parameters
--		Different pixel clock frequencies
--		Different sync pulse polarities
--
--  This code is developed based on timing:
--     back porch -> display -> front porch -> sync pulse
--
--------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity driver_vga is
   generic(
		-- Default VGA 640-by-480 display parameters
		H_back_porch: 	integer:=48; 	
		H_display: 		natural:=640; 
		H_front_porch: natural:=16; 	
		H_retrace: 		natural:=96; 	
		V_back_porch: 	integer:=33; 	
		V_display: 		natural:=480; 
		V_front_porch: natural:=10; 
		V_retrace: 		natural:=2;
		Color_bits:		natural:=4;
		H_counter_size: natural:= 10;		--  depends on above generic values
		V_counter_size: natural:= 10;		--  depends on above generic values
		H_sync_polarity: std_logic:= '0';		--  depends on standard (negative -> 0), (positive -> 1)
		V_sync_polarity: std_logic:= '0'			--  depends on standard (negative -> 0), (positive -> 1)
	);
		
-------------------------------------------
--		Debug code 
--
--		H_back_porch: 	positive:=4;--48; 	
--		H_display: 		positive:=10;--640; 
--		H_front_porch: positive:=2;--16; 	
--		H_retrace: 		positive:=9;--96; 	
--		V_back_porch: 	positive:=3;--33; 	
--		V_display: 		positive:=4;--480; 
--		V_front_porch: positive:=1;--10; 
--		V_retrace: 		positive:=2;--2;
--		Color_bits:		positive:=4	
-------------------------------------------
	
	port(
      -- clock and reset - vid_clk is the appropriate video clock
		-- vid_clk would be 25MHz for a 640 x 480 display
		vid_clk: 		in std_logic;
		reset: 			in std_logic;
		-- standard video sync signals
		h_sync:			out std_logic;
		v_sync:			out std_logic;
 		--  X and Y values for current pixel location being written to the screen
		--  Can be used for reference in upper levels of design
		pixel_x: 		out integer := 0;
		pixel_y: 		out integer := 0;
		-- signal to indicate display is actively being written
		-- use this to set RGB values to 0 when not on an active part of the screen
		-- ** not used if using the RGB in/out synchronous signals
		vid_display:	out std_logic	:= '0';
		-- convenience signals
		-- syncronize rgb outputs to vid_clk
		red_in:     in std_logic_vector((Color_bits - 1) downto 0);
		green_in:	in	std_logic_vector((Color_bits - 1) downto 0);
		blue_in:		in	std_logic_vector((Color_bits - 1) downto 0);
		red_out:			out	std_logic_vector((Color_bits - 1) downto 0) := (others => '0');
		green_out:		out	std_logic_vector((Color_bits - 1) downto 0) := (others => '0');
		blue_out:		out	std_logic_vector((Color_bits - 1) downto 0) := (others => '0')
  );
end;

architecture behavioral of driver_vga is
	--
   -- Counter signals
	--
	signal h_count:		unsigned(H_counter_size - 1 downto 0);
	signal h_count_next: 	unsigned(H_counter_size - 1 downto 0);
	signal v_count:		unsigned(V_counter_size - 1 downto 0);
	signal v_count_next: 	unsigned(V_counter_size - 1 downto 0);
   --
	-- Display signals
	--
	signal v_display_on:	std_logic	:= '0';
	signal h_display_on:	std_logic	:= '0';
	signal display_on:	std_logic	:= '0';
	--
	-- Convenience signals (RGB buffering)
	--
	signal red: 	std_logic_vector((Color_bits - 1) downto 0);
	signal green: 	std_logic_vector((Color_bits - 1) downto 0);
	signal blue: 	std_logic_vector((Color_bits - 1) downto 0);
	
begin
	--
	--	 counter logic
	--
	process (h_count, v_count)
	begin
		--
		--		Horizontal counter
		--
		if (h_count >= (H_back_porch + H_display + H_front_porch + H_retrace - 1)) then
			h_count_next <= (others => '0');
		else
			h_count_next <= h_count + 1;
		end if;
		--
		--		Horizontal Sync
		--
		if ((h_count >= (H_back_porch + H_display + H_front_porch)) and 
							(h_count <= (H_back_porch + H_display + H_front_porch + H_retrace))) then
			h_sync <= H_sync_polarity;
		else
			h_sync <= not(H_sync_polarity);
		end if;
		--
		--		Horizontal display on
		--
		if ((h_count >= (H_back_porch)) and (h_count <= (H_back_porch + H_display - 1))) then
			h_display_on <= '1';
		else
			h_display_on <= '0';
		end if;
		--
		--		Vertical counter
		--
		--		Must also wait for the end of the horizontal counter
		--		to get all the way to the lower right
		--
		if ((v_count >= (V_back_porch + V_display + V_front_porch + V_retrace - 1)) and 
							(h_count >= (H_back_porch + H_display + H_front_porch + H_retrace -1))) then
			v_count_next <= (others => '0');
		elsif (h_count >= (H_back_porch + H_display + H_front_porch + H_retrace -1)) then
			v_count_next <= v_count + 1;
		else 
			v_count_next <= v_count;
		end if;
		--
		--		Vertical Sync
		--
		if ((v_count >= (V_back_porch + V_display + V_front_porch)) and 
							(v_count <= (V_back_porch + V_display + V_front_porch + V_retrace))) then
			v_sync <= V_sync_polarity;
		else
			v_sync <= not(V_sync_polarity);
		end if;
		--
		--		Vertical display on
		--
		if ((v_count >= (V_back_porch)) and (v_count <= (V_back_porch + V_display - 1))) then
			v_display_on <= '1';
		else
			v_display_on <= '0';
		end if;
	end process;
	--
	--		Combined display on
	--	
	display_on <= h_display_on AND v_display_on;

		
	----------------
	--  Synchronous update section 
	----------------
	process (vid_clk, reset)
   begin
      if reset='0' then
         v_count <= (others=>'0');
         h_count <= (others=>'0');
      elsif (vid_clk'event and vid_clk='1') then
         v_count <= v_count_next;
         h_count <= h_count_next;
			--RGB syncronizer
			red <= red_in;
			green <= green_in;
			blue <= blue_in;
      end if;
   end process;
	
	-----------------
	--  Output section
	-----------------
	--
	-- alternate signal to control RGB values externally
	-- not used if the RGB syncronizer is used
	--
	vid_display <= display_on;
	--
	--	pixel values range from 0 to ((display size) -1)
	-- if display is off, pixel values are set to (display size)
	-- eg x might range from 0 to 799 with x = 800 when the display is off
	--
	pixel_x <= (to_integer(h_count) - H_back_porch) when (h_display_on = '1') else
				   H_display;
	pixel_y <= (to_integer(v_count) - V_back_porch) when (v_display_on = '1') else
					V_display;
	--
	-- RGB helper to turn off RGB when display is not in the active area of the screen
	--
	red_out <= red when (display_on = '1') else 
					(others => '0');
	green_out <= green when (display_on = '1') else 
					(others => '0');
	blue_out <= blue when (display_on = '1') else 
					(others => '0');
					
end architecture;