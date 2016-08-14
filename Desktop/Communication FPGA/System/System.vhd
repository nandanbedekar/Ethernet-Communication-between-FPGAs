library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity system is
end system;

architecture Behavioral of system is

signal	clk										:	std_logic;
signal	rst										:	std_logic;

signal	adc_data_out							:	std_logic_vector(255 downto 0);
signal	adc_expo_out							:	std_logic_vector(3 downto 0);
signal	adc_valid_out							:	std_logic;

--FPGA1
signal	sop_tx_fpga1							:	std_logic;
signal	data_tx_fpga1							:	std_logic_vector(31 downto 0);
signal	eop_tx_fpga1							:	std_logic;
signal	valid_tx_fpga1							:	std_logic;

signal	sop_rx_fpga1							:	std_logic;
signal	data_rx_fpga1							:	std_logic_vector(31 downto 0);
signal	eop_rx_fpga1							:	std_logic;
signal	valid_rx_fpga1							:	std_logic;

signal	int_udp_port								:	std_logic_vector(15 downto 0);

--FPGA2
signal	sop_tx_fpga2							:	std_logic;
signal	data_tx_fpga2							:	std_logic_vector(31 downto 0);
signal	eop_tx_fpga2							:	std_logic;
signal	valid_tx_fpga2							:	std_logic;

signal	sop_rx_fpga2							:	std_logic;
signal	data_rx_fpga2							:	std_logic_vector(31 downto 0);
signal	eop_rx_fpga2							:	std_logic;
signal	valid_rx_fpga2							:	std_logic;


--DHCP
signal	sop_tx_dhcp								:	std_logic;
signal	data_tx_dhcp							:	std_logic_vector(31 downto 0);
signal	eop_tx_dhcp								:	std_logic;
signal	valid_tx_dhcp							:	std_logic;

signal	sop_rx_dhcp								:	std_logic;
signal	data_rx_dhcp							:	std_logic_vector(31 downto 0);
signal	eop_rx_dhcp								:	std_logic;
signal	valid_rx_dhcp							:	std_logic;

signal	mac_addr_dhcp_server					:	std_logic_vector(47 downto 0):=x"1aef93b4c000";
signal	ip_addr_dhcp_server					:	std_logic_vector(31 downto 0):=x"c0a80000";
signal	ip_addr_fpga1							:	std_logic_vector(31 downto 0):=x"c0a80001";
signal	ip_addr_fpga2							:	std_logic_vector(31 downto 0):=x"c0a80002";
signal	mac_addr_fpga1							:	std_logic_vector(47 downto 0):=x"1aef93b4c001";
signal	mac_addr_fpga2							:	std_logic_vector(47 downto 0):=x"1aef93b4c002";
signal	lease_time								:	std_logic_vector(31 downto 0):=x"000fffff";

begin

fpga1	:	entity	work.FPGA1
port map (
			clock=>clk,reset=>rst,adcdataout=>adc_data_out,adcexpout=>adc_expo_out,
			adcvalidout=>adc_valid_out,
			
			fpga1validout=>valid_tx_fpga1,fpga1sof=>sop_tx_fpga1,fpga1eof=>eop_tx_fpga1,fpga1dataout=>data_tx_fpga1,
			
			validin=>valid_rx_fpga1,sof=>sop_rx_fpga1,eof=>eop_rx_fpga1,datain=>data_rx_fpga1,
			
			intudpport=>int_udp_port	
			);

fpga2	:	entity	work.FPGA2
port map (
			clk=>clk,rst=>rst,
			mac_addr_fpga2=>mac_addr_fpga2,
			
			sop_tx_mac=>sop_tx_fpga2,data_tx_mac=>data_tx_fpga2,eop_tx_mac=>eop_tx_fpga2,valid_out=>valid_tx_fpga2,
			
			sop_rx_mac=>sop_rx_fpga2,data_rx_mac=>data_rx_fpga2,eop_rx_mac=>eop_rx_fpga2,valid_in=>valid_rx_fpga2
			);
	
dhcp		:	entity	work.dhcp_server
port map (
			clk=>clk,rst=>rst,
			sop_in=>sop_rx_dhcp,data_in=>data_rx_dhcp,eop_in=>eop_rx_dhcp,valid_data_in=>valid_rx_dhcp,
			
			sop_out=>sop_tx_dhcp,data_out=>data_tx_dhcp,eop_out=>eop_tx_dhcp,valid_out=>valid_tx_dhcp,
			
			mac_addr_dhcp_server=>mac_addr_dhcp_server,ip_addr_dhcp_server=>ip_addr_dhcp_server,
			
			ip_addr_fpga1=>ip_addr_fpga1,ip_addr_fpga2=>ip_addr_fpga2,
			
			mac_addr_fpga1=>mac_addr_fpga1,mac_addr_fpga2=>mac_addr_fpga2,lease_time=>lease_time
			);

switch	:	entity	work.switch
port map (
			clk=>clk,rst=>rst,
			
			sop_tx_fpga1=>sop_tx_fpga1,data_tx_fpga1=>data_tx_fpga1,
			eop_tx_fpga1=>eop_tx_fpga1,valid_tx_fpga1=>valid_tx_fpga1,
			sop_rx_fpga1=>sop_rx_fpga1,data_rx_fpga1=>data_rx_fpga1,
			eop_rx_fpga1=>eop_rx_fpga1,valid_rx_fpga1=>valid_rx_fpga1,
			
			sop_tx_fpga2=>sop_tx_fpga2,data_tx_fpga2=>data_tx_fpga2,
			eop_tx_fpga2=>eop_tx_fpga2,valid_tx_fpga2=>valid_tx_fpga2,
			sop_rx_fpga2=>sop_rx_fpga2,data_rx_fpga2=>data_rx_fpga2,
			eop_rx_fpga2=>eop_rx_fpga2,valid_rx_fpga2=>valid_rx_fpga2,
			
			sop_tx_dhcp=>sop_tx_dhcp,data_tx_dhcp=>data_tx_dhcp,
			eop_tx_dhcp=>eop_tx_dhcp,valid_tx_dhcp=>valid_tx_dhcp,
			sop_rx_dhcp=>sop_rx_dhcp,data_rx_dhcp=>data_rx_dhcp,
			eop_rx_dhcp=>eop_rx_dhcp,valid_rx_dhcp=>valid_rx_dhcp,
			
			mac_addr_dhcp_server=>mac_addr_dhcp_server,
			ip_addr_dhcp_server=>ip_addr_dhcp_server,
			mac_addr_fpga1=>mac_addr_fpga1,ip_addr_fpga1=>ip_addr_fpga1,
			mac_addr_fpga2=>mac_addr_fpga2,ip_addr_fpga2=>ip_addr_fpga2
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
		rst<='0';wait until rising_edge(clk);
		
		while rst='0' loop
		wait until rising_edge(clk);
		end loop;
		
	end process;
	
	
	
	
	
	
	
	
	
	
	
	

end Behavioral;

