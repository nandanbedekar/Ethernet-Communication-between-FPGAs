library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity ether2_tb is
end ether2_tb;

architecture Behavioral of ether2_tb is

signal	clk,rst: std_logic;
		
		--Rx unit to Tx unit ETHER
signal		valid_arp: std_logic;
signal		ip_dest1: std_logic_vector(31 downto 0);
signal		mac_dest1: std_logic_vector(47 downto 0);

signal		pingit: std_logic;--exclusive in 2--

signal		ping_valid:  std_logic;
signal		seq_counter: std_logic_vector(15 downto 0);
				
signal		stop_valid: std_logic;
signal		start_valid: std_logic;		


		--buffer to ether

signal		stopit,startit: std_logic;
		
		--ether to mac
signal		sop_tx_mac: std_logic;
signal		data_tx_mac: std_logic_vector(31 downto 0);
signal		eop_tx_mac: std_logic;
signal		valid_out: std_logic;

		--Rx to Tx DHCP
signal		dhcp_o_valid:		std_logic;
signal		dhcp_server_mac:	std_logic_vector(47 downto 0);
signal		dhcp_server_ip:	std_logic_vector(31 downto 0);
signal		dhcp_a_valid:		std_logic;
signal		ip_addr_fpga1:		std_logic_vector(31 downto 0);
signal		lease_time:			std_logic_vector(31 downto 0);

begin
ether2 : entity work.ether2a_tx
port map(
			clk=>clk,rst=>rst,
			sop_tx_mac=>sop_tx_mac,data_tx_mac=>data_tx_mac,eop_tx_mac=>eop_tx_mac,valid_out=>valid_out,
			
			valid_arp=>valid_arp,ip_dest1=>ip_dest1,mac_dest1=>mac_dest1,
			
			ping_valid=>ping_valid,seq_counter=>seq_counter,
			
			pingit=>pingit,stopit=>stopit,stop_valid=>stop_valid,startit=>startit,start_valid=>start_valid,
			
			dhcp_o_valid=>dhcp_o_valid,dhcp_server_mac=>dhcp_server_mac,
			dhcp_server_ip=>dhcp_server_ip,dhcp_a_valid=>dhcp_a_valid,
			ip_addr_fpga1=>ip_addr_fpga1,lease_time=>lease_time
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
	wait until rising_edge(clk);
	rst<='0';valid_arp<='0';	ip_dest1<=(others=>'0');					mac_dest1<=(others=>'0');
	ping_valid<='0';				seq_counter<=(others=>'0');				pingit<='0';stopit<='0';
	stop_valid<='0';				startit<='0';start_valid<='0';
	dhcp_o_valid<='0';			dhcp_server_mac<=x"ffaabbcceedd";		dhcp_server_ip<=x"00220022";
	dhcp_a_valid<='0';			ip_addr_fpga1<=x"00330033";				lease_time<=x"11223344";
	
	
	
	for j in 0 to 10 loop
	wait until rising_edge(clk);wait until rising_edge(clk);
	wait until rising_edge(clk);wait until rising_edge(clk);
	wait until rising_edge(clk);
	
	if j=0 then 
		for i in 0 to 750 loop
		wait until rising_edge(clk);
		end loop;
		dhcp_o_valid<='1';
		wait until rising_edge(clk);
		dhcp_o_valid<='0';
	
	elsif j=1 then
		for i in 0 to 750 loop
		wait until rising_edge(clk);
		end loop;
		dhcp_a_valid<='1';
		wait until rising_edge(clk);
		dhcp_a_valid<='0';
	elsif j=2 then
		for i in 0 to 750 loop
		wait until rising_edge(clk);
		end loop;
		valid_arp<='1';ip_dest1<=x"fabdbdaf";mac_dest1<=x"abcdeffedcba";
		wait until rising_edge(clk);
		valid_arp<='0';
		for i in 0 to 750 loop
		wait until rising_edge(clk);
		end loop;

	
	elsif j=3 then
		pingit<='1';
		wait until rising_edge(clk);
		pingit<='0';
		for i in 0 to 7500 loop
		wait until rising_edge(clk);
		end loop;
	elsif j=4 then
		ping_valid<='1';
		wait until rising_edge(clk);
		ping_valid<='0';
		for i in 0 to 750 loop
		wait until rising_edge(clk);
		end loop;
		
	elsif j=5 then
		stopit<='1';
		wait until rising_edge(clk);
		stopit<='0';
		for i in 0 to 750 loop
		wait until rising_edge(clk);
		end loop;
	elsif j=6 then
		stop_valid<='1';
		wait until rising_edge(clk);
		stop_valid<='0';
		for i in 0 to 750 loop
		wait until rising_edge(clk);
		end loop;
	
	elsif j=7 then
		startit<='1';
		wait until rising_edge(clk);
		startit<='0';
		for i in 0 to 750 loop
		wait until rising_edge(clk);
		end loop;
	elsif j=8 then
		start_valid<='1';
		wait until rising_edge(clk);
		start_valid<='0';
		for i in 0 to 3000 loop
		wait until rising_edge(clk);
		end loop;
	elsif j=9 then
		stopit<='1';
		wait until rising_edge(clk);
		stopit<='0';
		for i in 0 to 750 loop
		wait until rising_edge(clk);
		end loop;
	elsif j=10 then
		stop_valid<='1';
		wait until rising_edge(clk);
		stop_valid<='0';
		for i in 0 to 7500 loop
		wait until rising_edge(clk);
		end loop;
	
	end if;
	end loop;
	
	
end process;



end Behavioral;

