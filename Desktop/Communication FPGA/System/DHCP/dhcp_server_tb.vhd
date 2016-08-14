library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use IEEE.std_logic_textio.all;

entity dhcp_tb is
end dhcp_tb;

architecture Behavioral of dhcp_tb is
signal clk,rst						: 	std_logic;
signal mac_addr_dhcp_server	:	std_logic_vector(47 downto 0);
signal ip_addr_dhcp_server		:	std_logic_vector(31 downto 0);

signal sop_in						: 	std_logic;
signal data_in						: 	std_logic_vector(31 downto 0);
signal eop_in						:	std_logic;
signal valid_data_in				:	std_logic;
		
signal sop_out						:	std_logic;
signal data_out					:	std_logic_vector(31 downto 0);
signal eop_out						:	std_logic;
signal valid_out					:  std_logic;

signal ip_addr_fpga1				:  std_logic_vector(31 downto 0);
signal ip_addr_fpga2				: 	std_logic_vector(31 downto 0);
signal mac_addr_fpga2			: 	std_logic_vector(47 downto 0);
signal mac_addr_fpga1			: 	std_logic_vector(47 downto 0);		

signal lease_time					:	std_logic_vector(31 downto 0);

begin
	dhcp_server : entity work.dhcp_server
	port map (
				clk=>clk, rst=>rst, sop_in=>sop_in,data_in=>data_in,eop_in=>eop_in,
				valid_data_in=>valid_data_in,sop_out=>sop_out,data_out=>data_out,
				eop_out=>eop_out,valid_out=>valid_out,mac_addr_dhcp_server=>mac_addr_dhcp_server,
				ip_addr_dhcp_server=>ip_addr_dhcp_server,
				ip_addr_fpga1=>ip_addr_fpga1,ip_addr_fpga2=>ip_addr_fpga2,
				mac_addr_fpga1=>mac_addr_fpga1,mac_addr_fpga2=>mac_addr_fpga2,
				lease_time=>lease_time
				);

	process
		begin
		clk<='0'; wait for 10 ns;
		clk<='1'; wait for 10 ns;
	end process;
	
	
	
	process
	begin
	rst<='1';
	wait until rising_edge(clk);
	rst<='0';ip_addr_dhcp_server<=x"c0a80100";mac_addr_dhcp_server<=x"1aef93b4c000";
	ip_addr_fpga1<=x"c0a80101";ip_addr_fpga2<=x"c0a80102";--192.168.1.1/2
	mac_addr_fpga1<=x"1aef93b4c001";mac_addr_fpga2<=x"1aef93b4c002";lease_time<=x"000fffff";
	for i in 0 to 500000 loop
	wait until rising_edge(clk);
	end loop;
	
	
	
	
	
	end process;












--from FILE to DHCP Rx
process
		file  input_file : text is in  "input_cases_dhcp.txt";
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
										sop_in<='0';
										eop_in<='0';
										valid_data_in<='0';
						
					 elsif char='s' then
										sop_in<='1';
							
										eop_in<='0';
										valid_data_in<='1';
										for i in 0 to 31 loop
											if line_1(i+2) ='0' then
											data_in(31-i)<='0';
											elsif line_1(i+2)='1' then
											data_in(31-i)<='1';
											end if;
										end loop;
										
					 elsif char='d' then
										sop_in<='0';
										
										eop_in<='0';
										valid_data_in<='1';
										for i in 0 to 31 loop
											if line_1(i+2) ='0' then
											data_in(31-i)<='0';
											elsif line_1(i+2)='1' then
											data_in(31-i)<='1';
											end if;
										end loop;
						
					 elsif char='e' then
										sop_in<='0';
										
										eop_in<='1';
										valid_data_in<='1';
										for i in 0 to 31 loop
											if line_1(i+2) ='0' then
											data_in(31-i)<='0';
											elsif line_1(i+2)='1' then
											data_in(31-i)<='1';
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
	process(clk)
		file  output_file : text is out "output_cases_dhcp.txt";
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
				if sop_out='1' then
					char:="s";
					write(output_file,char);
					data_give:=data_out;
					write(line_1,data_give);
					writeline(output_file,line_1);
				elsif eop_out='1' then
					char:="e";
					write(output_file,char);
					data_give:=data_out;
					write(line_1,data_give);
					writeline(output_file,line_1);
				elsif sop_out='0' and eop_out='0' then
					char:="d";
					write(output_file,char);
					data_give:=data_out;
					write(line_1,data_give);
					writeline(output_file,line_1);
				end if;
			end if;
		
		end if;
    end process;















end Behavioral;

