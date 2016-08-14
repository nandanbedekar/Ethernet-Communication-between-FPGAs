library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use IEEE.std_logic_textio.all;

entity fpga2_tb is
end fpga2_tb;

architecture Behavioral of fpga2_tb is

signal	clk, rst: 		 	std_logic;
signal	mac_addr_fpga2:	std_logic_vector(47 downto 0);

signal	sop_tx_mac: 	 	std_logic;
signal	data_tx_mac: 	 	std_logic_vector(31 downto 0);
signal	eop_tx_mac: 	 	std_logic;
signal	valid_out: 		 	std_logic;
		
signal	sop_rx_mac:		 	std_logic;
signal	data_rx_mac:		std_logic_vector(31 downto 0);
signal	eop_rx_mac:			std_logic;
signal	valid_in:			std_logic; 


begin

fpga2_uut: entity work.FPGA2
port map (
			clk=>clk,rst=>rst,mac_addr_fpga2=>mac_addr_fpga2, sop_tx_mac=>sop_tx_mac, data_tx_mac=>data_tx_mac,
			eop_tx_mac=>eop_tx_mac,valid_out=>valid_out, sop_rx_mac=>sop_rx_mac,data_rx_mac=>data_rx_mac,
			eop_rx_mac=>eop_rx_mac,
			valid_in=>valid_in
			);

	process
		begin
		clk<='0'; wait for 10 ns;
		clk<='1'; wait for 10 ns;
	end process;

	--Managing Rx's Response
	process
		begin
		
		
		rst<='1';mac_addr_fpga2<=x"1aef93b4c002";
		wait until rising_edge(clk);
		rst<='0';wait until rising_edge(clk);
		
		while rst='0' loop
		wait until rising_edge(clk);
		end loop;
		
	end process;
	
	
	
	
	--reading from file into Rx unit
	process
		file  input_file : text is in "input_cases_vhdl.txt";
		variable line_1: line;
		variable data_give: string (32 downto 1);
		variable char : character; 
		variable x: integer:=0;
	begin
		 wait until rising_edge(clk);
		 if x=0 then
		 while not endfile(input_file) loop 
		 
		 readline (input_file,line_1); 
		 char:=line_1(1);
				 if char='v' then
									sop_rx_mac<='0';
									eop_rx_mac<='0';
									valid_in<='0';
					
				 elsif char='s' then
									sop_rx_mac<='1';
						
									eop_rx_mac<='0';
									valid_in<='1';
									for i in 0 to 31 loop
										if line_1(i+2) ='0' then
										data_rx_mac(31-i)<='0';
										elsif line_1(i+2)='1' then
										data_rx_mac(31-i)<='1';
										end if;
									end loop;
									
				 elsif char='d' then
									sop_rx_mac<='0';
									
									eop_rx_mac<='0';
									valid_in<='1';
									for i in 0 to 31 loop
										if line_1(i+2) ='0' then
										data_rx_mac(31-i)<='0';
										elsif line_1(i+2)='1' then
										data_rx_mac(31-i)<='1';
										end if;
									end loop;
					
				 elsif char='e' then
									sop_rx_mac<='0';
									
									eop_rx_mac<='1';
									valid_in<='1';
									for i in 0 to 31 loop
										if line_1(i+2) ='0' then
										data_rx_mac(31-i)<='0';
										elsif line_1(i+2)='1' then
										data_rx_mac(31-i)<='1';
										end if;
									end loop;
				 end if; 
				 wait until rising_edge(clk);
		end loop;
		end if;
			if x=0 then
			file_close(input_file);  --after reading all the lines close the file.  
			x:=1;
			end if;
    end process;
	 
	 



	--writing from Tx unit into File
	--reading from file into Rx unit
	process(clk)
		file  output_file : text is out "output_cases_vhdl.txt";
		variable line_1: line;
		variable data_give: std_logic_vector (31 downto 0);
		variable char : string(1 downto 1); 
		
	begin
		 if rising_edge(clk) then
			
			if valid_out='0' then
				char:="v";
				write(output_file,char);
				writeline(output_file,line_1);
			elsif valid_out='1' then
			
				if sop_tx_mac='1' then
					char:="s";
					write(output_file,char);
					data_give:=data_tx_mac;
					write(line_1,data_give);
					writeline(output_file,line_1);
				elsif eop_tx_mac='1' then
					char:="e";
					write(output_file,char);
					data_give:=data_tx_mac;
					write(line_1,data_give);
					writeline(output_file,line_1);
				elsif sop_tx_mac='0' and eop_tx_mac='0' then
					char:="d";
					write(output_file,char);
					data_give:=data_tx_mac;
					write(line_1,data_give);
					writeline(output_file,line_1);
				end if;
			end if;
		
		end if;
    end process;










end Behavioral;

