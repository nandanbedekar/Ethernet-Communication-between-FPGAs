library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity switch is
port	(
	clk						:	in		std_logic;
	rst						:	in		std_logic;

--FPGA1
	sop_tx_fpga1			:	in		std_logic;
	data_tx_fpga1			:	in		std_logic_vector(31 downto 0);
	eop_tx_fpga1			:	in		std_logic;
	valid_tx_fpga1			:	in		std_logic;

	sop_rx_fpga1			:	out	std_logic;
	data_rx_fpga1			:	out	std_logic_vector(31 downto 0);
	eop_rx_fpga1			:	out	std_logic;
	valid_rx_fpga1			:	out	std_logic;

--FPGA2
	sop_tx_fpga2			:	in		std_logic;
	data_tx_fpga2			:	in		std_logic_vector(31 downto 0);
	eop_tx_fpga2			:	in		std_logic;
	valid_tx_fpga2			:	in		std_logic;

	sop_rx_fpga2			:	out	std_logic;
	data_rx_fpga2			:	out	std_logic_vector(31 downto 0);
	eop_rx_fpga2			:	out	std_logic;
	valid_rx_fpga2			:	out	std_logic;

--DHCP
	sop_tx_dhcp				:	in		std_logic;
	data_tx_dhcp			:	in		std_logic_vector(31 downto 0);
	eop_tx_dhcp				:	in		std_logic;
	valid_tx_dhcp			:	in		std_logic;

	sop_rx_dhcp				:	out	std_logic;
	data_rx_dhcp			:	out	std_logic_vector(31 downto 0);
	eop_rx_dhcp				:	out	std_logic;
	valid_rx_dhcp			:	out	std_logic;

	mac_addr_dhcp_server	:	in		std_logic_vector(47 downto 0);
	ip_addr_dhcp_server	:	in		std_logic_vector(31 downto 0);
	mac_addr_fpga1			:	in		std_logic_vector(47 downto 0);
	ip_addr_fpga1			:	in		std_logic_vector(31 downto 0);
	mac_addr_fpga2			:	in		std_logic_vector(47 downto 0);
	ip_addr_fpga2			:	in		std_logic_vector(31 downto 0)
	
	
		
	);
end switch;

architecture Behavioral of switch is

signal	count_1					:	unsigned(10 downto 0);
signal	busy_1,togg_1			:	std_logic;
signal	mac_get_1				:	std_logic_vector(47 downto 0);

signal	count_2					:	unsigned(10 downto 0);
signal	busy_2,togg_2			:	std_logic;
signal	mac_get_2				:	std_logic_vector(47 downto 0);

signal	count_d					:	unsigned(10 downto 0);
signal	busy_d,togg_d			:	std_logic;
signal	mac_get_d				:	std_logic_vector(47 downto 0);

type 		shift_reg is array (14 downto 0) of std_logic_vector(31 downto 0);
signal 	shift_1,shift_2,shift_d	:	shift_reg;
type		shift_bit	is array(14 downto 0) of	std_logic;
signal	valid_1,valid_2,valid_d	:	shift_bit;
signal	sop_1,sop_2,sop_d			:	shift_bit;
signal	eop_1,eop_2,eop_d			:	shift_bit;		

begin

shift_1(0)<=data_tx_fpga1;
valid_1(0)<=valid_tx_fpga1;
sop_1(0)<=sop_tx_fpga1;
eop_1(0)<=eop_tx_fpga1;

shift_2(0)<=data_tx_fpga2;
valid_2(0)<=data_tx_fpga2;
sop_2(0)<=sop_tx_fpga2;
eop_2(0)<=eop_tx_fpga2;

shift_d(0)<=data_tx_dhcp;
valid_d(0)<=data_tx_dhcp;
sop_d(0)<=sop_tx_dhcp;
eop_d(0)<=eop_tx_dhcp;

process(rst,clk)
begin
	if rst='1' then
	shift_1<=(others=>(others=>'0'));shift_2<=(others=>(others=>'0'));
	shift_d<=(others=>(others=>'0'));
	valid_1<=(others=>(others=>'0'));valid_2<=(others=>(others=>'0'));
	valid_d<=(others=>(others=>'0'));
	
	elsif rising_edge(clk) then
		for i in 0 to 13 loop
		shift_1(i+1)<=shift_1(i);
		shift_2(i+1)<=shift_2(i);
		shift_d(i+1)<=shift_d(i);
		
		valid_1(i+1)<=valid_1(i);
		valid_2(i+1)<=valid_2(i);
		valid_d(i+1)<=valid_d(i);
		
		sop_1(i+1)<=sop_1(i);
		sop_2(i+1)<=sop_2(i);
		sop_3(i+1)<=sop_3(i);
		
		eop_1(i+1)<=eop_1(i);
		eop_2(i+1)<=eop_2(i);
		eop_3(i+1)<=eop_3(i);
		
		end loop;
	end if;
	
end process;

process(clk,rst)
begin
	if rst='1' then
	count_1<="0000000000";
	count_2<="0000000000";
	count_d<="0000000000";
	
	elsif rising_edge(clk) then
		if sop_tx_fpga1='1' then
		count_1<="00000000001";
		end if;
		
		if count_1>0 then
		count_1<=count_1+1;
		end if;
		
		if eop_1(14)='1' then
		count_1<="00000000000";
		end if;
		
		if count_1="00000001101" then--13 --you may change this to the critical time where data HAS to be routed somewhere
			if mac_get_1 = mac_addr_fpga1 or mac_get_1=x"ffffff" then
				if busy_2='1' then
				count_1<="00000000000";
				end if;
			elsif mac_get_1 = mac_addr_dhcp_server or mac_get_1=x"ffffff" then
				if busy_d='1' then
				count_2<="00000000000";
				end if;
			end if;
		end if;
		
		--
		if sop_tx_fpga2='1' then
		count_2<="00000000001";
		end if;
		
		if count_2>0 then
		count_2<=count_2+1;
		end if;
		
		if eop_2(14)='1' then
		count_2<="00000000000";
		end if;
		
		if count_2="00000001101" then--13 --you may change this to the critical time where data HAS to be routed somewhere
			if mac_get_2 = mac_addr_fpga1 or mac_get_2=x"ffffff" then
				if busy_1='1' then
				count_2<="00000000000";
				end if;
			elsif mac_get_2 = mac_addr_dhcp_server or mac_get_2=x"ffffff" then
				if busy_d='1' then
				count_2<="00000000000";
				end if;
				
			end if;
		end if;
		
		--
		if sop_tx_dhcp='1' then
		count_d<="00000000001";
		end if;
		
		if count_d>0 then
		count_2<=count_2+1;
		end if;
		
		if eop_d(14)='1' then
		count_d<="00000000000";
		end if;
		
		if count_d="00000001101" then--13 --you may change this to the critical time where data HAS to be routed somewhere
			if mac_get_d = mac_addr_fpga1 or mac_get_d=x"ffffff" then
				if busy_1='1' then
				count_d<="00000000000";
				end if;
			elsif mac_get_d = mac_addr_fpga2 or mac_get_d=x"ffffff" then
				if busy_2='1' then
				count_d<="00000000000";
				end if;
				
			end if;
		end if;
		
	end if;


end process;


process(clk,rst)
begin

	if rst='1' then
		mac_get_1<=x"000000";
		mac_get_2<=x"000000";
		mac_get_d<=x"000000";
		
	elsif rising_edge(clk) then

--sending from fpga1
		if 	count_1="00000001000" then--8
		mac_get_1(15 downto 0)<=data_tx_fpga1;
		elsif count_1="00000001010" then--10
		mac_get_1(31 downto 16)<=data_tx_fpga1;
		elsif count_1="00000001100" then--12
		mac_get_1(47 downto 32)<=data_tx_fpga1;
		elsif count_1>"00000001101" then--13 --you may change this to the critical time where data HAS to be routed somewhere
			if mac_get_1 = mac_addr_fpga2 or mac_get_1=x"ffffff" then
				if busy_2='0' or togg_2='1' then
					busy_2<='1';togg_2<='1';
					
					data_rx_fpga2<=shift_1(14);
					valid_rx_fpga2<=valid_1(14);
					sop_rx_fpga2<=sop_1(14);
					eop_rx_fpga2<=eop_1(14);
					
					if eop_1(14)='1' then
					count_1<="00000000000";
					busy_2<='0';togg_2<='0';
					end if;
					
				elsif busy_2='1' then
					count_1<="00000000000";
				end if;
			end if;
			
			if mac_get_1 = mac_addr_dhcp_server or mac_get_1=x"ffffff" then
				if busy_d='0' or togg_d='1' then
					busy_d<='1';togg_d<='1';
					
					data_rx_dhcp<=shift_1(14);
					valid_rx_dhcp<=valid_1(14);
					sop_rx_dhcp<=sop_1(14);
					eop_rx_dhcp<=eop_1(14);
					
					if eop_d(14)='1' then
					count_1<="00000000000";
					busy_d<='0';togg_d<='0';
					end if;
					
				elsif busy_d='1' then
					null;
				end if;
			end if;
			
		end if;
		




--sending from fpga2
		if 	count_2="00000001000" then--8
		mac_get_2(15 downto 0)<=data_tx_fpga2;
		elsif count_2="00000001010" then--10
		mac_get_2(31 downto 16)<=data_tx_fpga2;
		elsif count_2="00000001100" then--12
		mac_get_2(47 downto 32)<=data_tx_fpga2;
		elsif count_2>"00000001101" then--13 --you may change this to the critical time where data HAS to be routed somewhere
			if mac_get_2 = mac_addr_fpga1 or mac_get_1=x"ffffff" then
				if busy_1='0' or togg_1='1' then
					busy_1<='1';togg_1<='1';
					
					data_rx_fpga1<=shift_2(14);
					valid_rx_fpga1<=valid_2(14);
					sop_rx_fpga1<=sop_2(14);
					eop_rx_fpga1<=eop_2(14);
					
					if eop_2(14)='1' then
					count_2<="00000000000";
					busy_1<='0';togg_1<='0';
					end if;
					
				elsif busy_1='1' then
					count_2<="00000000000";
				end if;
			end if;
			
			if mac_get_2 = mac_addr_dhcp_server or mac_get_2=x"ffffff" then
				if busy_d='0' or togg_d='1' then
					busy_d<='1';togg_d<='1';
					
					data_rx_dhcp<=shift_2(14);
					valid_rx_dhcp<=valid_2(14);
					sop_rx_dhcp<=sop_2(14);
					eop_rx_dhcp<=eop_2(14);
				
					if eop_2(14)='1' then
					count_2<="00000000000";
					busy_d<='0';togg_d<='0';
					end if;
					
				elsif busy_d='1' then
					null;
				end if;
			end if;
			
		end if;

		










--sending from dhcp
		if 	count_d="00000001000" then--8
		mac_get_d(15 downto 0)<=data_tx_dhcp;
		elsif count_d="00000001010" then--10
		mac_get_d(31 downto 16)<=data_tx_dhcp;
		elsif count_2="00000001100" then--12
		mac_get_d(47 downto 32)<=data_tx_dhcp;
		elsif count_d>"00000001101" then--13 --you may change this to the critical time where data HAS to be routed somewhere
			if mac_get_d = mac_addr_fpga1 or mac_get_d=x"ffffff" then
				if busy_1='0' or togg_1='1' then
					busy_1<='1';togg_1<='1';
					
					data_rx_fpga1<=shift_d(14);
					valid_rx_fpga1<=valid_d(14);
					sop_rx_fpga1<=sop_d(14);
					eop_rx_fpga1<=eop_d(14);
					
					if eop_d(14)='1' then
					count_d<="00000000000";
					busy_1<='0';togg_1<='0';
					end if;
					
				elsif busy_1='1' then
					count_d<="00000000000";
				end if;
			end if;
			
			if mac_get_d = mac_addr_fpga2 or mac_get_d=x"ffffff" then
				if busy_2='0' or togg_2='1' then
					busy_2<='1';togg_2<='1';
					
					data_rx_fpga2<=shift_d(14);
					valid_rx_fpga2<=valid_d(14);
					sop_rx_fpga2<=sop_d(14);
					eop_rx_fpga2<=eop_d(14);
				
					if eop_d(14)='1' then
					count_d<="00000000000";
					busy_2<='0';togg_2<='0';
					end if;
					
				elsif busy_2='1' then
					null;
				end if;
			end if;
			
		end if;









end if;
end process;

















end Behavioral;

