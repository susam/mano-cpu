library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity ram is
	port(en, r, w 	:in std_logic;
	data 		:inout std_logic_vector(15 downto 0);
	address 		:in std_logic_vector(2 downto 0));
end ram;

architecture main of ram is
	type word_vector is array(integer range <>) of std_logic_vector(15 downto 0);
	signal memory :word_vector(7 downto 0);
	signal enreg :std_logic_vector(7 downto 0);
	begin
	process(address)			-- instruction decoder
		begin
		if en='1' then
			if address = 0 then
				enreg <= "00000001";
			elsif address = 1 then
				enreg <= "00000010";
			elsif address = 2 then
				enreg <= "00000100";
			elsif address = 3 then
				enreg <= "00001000";
			elsif address = 4 then
				enreg <= "00010000";
			elsif address = 5 then
				enreg <= "00100000";
			elsif address = 6 then
				enreg <= "01000000";
			elsif address = 7 then
				enreg <= "10000000";
			end if;
		end if;
	end process;
	process(r,w)
		begin
		if en='1' then
			if enreg(0)='1' and r='1' then
				data <= memory(0);
			elsif enreg(0)='1' and w='1' then
				memory(0) <= data;
			end if;

			if enreg(1)='1' and r='1' then
				data <= memory(1);
			elsif enreg(1)='1' and w='1' then
				memory(1) <= data;
			end if;

			if enreg(2)='1' and r='1' then
				data <= memory(2);
			elsif enreg(2)='1' and w='1' then
				memory(2) <= data;
			end if;

			if enreg(3)='1' and r='1' then
				data <= memory(3);
			elsif enreg(3)='1' and w='1' then
				memory(3) <= data;
			end if;

			if enreg(4)='1' and r='1' then
				data <= memory(4);
			elsif enreg(4)='1' and w='1' then
				memory(4) <= data;
			end if;

			if enreg(5)='1' and r='1' then
				data <= memory(5);
			elsif enreg(5)='1' and w='1' then
				memory(5) <= data;
			end if;

			if enreg(6)='1' and r='1' then
				data <= memory(6);
			elsif enreg(6)='1' and w='1' then
				memory(6) <= data;
			end if;

			if enreg(7)='1' and r='1' then
				data <= memory(7);
			elsif enreg(7)='1' and w='1' then
				memory(7) <= data;
			end if;
		end if;
	end process;
end main;
