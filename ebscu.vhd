library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ebscu is
	port
	(
		mode:		in std_logic;

		mpdata:	inout std_logic_vector(15 downto 0);
		mpaddress:	in std_logic_vector(11 downto 0);
		userdata:		inout std_logic_vector(15 downto 0);
		useraddress:	in std_logic_vector(2 downto 0);
		ramdata:		inout std_logic_vector(15 downto 0);
		ramaddress:	out std_logic_vector(2 downto 0);

		mpread:		in std_logic;
		mpwrite:		in std_logic;
		userread:		in std_logic;
		userwrite:	in std_logic;
		ramread:		out std_logic;
		ramwrite:		out std_logic
	);
end ebscu;

architecture main of ebscu is
	begin
	process(mpread, mpwrite, userread, userwrite)
		begin
		if mode='0' then
			ramread <= mpread;
			ramwrite <= mpwrite;
			ramaddress <= mpaddress(2 downto 0);
			if mpread='1' then
				mpdata <= ramdata;
			elsif mpwrite='1' then
				ramdata <= mpdata;
			end if;
		elsif mode='1' then
			ramread <= userread;
			ramwrite <= userwrite;
			ramaddress <= useraddress;
			if userread='1' then
				userdata <= ramdata;
			elsif userwrite='1' then
				ramdata <=  userdata;
			end if;
		end if;
	end process;
end main;
