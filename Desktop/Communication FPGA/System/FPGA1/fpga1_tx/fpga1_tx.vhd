library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fpga1_tx is
	port(clk,rst:		in std_logic;
 		
		--From ADC
		data_out_adc:	 in std_logic_vector(255 downto 0);
		expo_adc: 	  	 in std_logic_vector(3 downto 0);
		valid_out_adc:  in std_logic;
		mac_addr_fpga1: in std_logic_vector(47 downto 0);
		
		--To MAC Unit
		sop_tx_mac:		 out std_logic;
		data_tx_mac:	 out std_logic_vector(31 downto 0);
		eop_tx_mac:		 out std_logic;
		valid_out:		 out std_logic;
		
		--From Rx Unit to Tx Unit
		valid_arp: 		 in  std_logic;--arp reply recieved
		ip_dest2_arp:   in  std_logic_vector(31 downto 0);
		mac_dest2_arp:	 in  std_logic_vector(47 downto 0);
	
		ping_valid:		 in  std_logic;--ping recieved
		seq_counter:	 in  std_logic_vector(15 downto 0);
		
		stop_valid:		 in  std_logic;--stop recieved
		start_valid:	 in  std_logic;--start recieved
		
		dhcp_o_valid:	 in std_logic;
		dhcp_server_mac:in std_logic_vector(47 downto 0);
		dhcp_server_ip: in std_logic_vector(31 downto 0);
		dhcp_a_valid:	 in std_logic;
		ip_addr_fpga1_dhcp:in	  std_logic_vector(31 downto 0);
		lease_time:   	 in std_logic_vector(31 downto 0)
		
		);
end fpga1_tx;

architecture Behavioral of fpga1_tx is

--UDP to IP
signal sop_tx_ip_udp:  std_logic;
signal data_tx_ip_udp: std_logic_vector(15 downto 0);
signal eop_tx_ip_udp:  std_logic;


--IP to ethernet
signal sop_tx_ip_ether: std_logic;
signal data_tx_ip_ether: std_logic_vector(15 downto 0);
signal eop_tx_ip_ether: std_logic;

signal w_addr_udp:unsigned(10 downto 0);


begin
udp_uut : entity work.udp 
	port map (clk=>clk,rst=>rst,data_out_adc=>data_out_adc,expo_adc=>expo_adc,valid_out_adc=>valid_out_adc,
				sop_tx_ip=>sop_tx_ip_udp,data_tx_ip=>data_tx_ip_udp,eop_tx_ip=>eop_tx_ip_udp,
				w_addr_udp=>w_addr_udp
				);
ip_uut : entity work.ip 
	port map (clk=>clk,rst=>rst,sop_tx_udp=>sop_tx_ip_udp,data_tx_udp=>data_tx_ip_udp,eop_tx_udp=>eop_tx_ip_udp,
				sop_tx_ether=>sop_tx_ip_ether, data_tx_ether=>data_tx_ip_ether,eop_tx_ether=>eop_tx_ip_ether
				);
ether_uut : entity work.ethernet1
	port map (
				clk=>clk,rst=>rst,sop_tx_ip=>sop_tx_ip_ether,data_tx_ip=>data_tx_ip_ether,
				eop_tx_ip=>eop_tx_ip_ether,sop_tx_mac=>sop_tx_mac,data_tx_mac=>data_tx_mac,
				eop_tx_mac=>eop_tx_mac,valid_out=>valid_out,w_addr_udp=>w_addr_udp,
				mac_addr_fpga1=>mac_addr_fpga1,
			
				valid_arp=>valid_arp,ip_dest2_arp=>ip_dest2_arp,mac_dest2_arp=>mac_dest2_arp,
			
				ping_valid=>ping_valid,seq_counter=>seq_counter,
			
				stop_valid=>stop_valid,start_valid=>start_valid,
				
				dhcp_o_valid=>dhcp_o_valid,dhcp_server_mac=>dhcp_server_mac,
				dhcp_server_ip=>dhcp_server_ip,dhcp_a_valid=>dhcp_a_valid,
				ip_addr_fpga1_dhcp=>ip_addr_fpga1_dhcp,lease_time=>lease_time
				);

end Behavioral;

