library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FPGA2 is
port	(
		clk, rst: 			in 	std_logic;
		mac_addr_fpga2: 	in 	std_logic_vector(47 downto 0);
		
		
		sop_tx_mac: 		out 	std_logic;
		data_tx_mac: 		out 	std_logic_vector(31 downto 0);
		eop_tx_mac: 		out 	std_logic;
		valid_out: 			out 	std_logic;
		
		sop_rx_mac:			in 	std_logic;
		data_rx_mac:		in		std_logic_vector(31 downto 0);
		eop_rx_mac:			in		std_logic;
		valid_in:			in		std_logic
		
	);
end FPGA2;

architecture Behavioral of FPGA2 is

--Signals for Tx Unit
----Rx unit to Tx unit ETHER
		
signal	ping_valid: 		std_logic;
signal	seq_counter: 		std_logic_vector(15 downto 0);
		
signal	valid_arp:	   	std_logic;
signal	ip_dest1_arp:	   	std_logic_vector(31 downto 0);
signal	mac_dest1_arp: 			std_logic_vector(47 downto 0);
		
signal	stop_valid: 		std_logic;
signal	start_valid: 		std_logic;
		
----buffer to ether
signal	pingit:				std_logic;
signal	stopit:				std_logic;
signal	startit:				std_logic;

		
----Rx to Tx DHCP
signal	dhcp_o_valid:	  std_logic;
signal	dhcp_server_mac: std_logic_vector(47 downto 0);
signal	dhcp_server_ip:  std_logic_vector(31 downto 0);
signal	dhcp_a_valid:	  std_logic;
signal	ip_addr_fpga2_dhcp:	  std_logic_vector(31 downto 0);
signal	lease_time:		  std_logic_vector(31 downto 0);

signal	ping_number:		unsigned(14 downto 0);

--Signals for Rx Unit
signal 	givedataout:	  std_logic;
signal	addressofdata:	  std_logic_vector(23 downto 0);
signal	inthwaddr:		  std_logic_vector(47 downto 0);
signal	intudpport:		  std_logic_vector(15 downto 0);
----buffer
signal	buffervalidout:  std_logic;
signal	bufferdataout:	  std_logic_vector(15 downto 0);
signal	datastarting:	  std_logic_vector(23 downto 0);
signal	dataend:			  std_logic_vector(23 downto 0);
signal	dataend_unsig:	  unsigned(23 downto 0);


begin

rx_unit : entity work.summary2	
port map	(reset=>rst,clock=>clk,
			 
			 validin=>valid_in,sof=>sop_rx_mac,eof=>eop_rx_mac,datain=>data_rx_mac,
			 givedataout=>givedataout,addressofdata=>addressofdata,inthwaddr=>mac_addr_fpga2,
			 intudpport=>intudpport,
			 
			 arpvalidout=>valid_arp,desthwaddr=>mac_dest1_arp,destipaddr=>ip_dest1_arp,
			 startvalid=>start_valid,stopvalid=>stop_valid,sequencevalid=>ping_valid,sequenceno=>seq_counter(15 downto 1),
			 value=>seq_counter(0),
			 
			 dhcpoffer=>dhcp_o_valid,dhcpacknowledge=>dhcp_a_valid,YIAddr=>ip_addr_fpga2_dhcp,
			 SIAddr=>dhcp_server_ip,ipleasetime=>lease_time,sourceaddr=>dhcp_server_mac,
			 
			 buffervalidout=>buffervalidout,bufferdataout=>bufferdataout,datastarting=>datastarting,
			 dataend=>dataend
				
			 );
			 
tx_unit : entity work.ether2a_tx	
port map	(clk=>clk,rst=>rst,
			 
			 ping_valid=>ping_valid,seq_counter=>seq_counter,
			 valid_arp=>valid_arp,ip_dest1_arp=>ip_dest1_arp,mac_dest1_arp=>mac_dest1_arp,stop_valid=>stop_valid,
			 start_valid=>start_valid,pingit=>pingit,stopit=>stopit,startit=>startit,
			 
			 sop_tx_mac=>sop_tx_mac,data_tx_mac=>data_tx_mac,eop_tx_mac=>eop_tx_mac,valid_out=>valid_out,
			 
			 dhcp_o_valid=>dhcp_o_valid,dhcp_server_mac=>dhcp_server_mac,
			 dhcp_server_ip=>dhcp_server_ip,dhcp_a_valid=>dhcp_a_valid,ip_addr_fpga2_dhcp=>ip_addr_fpga2_dhcp,
			 lease_time=>lease_time,mac_addr_fpga2=>mac_addr_fpga2
			 );


	dataend_unsig<=unsigned(dataend);
	process(clk,rst)
	begin
	if rst='1' then
	pingit<='0';stopit<='0';startit<='0';
	elsif rising_edge(clk) then
		pingit<='0';stopit<='0';startit<='0';
		
		if dataend_unsig="000000000000000000000001" then
		pingit<='1';
		end if;

		if dataend_unsig="000000000000110110001010" then
		stopit<='1';
		end if;
		
--		if dataend_unsig>(262144-ping_number*300) then
--		stopit<='1';
--		end if;
	
		
	end if;
	end process;












end Behavioral;

