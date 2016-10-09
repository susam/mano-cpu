library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity testbench is
	port
	(
		reset 	:in std_logic;
		clk	:in std_logic;
		mode	:in std_logic;

		inport	:in std_logic_vector(7 downto 0);
		outport	:out std_logic_vector(7 downto 0);

		data	:inout std_logic_vector(15 downto 0);
		address	:in std_logic_vector(2 downto 0);
		load	:in std_logic;
		debug	:in std_logic
	);
end testbench;

architecture main of testbench is
	component divider
		port(rst, clkin: in std_logic;
		clkout: out std_logic);
	end component;
	component ram
		port(en, r, w 	:in std_logic;
		data 		:inout std_logic_vector(15 downto 0);
		address 		:in std_logic_vector(2 downto 0));
	end component;
	component microprocessor
		port
		(
			reset 	:in std_logic;
			clk 	:in std_logic;
			data 	:inout std_logic_vector(15 downto 0);
			address 	:out std_logic_vector(11 downto 0);
			memr	:out std_logic;
			memw 	:out std_logic;
			inport 	:in std_logic_vector(7 downto 0);
			outport 	:out std_logic_vector(7 downto 0)
		);
	end component;
	component ebscu
		port
		(
			mode:		in std_logic;

			mpdata:	inout std_logic_vector(15 downto 0);
			mpaddress:	in std_logic_vector(11 downto 0);
			userdata:		inout std_logic_vector(15 downto 0);
			useraddress:	in std_logic_vector(2 downto 0);
			ramdata:	inout std_logic_vector(15 downto 0);
			ramaddress:	out std_logic_vector(2 downto 0);

			mpread:		in std_logic;
			mpwrite:		in std_logic;
			userread:		in std_logic;
			userwrite:	in std_logic;
			ramread:		out std_logic;
			ramwrite:		out std_logic
		);
	end component;
	signal internclk		:std_logic;
	signal mpreset		:std_logic;
	signal databus1		:std_logic_vector(15 downto 0);
	signal databus2		:std_logic_vector(15 downto 0);
	signal databus3		:std_logic_vector(15 downto 0);
	signal databus4		:std_logic_vector(15 downto 0);
	signal addressbus1	:std_logic_vector(11 downto 0);
	signal addressbus2	:std_logic_vector(2 downto 0);
	signal read1, write1	:std_logic;
	signal read2, write2	:std_logic;

	begin
	mpreset <= reset or mode;
	process(databus1)
		variable busvar: std_logic_vector(15 downto 0);
		begin
		busvar := databus1;
		databus2 <= busvar;
	end process;
	process(databus2)
		variable busvar: std_logic_vector(15 downto 0);
		begin
		busvar := databus2;
		databus1 <= busvar;
	end process;
	process(databus3)
		variable busvar: std_logic_vector(15 downto 0);
		begin
		busvar := databus3;
		databus4 <= busvar;
	end process;
	process(databus4)
		variable busvar: std_logic_vector(15 downto 0);
		begin
		busvar := databus4;
		databus3 <= busvar;
	end process;
	d1: divider 		port map(reset, clk, internclk);
	d2: microprocessor		port map(mpreset, internclk, databus1, addressbus1, read1, write1, inport, outport);
	d3: ebscu		port map(mode, databus2, addressbus1, data, address, databus3, addressbus2, read1, write1, debug, load, read2, write2);
	d4: ram			port map('1', read2, write2, databus4, addressbus2);
end main;
