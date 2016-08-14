library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dhcp_server is
port (
		clk,rst:							in	std_logic;
		
		sop_in: 							in	std_logic;
		data_in: 						in	std_logic_vector(31 downto 0);
		eop_in:							in	std_logic;
		valid_data_in:					in	std_logic;
		mac_addr_dhcp_server: 		in std_logic_vector(47 downto 0);
		ip_addr_dhcp_server:  		in std_logic_vector(31 downto 0);
		ip_addr_fpga1:					in	std_logic_vector(31 downto 0);
		ip_addr_fpga2:					in	std_logic_vector(31 downto 0);
		mac_addr_fpga1:				in	std_logic_vector(47 downto 0);		
		mac_addr_fpga2:				in	std_logic_vector(47 downto 0);
		lease_time:						in	std_logic_vector(31 downto 0);

		sop_out:						  out std_logic;
		data_out:					  out std_logic_vector(31 downto 0);
		eop_out:						  out std_logic;
		valid_out:					  out std_logic 
		);

end dhcp_server; 

architecture Behavioral of dhcp_server is

--CRC
signal crc_in,crc_out,crc_final:		std_logic_vector(31 downto 0);
signal crc_en: 							std_logic:='0';
signal crc_start_n: 						std_logic:='1';
signal crc_t: 								unsigned(0 downto 0):="0";

type fsm_states is (s_idle,s_dhcp_o,s_dhcp_a);
signal q_state: fsm_states;
signal count_dhcp_o:						unsigned(9 downto 0);
signal count_dhcp_a:						unsigned(9 downto 0);
signal dhcp_d_valid:						std_logic;
signal dhcp_r_valid:						std_logic;

signal count_rx	 :						unsigned(9 downto 0);

--Sending Data Out
signal reg1,reg2,reg3: 					std_logic_vector(15 downto 0);
signal start_send_i,start_send_o:	std_logic:='0';
signal send_t: 							unsigned(0 downto 0):="0";
signal data_sending: 					std_logic;

--IP header
    signal version :            		std_logic_vector(3 downto 0):="0100";
    signal ip_header_length :     	std_logic_vector(3 downto 0):="0101";
    signal type_of_serv :         	std_logic_vector(7 downto 0):="00000000";
    signal length_ip :             	std_logic_vector(15 downto 0):="0000000000011110";--30---
    signal identi :             		std_logic_vector(15 downto 0):="0000000000000001";
    signal flag_ip:             		std_logic_vector(2 downto 0):="000";
    signal offset:                 	std_logic_vector(12 downto 0):="0000000000000";---
    signal ttl:                 		std_logic_vector(7 downto 0):="00000101";--5--
    signal protocol:             	std_logic_vector(7 downto 0):="00010001";
    signal header_chksum:         	unsigned(15 downto 0):="0000000000000000";---to be defined

    signal source_dest_ip_sum:      unsigned(15 downto 0):="0000000000000000";
    signal source_ip_sum:           unsigned(15 downto 0):="0000000000000000";
    signal dest_ip_sum:             unsigned(15 downto 0):="0000000000000000";

--UDP Header
    signal sp2:                 		std_logic_vector(15 downto 0):="0000000001000011";--67
    signal dp1:                 		std_logic_vector(15 downto 0):="0000000001000100";--68
    signal length_udp:             	std_logic_vector(15 downto 0):="0000000000001010";--10 
    signal udp_chksum:              unsigned(15 downto 0);
    signal udp_chksum_seq:          std_logic_vector(15 downto 0);
    signal seq_sent:             	std_logic_vector(14 downto 0);

--Information related to each FPGA

	signal 	mac_addr_send:				std_logic_vector(47 downto 0);
	signal 	ip_addr_send:				std_logic_vector(31 downto 0);
	signal	ip_dhcp_sum:				unsigned(15 downto 0);
	
begin
	
	process(clk,rst)
	begin
	if rst='1' then
	q_state<=s_idle;
	elsif rising_edge(clk) then
		if q_state=s_idle then
			if dhcp_d_valid='1' then
			q_state<=s_dhcp_o;
			elsif dhcp_r_valid='1' then
			q_state<=s_dhcp_a;
			end if;
		elsif q_state=s_dhcp_o then
			if count_dhcp_o = "0001000000" then
				q_state<=s_idle;
			end if; 
		elsif q_state=s_dhcp_a then	
			if count_dhcp_a = "0001000000" then
				q_state<=s_idle;
			end if;
			
		end if;
	end if;
	end process; 

	process(clk,rst)
	begin
	if rst='1' then
	count_dhcp_o<="0000000000";count_dhcp_a<="0000000000";length_udp<="0000000000111110";
	elsif rising_edge(clk) then
		case q_state is 
			when s_dhcp_o =>
			count_dhcp_o<=count_dhcp_o+1;
				if count_dhcp_o ="0001000000" then
				count_dhcp_o<="0000000000";
				end if;
				length_udp<="0000000000111110";--62
				header_chksum<=ip_dhcp_sum+"1000110101100";--ip_server_sum+"100....";
				length_ip<="0000000001010010";--82
				
			when s_dhcp_a =>
			count_dhcp_a<=count_dhcp_a+1;
				if count_dhcp_a ="0001000000" then
				count_dhcp_a<="0000000000";
				end if;
				length_udp<="0000000000111110";--62
				header_chksum<=ip_dhcp_sum+"1000110101100";--ip_server_sum+"100....";
				length_ip<="0000000001010010";--82
				
			when others =>
			null;
		end case;
	end if;
	end process;
	
--RX UNIT--------------------
--The Rx Unit for the Device!
	process(clk,rst)
		variable mac_addr_temp: std_logic_vector(47 downto 0);
		variable udp_chksum_addr_v: unsigned(15 downto 0):="0000000000000000";
		variable udp_chksum_v1: unsigned(15 downto 0):="0000000000000000";
		variable udp_chksum_v2: unsigned(15 downto 0):="0000000000000000";	
		variable one: unsigned(7 downto 0):="00001010";
	begin
	if rst='1' then
	count_rx<="0000000000";dhcp_d_valid<='0';dhcp_r_valid<='0';
	mac_addr_temp:=(others=>'0');
	mac_addr_send<=(others=>'0');ip_addr_send<=(others=>'0');
	ip_dhcp_sum<=(others=>'0');
	
	
	elsif rising_edge(clk) then
		if valid_data_in='1' then
		count_rx<=count_rx+1;
		ip_dhcp_sum<=unsigned(ip_addr_dhcp_server(31 downto 16)) + unsigned(ip_addr_dhcp_server(15 downto 0));
		end if;
		
		if eop_in='1' then--26
		count_rx<="0000000000";
		end if;
			
			
		if count_rx="0000000011" then --when it gets mac addr--3
		mac_addr_temp(15 downto 0):=data_in(31 downto 16);
		elsif count_rx="0000000100" then--next of prev--4
		mac_addr_temp(47 downto 16):=data_in(31 downto 0);
		elsif count_rx="0000000101" then--next of prev--5
			if mac_addr_temp=mac_addr_fpga1 then
			ip_addr_send<=ip_addr_fpga1;
			mac_addr_send<=mac_addr_fpga1;
			udp_chksum_addr_v:=unsigned(sp2)+unsigned(dp1)+unsigned(length_udp)+
							x"0102"+x"0006"+x"abcd"+x"0001"+x"8000"+
							unsigned(ip_addr_send(15 downto 0))+unsigned(ip_addr_send(31 downto 16))+
							ip_dhcp_sum+unsigned(mac_addr_send(15 downto 0))+unsigned(mac_addr_send(31 downto 16))+
							unsigned(mac_addr_send(47 downto 32))+x"0135"+x"3302"+
							unsigned(lease_time(7 downto 0))*128+unsigned(lease_time(7 downto 0))*128+
							x"0004"+unsigned(lease_time(23 downto 8))+65280+
							unsigned(lease_time(31 downto 24));
			
			
			--udp_chksum_addr_v:=not "1001111000110101";			 
			elsif mac_addr_temp=mac_addr_fpga2 then
			ip_addr_send<=ip_addr_fpga2;
			mac_addr_send<=mac_addr_fpga2;
			udp_chksum_addr_v:=
							unsigned(sp2)+unsigned(dp1)+unsigned(length_udp)+
							x"0102"+x"0006"+x"abcd"+x"0001"+x"8000"+
							unsigned(ip_addr_send(15 downto 0))+unsigned(ip_addr_send(31 downto 16))+
							ip_dhcp_sum+unsigned(mac_addr_send(15 downto 0))+unsigned(mac_addr_send(31 downto 16))+
							unsigned(mac_addr_send(47 downto 32))+x"0135"+x"3302"+
							unsigned(lease_time(7 downto 0))*128+unsigned(lease_time(7 downto 0))*128+
							x"0004"+unsigned(lease_time(23 downto 8))+65280+
							unsigned(lease_time(31 downto 24));
			
			
			--udp_chksum_addr_v:=not "1001111000110011";

			end if;
		elsif count_rx="0000011001" then
			if data_in(31 downto 16)="0000000000000001" then
			dhcp_d_valid<='1';
			udp_chksum<=udp_chksum_addr_v;
			elsif data_in(31 downto 16)="0000000000000011" then
			dhcp_r_valid<='1';udp_chksum<=udp_chksum_addr_v+3;
			end if;	
		end if;
		
		if q_state=s_dhcp_o then
			dhcp_d_valid<='0';
		elsif q_state=s_dhcp_a then
			dhcp_r_valid<='0';
		end if;

		
	end if;	
	end process;


--TX UNIT-------------------------------------------	
--The Tx unit for the device, following 3 processes
	process(clk)
	begin
	if rising_edge(clk) then	
		
	case q_state is
	when s_dhcp_o =>--sending dhcp Discovery
		if count_dhcp_o="0000000001" then--1
			reg1<="0101010101010101";--preamble
			elsif (count_dhcp_o<4 and count_dhcp_o>1) then
			reg1<="0101010101010101";--preamble
			elsif count_dhcp_o="0000000100" then--4
			reg1<="1101010101010101";--preamble
			elsif count_dhcp_o="0000000101" then--5
         reg1<=mac_addr_send(15 downto 0);--target MAC
         elsif count_dhcp_o="0000000110" then--6
			reg1<=mac_addr_send(31 downto 16);--target MAC
			elsif count_dhcp_o="0000000111" then--7
			reg1<=mac_addr_send(47 downto 32);--target MAC
			
			elsif count_dhcp_o="0000001000" then--8
			reg1<=mac_addr_dhcp_server(15 downto 0);--sender MAC
			elsif count_dhcp_o="0000001001" then--9
			reg1<=mac_addr_dhcp_server(31 downto 16);--sender MAC
			elsif count_dhcp_o="0000001010" then--10
			reg1<=mac_addr_dhcp_server(47 downto 32);--sender MAC
			elsif count_dhcp_o="0000001011" then--11
			reg1<="0000000001101000";--reg1<=leng_type;
		
			--IP  header
			elsif count_dhcp_o="0000001100" then--12
			reg1<=type_of_serv&ip_header_length&version;
			elsif count_dhcp_o="0000001101" then--13
			reg1<=length_ip;
			elsif count_dhcp_o="0000001110" then--14
			reg1<=identi;
			elsif count_dhcp_o="0000001111" then--15
			reg1<=flag_ip&offset;
			elsif count_dhcp_o="0000010000" then--16
			reg1<=protocol&ttl;
			elsif count_dhcp_o="0000010001" then--17
			reg1<=not std_logic_vector(header_chksum);
			elsif count_dhcp_o="0000010010" then--18
			reg1<=ip_addr_dhcp_server(15 downto 0);--reg1<=source_ip1(15 downto 0);
			elsif count_dhcp_o="0000010011" then--19
			reg1<=ip_addr_dhcp_server(31 downto 16);--reg1<=source_ip1(31 downto 16);
			elsif count_dhcp_o="0000010100" then--20
			reg1<=x"0000";--reg1<=desti_ip2(15 downto 0);
			elsif count_dhcp_o="0000010101" then--21
			reg1<=x"0000";--reg1<=desti_ip2(31 downto 16);


			
			--UDP header
			
			elsif count_dhcp_o="0000010110" then--22
			reg1<=sp2;--0800--to be set
			elsif count_dhcp_o="0000010111" then--23
			reg1<=dp1;--1000--to be set
			elsif count_dhcp_o="0000011000" then--24
			reg1<=length_udp;--58 in decimal
			elsif count_dhcp_o="0000011001" then--25
			reg1<=not std_logic_vector(udp_chksum);
			
			--DHCP
			elsif count_dhcp_o="0000011010" then--26
			reg1<=x"0102";--htype&op
			elsif count_dhcp_o="0000011011" then--27
			reg1<=x"0006";--hops&hlen
			elsif count_dhcp_o="0000011100" then--28
			reg1<=x"abcd";--xid lsb
			elsif count_dhcp_o="0000011101" then--29
			reg1<=x"0001";--xid msb
			elsif count_dhcp_o="0000011110" then--30
			reg1<=x"0000";--secs
			elsif count_dhcp_o="0000011111" then--31
			reg1<=x"8000";--flags
			elsif count_dhcp_o="0000100000" then--32
			reg1<=x"0000";--clint ip lsb
			elsif count_dhcp_o="0000100001" then--33
			reg1<=x"0000";--clint ip msb
			elsif count_dhcp_o="0000100010" then--34
			reg1<=ip_addr_send(15 downto 0);--your ip lsb
			elsif count_dhcp_o="0000100011" then--35
			reg1<=ip_addr_send(31 downto 16);--your ip msb
			elsif count_dhcp_o="0000100100" then--36
			reg1<=ip_addr_dhcp_server(15 downto 0);--server ip lsb
			elsif count_dhcp_o="0000100101" then--37
			reg1<=ip_addr_dhcp_server(31 downto 16);--server ip msb
			elsif count_dhcp_o="0000100110" then--38
			reg1<=x"0000";--gateway ip lsb
			elsif count_dhcp_o="0000100111" then--39
			reg1<=x"0000";--gateway ip msb
			elsif count_dhcp_o="0000101000" then--40
			reg1<=mac_addr_send(15 downto 0);--clint mac (15 0)
			elsif count_dhcp_o="0000101001" then--41
			reg1<=mac_addr_send(31 downto 16);--clint mac (31 16)
			elsif count_dhcp_o="0000101010" then--42
			reg1<=mac_addr_send(47 downto 32);--clint mac (47 32)
			elsif count_dhcp_o="0000101011" then--43
			reg1<=x"0000";--clint mac 0000 stuff
			elsif count_dhcp_o="0000101100" then--44
			reg1<=x"0000";--clint mac 0000 stuff
			elsif count_dhcp_o="0000101101" then--45
			reg1<=x"0000";--clint mac 0000 stuff
			elsif count_dhcp_o="0000101110" then--46
			reg1<=x"0000";--clint mac 0000 stuff
			elsif count_dhcp_o="0000101111" then--47
			reg1<=x"0000";--clint mac 0000 stuff
			elsif count_dhcp_o="0000110000" then--48
			reg1<=x"01"&x"35";--Option DHCP Type:53 octet 2&1
			elsif count_dhcp_o="0000110001" then--49
			reg1<=x"3302";--Option 51 & DHCP Type 53 octet 3
			elsif count_dhcp_o="0000110010" then--50
			reg1<=lease_time(7 downto 0)&x"04";--leasetime(octet1)&length
		   elsif count_dhcp_o="0000110011" then--51
			reg1<=lease_time(23 downto 8);--leasetime(octet2&3)
			elsif count_dhcp_o="0000110100" then--52
			reg1<=x"ff"&lease_time(31 downto 24);--end & octet(4)			
			end if;

		when s_dhcp_a =>--sending dhcp Discovery
			if count_dhcp_a="0000000001" then--1
			reg1<="0101010101010101";--preamble
			elsif (count_dhcp_a<4 and count_dhcp_a>1) then
			reg1<="0101010101010101";--preamble
			elsif count_dhcp_a="0000000100" then--4
			reg1<="1101010101010101";--preamble
			elsif count_dhcp_a="0000000101" then--5
			reg1<=mac_addr_send(15 downto 0);--target MAC
			elsif count_dhcp_a="0000000110" then--6
			reg1<=mac_addr_send(31 downto 16);--target MAC
			elsif count_dhcp_a="0000000111" then--7
			reg1<=mac_addr_send(47 downto 32);--target MAC
			
			elsif count_dhcp_a="0000001000" then--8
			reg1<=mac_addr_dhcp_server(15 downto 0);--sender MAC
			elsif count_dhcp_a="0000001001" then--9
			reg1<=mac_addr_dhcp_server(31 downto 16);--sender MAC
			elsif count_dhcp_a="0000001010" then--10
			reg1<=mac_addr_dhcp_server(47 downto 32);--sender MAC
			elsif count_dhcp_a="0000001011" then--11
			reg1<="0000000001101000";--reg1<=leng_type;
			
			--IP  header
			elsif count_dhcp_a="0000001100" then--12
			reg1<=type_of_serv&ip_header_length&version;
			elsif count_dhcp_a="0000001101" then--13
			reg1<=length_ip;
			elsif count_dhcp_a="0000001110" then--14
			reg1<=identi;
			elsif count_dhcp_a="0000001111" then--15
			reg1<=flag_ip&offset;
			elsif count_dhcp_a="0000010000" then--16
			reg1<=protocol&ttl;
			elsif count_dhcp_a="0000010001" then--17
			reg1<=not std_logic_vector(header_chksum);
			elsif count_dhcp_a="0000010010" then--18
			reg1<=ip_addr_dhcp_server(15 downto 0);--reg1<=source_ip1(15 downto 0);
			elsif count_dhcp_a="0000010011" then--19
			reg1<=ip_addr_dhcp_server(31 downto 16);--reg1<=source_ip1(31 downto 16);
			elsif count_dhcp_a="0000010100" then--20
			reg1<=x"0000";--reg1<=desti_ip2(15 downto 0);
			elsif count_dhcp_a="0000010101" then--21
			reg1<=x"0000";--reg1<=desti_ip2(31 downto 16);

			
			--UDP header
			
			elsif count_dhcp_a="0000010110" then--22
			reg1<=sp2;--0800--to be set
			elsif count_dhcp_a="0000010111" then--23
			reg1<=dp1;--1000--to be set
			elsif count_dhcp_a="0000011000" then--24
			reg1<=length_udp;--58 in decimal
			elsif count_dhcp_a="0000011001" then--25
			reg1<=not std_logic_vector(udp_chksum);
			
			--DHCP
			elsif count_dhcp_a="0000011010" then--26
			reg1<=x"0102";--htype&op
			elsif count_dhcp_a="0000011011" then--27
			reg1<=x"0006";--hops&hlen
			elsif count_dhcp_a="0000011100" then--28
			reg1<=x"abcd";--xid lsb
			elsif count_dhcp_a="0000011101" then--29
			reg1<=x"0001";--xid msb
			elsif count_dhcp_a="0000011110" then--30
			reg1<=x"0000";--secs
			elsif count_dhcp_a="0000011111" then--31
			reg1<=x"8000";--flags
			elsif count_dhcp_a="0000100000" then--32
			reg1<=x"0000";--clint ip lsb
			elsif count_dhcp_a="0000100001" then--33
			reg1<=x"0000";--clint ip msb
			elsif count_dhcp_a="0000100010" then--34
			reg1<=ip_addr_send(15 downto 0);--your ip lsb
			elsif count_dhcp_a="0000100011" then--35
			reg1<=ip_addr_send(31 downto 16);--your ip msb
			elsif count_dhcp_a="0000100100" then--36
			reg1<=ip_addr_dhcp_server(15 downto 0);--server ip lsb
			elsif count_dhcp_a="0000100101" then--37
			reg1<=ip_addr_dhcp_server(31 downto 16);--server ip msb
			elsif count_dhcp_a="0000100110" then--38
			reg1<=x"0000";--gateway ip lsb
			elsif count_dhcp_a="0000100111" then--39
			reg1<=x"0000";--gateway ip msb
			elsif count_dhcp_a="0000101000" then--40
			reg1<=mac_addr_send(15 downto 0);--clint mac (15 0)--to be set
			elsif count_dhcp_a="0000101001" then--41
			reg1<=mac_addr_send(31 downto 16);--clint mac (31 16)--to be set
			elsif count_dhcp_a="0000101010" then--42
			reg1<=mac_addr_send(47 downto 32);--clint mac (47 32)--to be set
			elsif count_dhcp_a="0000101011" then--43
			reg1<=x"0000";--clint mac 0000 stuff
			elsif count_dhcp_a="0000101100" then--44
			reg1<=x"0000";--clint mac 0000 stuff
			elsif count_dhcp_a="0000101101" then--45
			reg1<=x"0000";--clint mac 0000 stuff
			elsif count_dhcp_a="0000101110" then--46
			reg1<=x"0000";--clint mac 0000 stuff
			elsif count_dhcp_a="0000101111" then--47
			reg1<=x"0000";--clint mac 0000 stuff
			elsif count_dhcp_a="0000110000" then--48
			reg1<=x"01"&x"35";--Option DHCP Type:53 octet 2&1
			elsif count_dhcp_a="0000110001" then--49
			reg1<=x"3305";--Option 51 & DHCP Type 53 octet 3
			elsif count_dhcp_a="0000110010" then--50
			reg1<=lease_time(7 downto 0)&x"04";--leasetime(octet1)&length
		   elsif count_dhcp_a="0000110011" then--51
			reg1<=lease_time(23 downto 8);--leasetime(octet2&3)
			elsif count_dhcp_a="0000110100" then--52
			reg1<=x"ff"&lease_time(31 downto 24);--end & octet(4)			
			end if;
		when others=>
			null;
		end case;
	
	 end if;
	end process;
	
	
	
	crc_unit : entity work.crc
port map (clk=>clk,data_in=>crc_in,crc_en=>crc_en,rst=>crc_start_n,
			crc_out=>crc_out
			 );


	process(clk)
	begin
	if rising_edge(clk) then
	
	case q_state is
		when s_dhcp_o =>
			if count_dhcp_o="0000000000" then
			crc_t<="0";crc_in<=(others=>'0');
			crc_start_n<='1';
			else crc_start_n<='0';
			end if;
			
			if (count_dhcp_o>=2 and count_dhcp_o<=53)  then
				crc_in(15 + to_integer(crc_t)*16 downto to_integer(crc_t)*16)<= reg1;
				crc_t<=crc_t+1;
			end if;	
			
			if (count_dhcp_o>=2 and count_dhcp_o<=54) then
				if crc_t="1" then
				crc_en<='1';
				else crc_en<='0';
				end if;
			end if;
			
			if count_dhcp_o="0000110111" then--55
			crc_final<=crc_out;
			end if;
		when s_dhcp_a =>
		   if count_dhcp_a="0000000000" then
			crc_t<="0";crc_in<=(others=>'0');
			crc_start_n<='1';
			else crc_start_n<='0';
			end if;
			
			if (count_dhcp_a>=2 and count_dhcp_a<=53)  then
				crc_in(15 + to_integer(crc_t)*16 downto to_integer(crc_t)*16)<= reg1;
				crc_t<=crc_t+1;
			end if;	
			
			if (count_dhcp_a>=2 and count_dhcp_a<=54) then
				if crc_t="1" then
				crc_en<='1';
				else crc_en<='0';
				end if;
			end if;
			
			if count_dhcp_a="0000110111" then--55
			crc_final<=crc_out;
			end if;
		
		when others=> 
			null;
		
		end case;
		end if;
	end process;
	
	
	
	process(clk)
	begin
	if rising_edge(clk) then
		reg2<=reg1;
		reg3<=reg2;
		sop_out<='0';eop_out<='0';
		valid_out<='0';
	
		case q_state is 
			when s_dhcp_o =>
				if count_dhcp_o="0000000000" then send_t<="0";sop_out<='0';eop_out<='0';start_send_o<='0';
				elsif (count_dhcp_o="0000000100" or start_send_o='1') then
				start_send_o<='1';
				data_out(15 + to_integer(send_t)*16 downto to_integer(send_t)*16)<=reg3;
				send_t<= 1 + send_t;
					if count_dhcp_o="0000110111" then --55 when the last data before CRC goes out
					start_send_o<='0';
					end if;
				end if;
				
						--VALID_OUT
				if send_t="1" or count_dhcp_o="0000111001" then--57
					valid_out<='1';
					if count_dhcp_o="1011010010" then 
					send_t<=not send_t;
					end if;
				else 
					 valid_out<='0';
				end if;
							--SOP
				if count_dhcp_o="0000000101" then --5
					sop_out<='1';
				end if;
							--CRC
				if count_dhcp_o="0000111001" then -- 57
					data_out<=crc_final;--CRC OUTPUT
				end if;
							--EOP
				if count_dhcp_o="0000111001" then --57
					eop_out<='1';
				end if;
			
			when s_dhcp_a =>
				if count_dhcp_a="0000000000" then send_t<="0";sop_out<='0';eop_out<='0';start_send_o<='0';
				elsif (count_dhcp_a="0000000100" or start_send_o='1') then
				start_send_o<='1';
				data_out(15 + to_integer(send_t)*16 downto to_integer(send_t)*16)<=reg3;
				send_t<= 1 + send_t;
					if count_dhcp_a="0000110111" then --55 when the last data before CRC goes out
					start_send_o<='0';
					end if;
				end if;
				
						--VALID_OUT
				if send_t="1" or count_dhcp_a="0000111001" then--57
					valid_out<='1';
					if count_dhcp_a="1011010010" then 
					send_t<=not send_t;
					end if;
				else 
					 valid_out<='0';
				end if;
							--SOP
				if count_dhcp_a="0000000101" then --5
					sop_out<='1';
				end if;
							--CRC
				if count_dhcp_a="0000111001" then -- 57
					data_out<=crc_final;--CRC OUTPUT
				end if;
							--EOP
				if count_dhcp_a="0000111001" then --57
					eop_out<='1';
				end if;
			when others =>
				null;
			end case;
		end if;
		end process;
	


end Behavioral;

