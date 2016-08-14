library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ip is
port(
		clk,rst:in std_logic;

--		TX Unit
		sop_tx_udp:in std_logic;
		data_tx_udp:in std_logic_vector(15 downto 0);
		eop_tx_udp:in std_logic;
		
		sop_tx_ether:out std_logic;
		data_tx_ether:out std_logic_vector(15 downto 0);
		eop_tx_ether:out std_logic
		);
end ip;

architecture Behavioral of ip is

	--TX RAM
	signal data_in_ram: std_logic_vector(15 downto 0);
	signal w_addr_ram,r_addr_ram: unsigned(3 downto 0):="0000";
	signal data_out_ram: std_logic_vector(15 downto 0);

	--IP Header Information
	signal version : std_logic_vector(3 downto 0):="0100";--4--
	signal ip_header_length : std_logic_vector(3 downto 0):="0101";--5
	signal type_of_serv : std_logic_vector(7 downto 0):="00000000";--0
	signal length_ip : std_logic_vector(15 downto 0):="0000010110000110";--1414---
	signal identi : std_logic_vector(15 downto 0):="0000000000000001";--1
	signal flag: std_logic_vector(2 downto 0):="000";--
	signal offset: std_logic_vector(12 downto 0):="0000000000000";---
	signal ttl: std_logic_vector(7 downto 0):="00000101";
	signal protocol: std_logic_vector(7 downto 0):="00010001";--udp
	signal header_chksum: std_logic_vector(15 downto 0):="0000000000000000";--
	signal source_ip: std_logic_vector(31 downto 0):="00000101100001010000010110000111";---
	signal desti_ip: std_logic_vector(31 downto 0):="00000101100001000000010110001000";---
	
	--SOP and EOP manager of udp
	signal data_incoming,data_incoming1,data_incoming2,data_incoming3 : std_logic:='0';
	signal sop_delay: unsigned(4 downto 0):="00000";

	--Writing into buffer
	
	
	--Sending data to ether
	signal start_sending: std_logic:='0';
	signal count_r: unsigned(9 downto 0):="0000000000";
	signal count: unsigned(1 downto 0):="00";


begin



	--RAM 
	ram_tx : entity work.ram_ip
	port map (
	clk=>clk, rst=>rst, data_in_ram=>data_in_ram, data_out_ram=>data_out_ram,
	we_ram=>data_incoming3, r_addr_ram=>r_addr_ram, w_addr_ram=>w_addr_ram);
	
	----SOP and EOP manager of udp
	process(clk)
	begin
	if rising_edge(clk) then
		if sop_tx_udp ='1' then
		 data_incoming1<='1';
		elsif eop_tx_udp ='1' then
		 data_incoming1<='0';
		end if;
	end if;
	end process;
	data_incoming2<=data_incoming1 or sop_tx_udp;
	
	process(clk)
	begin
	if rising_edge(clk) then
	data_incoming3<=data_incoming2;
	data_incoming<=data_incoming3;
	end if;
	end process;
	
	
	--writing data to buffer
	process(clk)
	begin
	if rising_edge(clk) then
		if data_incoming2='1' then
			if count="00" then
			data_in_ram<=data_tx_udp;
			count<=count+1;
--			elsif count="01" then
--			data_in_ram<=data_tx_udp;
--			count<=count+1;
			else
			w_addr_ram<=w_addr_ram+1;
			data_in_ram<=data_tx_udp;
			if w_addr_ram="1001" then
			w_addr_ram<="0000";
			end if;
			end if;
		elsif data_incoming2='0' then
		count<="00";
		w_addr_ram<="0000";
		
		end if;
	end if;
	end process;
	
	
	--s_ahead meachanism
	process(clk,rst)
	begin
	if 	rst='1' then sop_delay<="00000";
	elsif rising_edge(clk) then 
		if sop_tx_udp='1' then sop_delay<="00001";		 
		elsif sop_delay="00000" then null;
		else	sop_delay<=sop_delay + 1;
		end if;
	end if;
	end process;
	
	
	--output data to the ethernet and also reading from the buffer
	process(clk)
	begin
	if rising_edge(clk) then
		if sop_tx_udp='1' then--1st sent
		sop_tx_ether<='1';
		data_tx_ether<=type_of_serv&ip_header_length&version;
		r_addr_ram<="0000";
		start_sending<='0';
		count_r<="0000000000";
		
		elsif	sop_delay="00001" then--2nd sent
		sop_tx_ether<='0';
		data_tx_ether<=length_ip;
		start_sending<='1';
		
		elsif	sop_delay="00010" then--
		data_tx_ether<=identi;
		
		elsif	sop_delay="00011" then
		data_tx_ether<=flag&offset;
		
		elsif	sop_delay="00100" then
		data_tx_ether<=protocol&ttl;
		
		elsif	sop_delay="00101"	then
		data_tx_ether<=header_chksum;
		
		elsif	sop_delay="00110"	then
		data_tx_ether<=source_ip(15 downto 0);
		
		elsif	sop_delay="00111"	then
		data_tx_ether<=source_ip(31 downto 16);
		
		elsif	sop_delay="01000"	then
		data_tx_ether<=desti_ip(15 downto 0);
		
		elsif	sop_delay="01001"	then
		data_tx_ether<=desti_ip(31 downto 16);
		r_addr_ram<=r_addr_ram+1;
		
		elsif start_sending='1' and count_r<696 then
		data_tx_ether<=data_out_ram;
		r_addr_ram<=r_addr_ram+1;
		
		if r_addr_ram="1001" then
			r_addr_ram<="0000";
		end if;
		count_r<=count_r+1;
		
		elsif count_r="1010111000" then--696
		data_tx_ether<=data_out_ram;
		count_r<=count_r+1;
		eop_tx_ether<='1';
		
		elsif count_r="1010111001" then--697
		start_sending<='0';
		count_r<="0000000000";
		eop_tx_ether<='0';
		r_addr_ram<="0000";
		end if;
	end if;
	
	end process;
	
	









end Behavioral;

