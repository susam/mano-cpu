library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity microprocessor is
	port
	(
		reset 	:in std_logic;				-- reset
		clk 	:in std_logic;				-- clock
		data 	:inout std_logic_vector(15 downto 0);	-- data lines
		address :out std_logic_vector(11 downto 0);	-- address lines
		memr	:out std_logic;				-- memory read
		memw 	:out std_logic;				-- memory write
		inport 	:in std_logic_vector(7 downto 0);		-- input port
		outport 	:out std_logic_vector(7 downto 0);	-- output port
		intr_in	:in std_logic;				-- interrupt for input
		intr_out	:in std_logic				-- interrupt for output
	);
end microprocessor;

architecture main of microprocessor is
					-- list of registers
	signal dr	:std_logic_vector(15 downto 0);	-- data register
	signal ar 	:std_logic_vector(11 downto 0);	-- address register
	signal ac	:std_logic_vector(15 downto 0);	-- accumulator
	signal ir		:std_logic_vector(15 downto 0);	-- instruction register
	signal pc	:std_logic_vector(11 downto 0);	-- program counter
	signal tr		:std_logic_vector(15 downto 0);	-- temporary register
	signal inpr	:std_logic_vector(7 downto 0);	-- input register
	signal outr	:std_logic_vector(7 downto 0);	-- output register

					-- internals of microprocessor
	signal d		:std_logic_vector(7 downto 0);	-- instruction decoder output
	signal sc	:std_logic_vector(3 downto 0);	-- sequence counter output
	signal t		:std_logic_vector(15 downto 0);	-- timing signals
	signal i 		:std_logic;			-- I bit
	signal e		:std_logic;			-- extended accumulator
	signal s		:std_logic;			-- start-stop flip-flop
	signal en_id	:std_logic;			-- enable signal for instruction decoder
	signal clr_sc	:std_logic;			-- clear signal for sequence counter
	signal fgi	:std_logic;			-- input flag
	signal fgo	:std_logic;			-- output flag
	signal ien	:std_logic;			-- interrupt enable flip-flop
	signal r		:std_logic;			-- interrupt flip-flop



	begin
	process(en_id)			-- instruction decoder
		begin
		if en_id='1' then
			case ir(14 downto 12) is
				when "000" => d <= "00000001";
				when "001" => d <= "00000010";
				when "010" => d <= "00000100";
				when "011" => d <= "00001000";
				when "100" => d <= "00010000";
				when "101" => d <= "00100000";
				when "110" => d <= "01000000";
				when "111" => d <= "10000000";
				when others => null;
			end case;
		end if;
	end process;

	process(clk,s,clr_sc,inr_sc)		-- 4-bit sequence counter
		begin
		if s='0' then
			if (clk'event and clk='1') then
				if clr_sc='1' then
					sc <= "0000";
				else
					sc <= sc + "0001";
				end if;
	  		end if;
		end if;
	end process;

	process(sc, reset)			-- 4-to-16 decoder to generate timing signals
		begin
		if reset='1' then
			t <= "0000000000000000";
		else
		case sc is
				when "0000" => t <= "0000000000000001";
				when "0001" => t <= "0000000000000010";
				when "0010" => t <= "0000000000000100";
			when "0011" => t <= "0000000000001000";
				when "0100" => t <= "0000000000010000";
				when "0101" => t <= "0000000000100000";
			when "0110" => t <= "0000000001000000";
				when "0111" => t <= "0000000010000000";
				when "1000" => t <= "0000000100000000";
				when "1001" => t <= "0000001000000000";
			when "1010" => t <= "0000010000000000";
				when "1011" => t <= "0000100000000000";
				when "1100" => t <= "0001000000000000";
				when "1101" => t <= "0010000000000000";
			when "1110" => t <= "0100000000000000";
				when "1111" => t <= "1000000000000000";
				when others => null;
		end case;
		end if;
	end process;


	process(t)			-- control unit
		variable temp 	:std_logic;
		variable sum	:std_logic_vector(16 downto 0);
		variable ac_ext	:std_logic_vector(16 downto 0);
		variable dr_ext	:std_logic_vector(16 downto 0);
		begin
		if reset='1' then				-- reset microprocessor
			clr_sc <= '1';
			s <= '0';
			r <= '0';
			ien <= '0';
			fgi <= '0';
			fgo <= '0';
			memr <= '0';
			memw <= '0';
			en_id <= '0';
			pc <= "000000000000";
		elsif ((not r) and t(0))='1' then		-- load 'ar' with the contents of 'pc'
			clr_sc <= '0';
			memr <= '1';
			memw <= '0';
			ar <= pc;
		elsif ((not r) and t(1))='1' then		-- fetch instruction and increment 'pc'
		   	ir <= data;
			pc <= pc + 1;
		elsif ((not r) and t(2))='1' then		-- decode opcode
			fgi <= intr_in;
			fgo <= intr_out;
			memr <= '0';
			en_id <= '1';
			ar <= ir(11 downto 0);
			i <= ir(15);
		elsif (r and t(0))='1' then			-- store return address in tr
			clr_sc <= '0';
			ar <= "000000000000";
			tr <= "0000" & pc;
		elsif (r and t(1))='1' then			-- store return address in location 0
			data <= tr;
			memw <= '1';
			pc <= "000000000000";
		elsif(r and t(2))='1' then			-- increment pc, and reset ien and r
			pc <= pc + 1;
			ien <= '0';
			r <= '0';
			clr_sc <= '1';
	  	elsif t(3)='1' then
			fgi <= intr_in;
			fgo <= intr_out;
			r <= ien and (fgi or fgo);
			en_id <= '0';
			if  (d(7) and i)='1' then		-- execute i/o instruction
				if ir(11)='1' then			-- INP	(input character)
					ac(7 downto 0) <= inpr;
					fgi <= '0';
				elsif ir(10)='1' then		-- OUT	(output character)
					outr <= ac(7 downto 0);
					fgo <= '0';
				elsif ir(9)='1' then		-- SKI	(skip on input flag)
					if fgi='1' then
						pc <= pc + 1;
					end if;
				elsif ir(8)='1' then		-- SKO	(skip on output flag)
					if fgo='1' then
						pc <= pc + 1;
					end if;
				elsif ir(7)='1' then		-- ION	(interrupt enable on)
					ien <= '1';
				elsif ir(6)='0' then		-- IOF	(interrupt enable off)
					ien <= '0';
				end if;
				clr_sc <= '1';
			elsif (d(7) and (not i))='1' then	-- execute register reference instruction
				if ir(11)='1' then			--  CLA	(clear ac)
					ac <= "0000000000000000";
			  	elsif ir(10)='1' then		-- CLE	(clear e)
					e <= '0';
			  	elsif ir(9)='1' then		-- CMA	(complement ac)
 			   		ac <= not ac;
			  	elsif ir(8)='1' then		-- CME	(complement e)
					e <= not e;
				elsif ir(7)='1' then		-- CIR	(cirulate right)
					temp := e;
					e <= ac(0);
					ac <= temp & ac(15 downto 1);
			 	elsif ir(6)='1' then		-- CIL	(circulate left)
					temp := e;
					e <= ac(15);
					ac <= ac(14 downto 0) & temp;
			  	elsif ir(5)='1' then		-- INC	(increment ac)
					ac <= ac + 1;
				elsif ir(4)='1' then		-- SPA	(skip if positive)
					if ac(15)='0' then
						pc <= pc + 1;
				  	end if;
				elsif ir(3)='1' then		-- SNA	(skip if negative)
					if ac(15)='1' then
						pc <= pc + 1;
					end if;
			  	elsif ir(2)='1' then		-- SZA	(skip if ac is zero)
					if ac=0 then
						pc <= pc + 1;
					end if;
			  	elsif ir(1)='1' then		-- SZE	(skip if e is zero)
					if e='0' then
						pc <= pc + 1;
					end if;
				elsif ir(0)='1' then		-- HLT	(halt)
					s <= '1';
				end if;
				clr_sc <= '1';
	  		elsif (not d(7))='1' then
				if i='1' then	-- fetch address for indirect addressing mode
 	   				memr <= '1';
				elsif i='0' then	-- do nothing for direct addressing mode
					null;
				end if;
			end if;


		elsif t(4)='1' then
			fgi <= intr_in;
			fgo <= intr_out;
			r <= ien and (fgi or fgo);
			if d(7)='1' then
				if i='1' then	-- fetch address for indirect addressing mode

ar <= data(11 downto 0);				elsif i='0' then
					null;	-- do nothing for direct addressing mode
				end if;
			end if;
		elsif t(5)='1' then
			fgi <= intr_in;
			fgo <= intr_out;
			r <= ien and (fgi or fgo);
			if d(0)='1' then			-- AND (and to ac)
				memr <= '1';
			elsif d(1)='1' then		-- ADD (add to ac)
				memr <= '1';
			elsif d(2)='1' then		--  LDA (load to ac)
				memr <= '1';
			elsif d(3)='1' then		-- STA (store ac)
				data <= ac;
				memw <= '1';
				clr_sc <= '1';
			elsif d(4)='1' then		-- BUN (branch unconditionally)
				pc <= ar;
                                               	clr_sc <= '1';
			elsif d(5)='1' then		-- BSA (branch and save return address)
				data <= "0000" & pc;
				memw <= '1';
				ar <= ar + 1;
			elsif d(6)='1' then		-- ISZ (increment and skip if zero)
				memr <= '1';
			end if;
		elsif t(6)='1' then
			fgi <= intr_in;
			fgo <= intr_out;
			r <= ien and (fgi or fgo);
					-- memory read for AND, ADD, LDA and ISZ instructions
			if (d(0) or d(1) or d(2) or d(6)) = '1' then
				dr <= data;
			elsif d(5)='1' then		-- BSA (branch and save return address)
				memw <= '0';
				pc <= ar;
				clr_sc <= '1';
			end if;
		elsif t(7)='1' then
			fgi <= intr_in;
			fgo <= intr_out;
			r <= ien and (fgi or fgo);
			if d(0)='1' then			-- AND (and to ac)
				memr <= '0';
				ac <= ac and dr;
                                                	clr_sc <= '1';
			elsif d(1)='1' then		-- ADD (add to ac)
				memr <= '0';
				ac_ext := '0' & ac;
				dr_ext := '0' & dr;
				sum := ac_ext + dr_ext;
				ac <= sum(15 downto 0);
				e <= sum(16);
                                                	clr_sc <= '1';
			elsif d(2)='1' then		--  LDA (load to ac)
				memr <= '0';
				ac <= dr;
				clr_sc <= '1';
			elsif d(6)='1' then		-- ISZ (increment and skip if zero)
				memr <= '0';
				dr <= dr + 1;
			end if;
		elsif t(8)='1' then
			fgi <= intr_in;
			fgo <= intr_out;
			r <= ien and (fgi or fgo);
			if d(6)='1' then			-- ISZ (increment and skip if zero)
				data <= dr;
				memw <= '1';
				if dr=0 then
					pc <= pc + 1;
				end if;
                                                	clr_sc <= '1';
			end if;
		end if;
	end process;

	inpr <= inport;
	outport <= outr;
	address <= ar;
end main;
