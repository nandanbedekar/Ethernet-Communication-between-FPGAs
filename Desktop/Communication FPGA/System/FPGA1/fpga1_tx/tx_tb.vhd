library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use IEEE.std_logic_textio.all;

entity tx_tb is
end tx_tb;

architecture Behavioral of tx_tb is
signal		clk,rst: 	  std_logic;
signal		data_out_adc: std_logic_vector(255 downto 0);
signal		expo_adc: 	  std_logic_vector(3 downto 0);
signal		valid_out_adc:std_logic;
signal		mac_addr_fpga1:std_logic_vector(47 downto 0);
		
signal		sop_tx_mac: std_logic;
signal		data_tx_mac:std_logic_vector(31 downto 0);
signal		eop_tx_mac: std_logic;
signal		valid_out: std_logic;

signal		data_out_incr: unsigned(255 downto 0);

--Rx Unit to Tx
signal valid_arp:    std_logic;--arp reply recieved
signal ip_dest2_arp:     std_logic_vector(31 downto 0);
signal mac_dest2_arp:  	std_logic_vector(47 downto 0);
	
signal ping_valid:	std_logic;--ping recieved
signal seq_counter:  std_logic_vector(15 downto 0);
		
signal stop_valid:	std_logic;--stop recieved
signal start_valid:	std_logic;--start recieved

signal dhcp_o_valid:	  std_logic;
signal dhcp_server_mac:std_logic_vector(47 downto 0);
signal dhcp_server_ip: std_logic_vector(31 downto 0);
signal dhcp_a_valid:   std_logic;
signal ip_addr_fpga1_dhcp:  std_logic_vector(31 downto 0);
signal lease_time:  	  std_logic_vector(31 downto 0);


begin
	uut_fpga1: entity work.fpga1
	port map(clk=>clk,rst=>rst,data_out_adc=>data_out_adc,expo_adc=>expo_adc,
				mac_addr_fpga1=>mac_addr_fpga1,
				valid_out_adc=>valid_out_adc,sop_tx_mac=>sop_tx_mac,
				data_tx_mac=>data_tx_mac,eop_tx_mac=>eop_tx_mac,valid_out=>valid_out,
				valid_arp=>valid_arp,ip_dest2_arp=>ip_dest2_arp,mac_dest2_arp=>mac_dest2_arp,ping_valid=>ping_valid,
				seq_counter=>seq_counter,stop_valid=>stop_valid,start_valid=>start_valid,
				
				dhcp_o_valid=>dhcp_o_valid,dhcp_server_mac=>dhcp_server_mac,
				dhcp_server_ip=>dhcp_server_ip,dhcp_a_valid=>dhcp_a_valid,
				ip_addr_fpga1_dhcp=>ip_addr_fpga1_dhcp,lease_time=>lease_time
		     );
				
	process
		begin
		clk<='0'; wait for 10 ns;
		clk<='1'; wait for 10 ns;
	end process;
	
	--sending data to ADC
	process
		begin
		rst<='1';data_out_adc<=(others=>'0');expo_adc<="0000";data_out_incr<=(others=>'1');
		wait until rising_edge(clk);data_out_incr<=data_out_incr-1000;wait until rising_edge(clk); wait until rising_edge(clk);wait until rising_edge(clk);
		mac_addr_fpga1<=x"1aef93b4c001";
		
		rst<='0';
		data_out_adc<=(others=>'0');expo_adc<="0000";
		data_out_incr<=data_out_incr+1;
		valid_out_adc<='1';
		
		for j in 0 to 50000 loop
				for i in 0 to 62 loop
					wait until rising_edge(clk);
					valid_out_adc<='0';
				end loop;
				wait until rising_edge(clk);
				data_out_adc<=std_logic_vector(data_out_incr);
				data_out_incr<=data_out_incr+1;valid_out_adc<='1';
		end loop;
	end process;
	
	--Managing Rx's Response
	process
		begin
		valid_arp<='0' ; ping_valid<='0';dhcp_o_valid<='0';
		stop_valid<='0'; start_valid<='0';dhcp_a_valid<='0';
		
		wait until rising_edge(clk);
		for i in 0 to 900 loop
			wait until rising_edge(clk);
		end loop;
		
		dhcp_o_valid<='1';
		wait until rising_edge(clk);
		dhcp_o_valid<='0';
		
		for i in 0 to 900 loop
			wait until rising_edge(clk);
		end loop;
		
		dhcp_a_valid<='1';
		wait until rising_edge(clk);
		dhcp_a_valid<='0';
		
		for i in 0 to 900 loop
			wait until rising_edge(clk);
		end loop;
		
		valid_arp<='1';ip_dest2_arp<=x"c0a80102";mac_dest2_arp<=x"1aef93b4c002";
		wait until rising_edge(clk);
		valid_arp<='0';
		
		for i in 0 to 900 loop
		wait until rising_edge(clk);
		end loop;
		
			ping_valid<='1';seq_counter<="000000000000001"&"0";
			wait until rising_edge(clk);
			ping_valid<='0';
				

		for i in 0 to 900 loop
		wait until rising_edge(clk);
		end loop;
		
		stop_valid<='1';
		wait until rising_edge(clk);
		stop_valid<='0';
				

		for i in 0 to 900 loop
		wait until rising_edge(clk);
		end loop;
		
		start_valid<='1';
		wait until rising_edge(clk);
		start_valid<='0';
				

		for i in 0 to 15 loop
		wait until rising_edge(clk);
		end loop;
		
	end process;
	
	
	--writing to file
	process
	file  output_file : text is out "output_cases_vhdl.txt";
		variable line_putting: line;
		variable data_give: std_logic_vector(31 downto 0);
	begin
		for i in 0 to 62000 loop
		wait until rising_edge(clk);
					if valid_out='1' then
								if data_tx_mac="01010101010101010101010101010101" then
								data_give:="--------------------------------";
								write(line_putting,data_give);
								writeline(output_file,line_putting);
								end if;
								data_give:=data_tx_mac;
								write(line_putting,data_give);
								writeline(output_file,line_putting);
					end if;	
		end loop;
		
	
	end process;


end Behavioral;

