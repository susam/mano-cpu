library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity divider is
	port(rst,clkin: in std_logic;
	clkout: out std_logic);
end divider;

architecture main of divider is
	begin
	process(clkin)
		variable temp: std_logic_vector(11 downto 0);
		begin
		if rst='1' then
			temp := "000000000000";
		elsif clkin'event and clkin='1' and rst='0' then
			temp := temp + "000000000001";
		end if;
		clkout <= temp(0); --11
	end process;
end main;
