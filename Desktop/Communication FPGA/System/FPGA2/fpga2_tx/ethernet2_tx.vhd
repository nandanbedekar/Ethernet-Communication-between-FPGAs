library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity ether2a_tx is

port(
		clk,rst:					in 		std_logic;
		mac_addr_fpga2:		in			std_logic_vector(47 downto 0);
		
		--Rx unit to Tx unit ETHER
		
		ping_valid: 			in	 		std_logic;
		seq_counter:			in 		std_logic_vector(15 downto 0);
		
		valid_arp:				in	   	std_logic;
		ip_dest1_arp: 			in 		std_logic_vector(31 downto 0);
		mac_dest1_arp:			in 		std_logic_vector(47 downto 0);
		
		stop_valid:				in 		std_logic;
		start_valid:			in 		std_logic;
		
		--buffer to ether
		pingit:					in 		std_logic;
		stopit:					in 		std_logic;
		startit:					in 		std_logic;
		--ether to mac
		sop_tx_mac: 			out 		std_logic;
		data_tx_mac: 			out 		std_logic_vector(31 downto 0);
		eop_tx_mac: 			out 		std_logic;
		valid_out: 				out 		std_logic;
		
		--Rx to Tx DHCP
		dhcp_o_valid:			in 		std_logic;
		dhcp_server_mac:		in 		std_logic_vector(47 downto 0);
		dhcp_server_ip:		in 		std_logic_vector(31 downto 0);
		dhcp_a_valid:			in 		std_logic;
		ip_addr_fpga2_dhcp:	in 		std_logic_vector(31 downto 0);
		lease_time:   			in 		std_logic_vector(31 downto 0);
		
		ping_number: 			out		unsigned(14 downto 0)
		);

end ether2a_tx;

architecture Behavioral of ether2a_tx is
--2: IP
	signal ip_addr_fpga2:				std_logic_vector(31 downto 0);
--1: IP and MAC
	signal ip_addr_fpga1:				std_logic_vector(31 downto 0);
	signal mac_addr_fpga1: 				std_logic_vector(47 downto 0);


--CRC
	signal crc_in,crc_out,crc_final:	std_logic_vector(31 downto 0);
	signal crc_en: 					  	std_logic:='0';
	signal crc_start_n: 					std_logic:='1';
	signal crc_t: 							unsigned(0 downto 0):="0";

--SOP delay 
	signal count: 							unsigned(9 downto 0):="0000000000";

--Header
	signal leng_type: 					std_logic_vector(15 downto 0);
	--ARP Handling
	signal count_arp: 					unsigned(9 downto 0);
	signal arp:								std_logic_vector(1 downto 0):="00";
	
	
--pinging
	signal count_ping: 					unsigned(9 downto 0);
	signal seq_rec: 						std_logic_vector(14 downto 0):="000000000000001";
	signal seq_sent: 						unsigned(14 downto 0):="000000000000001";
	signal pinging:						std_logic;
	signal pinging1:						std_logic;
	signal ping_hold:						std_logic;

--stoping
	signal count_stop: 					unsigned(9 downto 0);
	signal stopping:						std_logic;
	signal stopping1:						std_logic;
	signal stop_hold:						std_logic;

--starting
	signal count_start: unsigned(9 downto 0);
	signal starting:						std_logic;
	signal starting1:						std_logic;
	signal start_hold:					std_logic;

--Sending Data Out
	signal reg1,reg2,reg3: 				std_logic_vector(15 downto 0);
	signal start_send_i,start_send_o:std_logic:='0';
	signal send_t:							unsigned(0 downto 0):="0";

--IP header
	signal version :				    	std_logic_vector(3 downto 0):="0100";
	signal ip_header_length : 	  		std_logic_vector(3 downto 0):="0101";
	signal type_of_serv : 				std_logic_vector(7 downto 0):="00000000";
	signal length_ip : 					std_logic_vector(15 downto 0):="0000000000011110";--30---
	signal identi : 						std_logic_vector(15 downto 0):="0000000000000001";
	signal flag_ip: 						std_logic_vector(2 downto 0):="000";
	signal offset: 						std_logic_vector(12 downto 0):="0000000000000";---
	signal ttl: 							std_logic_vector(7 downto 0):="00000101";--5--
	signal protocol: 						std_logic_vector(7 downto 0):="00010001";
	signal header_chksum: 				unsigned(15 downto 0):="0000000000000000";---to be defined
	signal source_ip2: 					std_logic_vector(31 downto 0):="00000101100001010000010110000111";---to be defined
	signal desti_ip1: 					std_logic_vector(31 downto 0):="00000101100001000000010110001000";---to be defined
	
	signal source_dest_ip_sum:			unsigned(15 downto 0):="0000000000000000";
	signal source_ip_sum: 				unsigned(15 downto 0):="0000000000000000";
	signal dest_ip_sum: 					unsigned(15 downto 0):="0000000000000000";

--UDP Header
	signal sp2: 							std_logic_vector(15 downto 0)			:="0001000000000000";--4096
	signal dp1: 							std_logic_vector(15 downto 0)			:="0000100000000000";--2048
	signal length_udp: 				 	std_logic_vector(15 downto 0):="0000000000001010";--10 
	signal udp_chksum: 					unsigned(15 downto 0);
	signal udp_chksum_seq:				std_logic_vector(15 downto 0);

--DHCP
	signal count_dhcp_d:					unsigned(9 downto 0);
	signal count_dhcp_r:					unsigned(9 downto 0);
	signal lease_time1:					unsigned(31 downto 0);
	signal lease_time2:					unsigned(31 downto 0);
	signal dhcp_toggle_r:				std_logic_vector(1 downto 0);
	signal lease: 							std_logic_vector(1 downto 0);
	signal mac_addr2_sum:				unsigned(15 downto 0);

type fsm_states is (s_idle,s_dhcp_d,s_dhcp_r,s_arp,s_ping,s_stop,s_start,s_data);
signal q_state: fsm_states;

begin

--FSM States Contorller
	process(rst,clk)
	begin
		if rst='1' then
			q_state<=s_idle;
			dhcp_toggle_r<="00";
		elsif rising_edge(clk) then
			if q_state=s_idle then--from s_idle to s_busy
				if lease="00" then
				q_state<=s_dhcp_d;
				elsif lease="01" then
				q_state<=s_dhcp_r;
				elsif arp="01" then
				q_state<=s_arp;
					
				elsif lease(1) = '1' and arp = "10" then
					if pinging='1' and ((count_ping>950 and count_ping<=1023) or count_ping="0000000000") then
					q_state<=s_ping;
					elsif stopping='1' and ((count_stop>950 and count_stop<=1023) or count_stop="0000000000") then
					q_state<=s_stop;
					elsif starting='1' and ((count_start>950 and count_start<=1023) or count_start="0000000000")  then
					q_state<=s_start;
					elsif lease="10" then
					q_state<=s_dhcp_r;
					else
					q_state<=s_idle;
					end if;
				end if;
			
			else --from s_busy to s_idle
				if count_dhcp_d="1111111100" then--end count
					q_state<=s_idle;
				end if;
				
				
				if lease="01" or dhcp_toggle_r="01" then--long
					if count_dhcp_r="0111111111" then
						q_state<=s_idle;
						dhcp_toggle_r<="00";
					end if;
					if dhcp_a_valid='1' then
						dhcp_toggle_r<="01";
					end if;
				elsif lease="10" or dhcp_toggle_r="10" then--short
					if count_dhcp_r="0000111111" then
						q_state<=s_idle;
						dhcp_toggle_r<="00";
					end if;
					if dhcp_a_valid='1' then
						if q_state=s_dhcp_r then
							dhcp_toggle_r<="10";
							else
							dhcp_toggle_r<="00";
						end if;
					end if;
				end if;	
				
				if count_arp ="0001000000" then
					q_state<=s_idle;
				end if;
				if count_ping ="0000011111" or (count_ping="0000000000" and pinging='0' and q_state=s_ping) then
					q_state<=s_idle;
				end if;
				if count_stop ="0000011111" or (count_stop="0000000000" and stopping='0' and q_state=s_stop) then
					q_state<=s_idle;
				end if;
				if count_start="0000011111" or (count_start="0000000000" and starting='0' and q_state=s_start) then
					q_state<=s_idle;
				end if;
		  end if;
		end if;
	end process;
		
--Count Tracker
process(rst,clk)
	begin
	if rst='1' then
	count_arp<="0000000000";count_dhcp_d<="0000000000";count_dhcp_r<="0000000000";
	length_udp<="0000000000000000";
	elsif rising_edge(clk) then 
	 case q_state is
		when s_idle => 
			count<="0000000000";count_arp<="0000000000";
			count_dhcp_d<="0000000000";count_dhcp_r<="0000000000";
			length_udp<="0000000000000000";
			length_ip<="0000000000000000";
		when s_dhcp_d =>
			count_dhcp_d<=count_dhcp_d+1;
			if count_dhcp_d="1111111100" then--end count
				count_dhcp_d<="0000000000";
			end if;
			length_udp<="0000000000111010";--58
			udp_chksum<="100011001000101"+mac_addr2_sum;--4545+mac_sum
			header_chksum<="0001000101011010"+"0000000001001110";--rest_header_sum+ip_sums+78
			length_ip<="0000000001001110";
		when s_dhcp_r =>
			if lease="01" or dhcp_toggle_r="01" then	--put a long timeout
				count_dhcp_r<=count_dhcp_r+1;
				if count_dhcp_r="1111111111" then
					count_dhcp_r<="0000000000";
				end if;
				
			elsif lease="10" or dhcp_toggle_r="10" then
				count_dhcp_r<=count_dhcp_r+1;		 --put a short timeout
				if count_dhcp_r="1111111111" then--short timeout
				count_dhcp_r<="0000000000";
				end if;
			end if;
				length_udp<="0000000000111010";--58
				udp_chksum<="100011001000111"+mac_addr2_sum;--4647+mac_sum
				header_chksum<="0001000101011010"+"0000000001001110";--rest_header_sum+ip_sums+length
				length_ip<="0000000001001110";
		when s_arp =>
			count_arp<=count_arp+1;
			if count_arp ="0001000000" then
				count_arp<="0000000000";
			end if;
		when s_ping =>
			length_udp<="0000000000001010";
			udp_chksum<=unsigned(udp_chksum_seq)+6154;--rest_sum+seq_counter_sum
			header_chksum<="0001000101011010"+source_dest_ip_sum+"0000000000011110";--rest_header_sum+ip_sums+length
			length_ip<="0000000000011110";
		when s_stop =>
			length_udp<="0000000000001010";
			header_chksum<="0001000101011010"+source_dest_ip_sum+"0000000000011110";--rest_header_sum+ip_sums+length
			length_ip<="0000000000011110";
		when s_start =>
			length_udp<="0000000000001010";
			header_chksum<="0001000101011010"+source_dest_ip_sum+"0000000000011110";--rest_header_sum+ip_sums+length
			length_ip<="0000000000011110";
		when others =>
		null;
    end case;
	 
	end if;
	end process;

--lease time config
	process(clk,rst)
	begin
	if rst='1' then
	lease_time1<=(others=>'0');
	elsif rising_edge(clk) then
		
		if lease_time1>0 then
		lease_time1<=lease_time1-1;
		end if;
		source_ip_sum<=unsigned(ip_addr_fpga2(15 downto 0))+unsigned(ip_addr_fpga2(31 downto 16));
		dest_ip_sum<=unsigned(ip_addr_fpga1(15 downto 0))+unsigned(ip_addr_fpga1(31 downto 16));
		source_dest_ip_sum<=source_ip_sum+dest_ip_sum;

		udp_chksum_seq<=std_logic_vector(seq_sent)&"0";
		mac_addr2_sum<=unsigned(mac_addr_fpga2(15 downto 0))+unsigned(mac_addr_fpga2(31 downto 16))+unsigned(mac_addr_fpga2(47 downto 32));
	
		if dhcp_a_valid='1' then
		ip_addr_fpga2<=ip_addr_fpga2_dhcp;
		lease_time1<=unsigned(lease_time);
		lease_time2<=unsigned(lease_time);
		end if;
	end if;
	end process;
	
	
	
	
	
--Input to FSM Controller

	process(rst,clk)
	begin	
		if rst='1' then
		lease<="00";arp<="00";
		
		elsif rising_edge(clk) then
		
		case lease is
		when "00" =>
			if dhcp_o_valid='1' then
			lease<="01";
			end if;
		when "01" =>
			if dhcp_a_valid='1' then
			lease<="11";
			end if;
		when "10" =>
			if dhcp_a_valid='1' then
			lease<="11";
			elsif lease_time1="00000000000000000000000000000001" then ---here put lease expiry things
			lease<="00";
			end if;
		when "11" =>
			if lease_time1<(lease_time2)/2 then---here put mid lease thing
			lease<="10";
			end if;
		when others=> 
			null;
		end case;
		
		if valid_arp='1' then
		arp<="01";
		mac_addr_fpga1<=mac_dest1_arp;
		ip_addr_fpga1<=ip_dest1_arp;
		end if;
		
		if q_state=s_arp then
			if count_arp="0000011111" then
			arp<="10";
			end if;
		end if;
	 

	 end if;			  
	end process;	









--Pingit,stopit and startit
	process(clk,rst)
	begin
	if rst='1' then
	count_ping<="0000000000";ping_hold<='0';
	count_stop<="0000000000";stop_hold<='0';
	count_start<="0000000000";start_hold<='0';
	seq_sent<="000000000000001";
	
	elsif rising_edge(clk) then
	
	if (q_state=s_idle and pinging='1') or ping_hold='1' then
		count_ping<=count_ping+1;
		ping_hold<='1';
			if pinging='0' and count_ping="1111111110" then--1022
			ping_hold<='0';count_ping<="0000000000";
			elsif count_ping="1111111110" then
			seq_sent<=seq_sent+1;
			end if;
	end if;
	
	if (q_state=s_idle and stopping='1') or stop_hold='1' then
		count_stop<=count_stop+1;
		stop_hold<='1';
			if stopping='0' and count_stop="1111111110" then--1023
			stop_hold<='0';count_stop<="0000000000";
			end if;
	end if;
	
	if (q_state=s_idle and starting='1') or start_hold='1' then
		count_start<=count_start+1;
		start_hold<='1';
			if starting='0' and count_start="1111111110" then--1023
			start_hold<='0';count_start<="0000000000";
			end if;
	end if;
	
	end if;
	end process;
	
	
	
	
	
	--pinging, starting and stopping: 1 from ping-it to ping_valid
	process(clk,rst)
	begin
	if rst='1' then
	pinging1<='0';stopping1<='0';starting1<='0';
	elsif rising_edge(clk) then
		if pingit ='1' then
		pinging1<='1';
		elsif ping_valid='1' then
		pinging1<='0';
		end if;
	
		if stopit ='1' then
		stopping1<='1';
		elsif stop_valid='1' then
		stopping1<='0';
		end if;
	
		if startit ='1' then
		starting1<='1';
		elsif start_valid='1' then
		starting1<='0';
		end if;	
	end if;
	end process;
	pinging<=pingit or pinging1;
	stopping<=stopit or stopping1;
	starting<=startit or starting1;
	
	
--Processing the ping time
	process(rst,clk)
	begin
	if rst='1' then
	ping_number<="000000000000000";
	elsif rising_edge(clk) then
		if ping_valid='1' then
		seq_rec<=seq_counter(15 downto 1);
		ping_number<=seq_sent-unsigned(seq_counter(15 downto 1))+1;
		end if;		
	end if;
	end process;
	
	




--1. Sending Data Out to REG1 --- VERIFIED!
	process(clk)
	begin
	if rising_edge(clk) then
		case q_state is
		when s_dhcp_d =>--sending dhcp Discovery
			if count_dhcp_d="0000000001" then--1
			reg1<="0101010101010101";--preamble
			elsif (count_dhcp_d<4 and count_dhcp_d>1) then
			reg1<="0101010101010101";--preamble
			elsif count_dhcp_d="0000000100" then--4
			reg1<="1101010101010101";--preamble
			elsif count_dhcp_d="0000000101" then--5
			reg1<=x"ffff";--target MAC
			elsif count_dhcp_d="0000000110" then--6
			reg1<=x"ffff";--target MAC
			elsif count_dhcp_d="0000000111" then--7
			reg1<=x"ffff";--target MAC
			
			elsif count_dhcp_d="0000001000" then--8
			reg1<=mac_addr_fpga2(15 downto 0);--sender MAC
			elsif count_dhcp_d="0000001001" then--9
			reg1<=mac_addr_fpga2(31 downto 16);--sender MAC
			elsif count_dhcp_d="0000001010" then--10
			reg1<=mac_addr_fpga2(47 downto 32);--sender MAC
			elsif count_dhcp_d="0000001011" then--11
			reg1<="0000000001101000";--reg1<=leng_type;
			
			--IP  header
			elsif count_dhcp_d="0000001100" then--12
			reg1<=type_of_serv&ip_header_length&version;
			elsif count_dhcp_d="0000001101" then--13
			reg1<=length_ip;
			elsif count_dhcp_d="0000001110" then--14
			reg1<=identi;
			elsif count_dhcp_d="0000001111" then--15
			reg1<=flag_ip&offset;
			elsif count_dhcp_d="0000010000" then--16
			reg1<=protocol&ttl;
			elsif count_dhcp_d="0000010001" then--17
			reg1<=not std_logic_vector(header_chksum);
			elsif count_dhcp_d="0000010010" then--18
			reg1<=x"0000";--reg1<=source_ip2(15 downto 0);
			elsif count_dhcp_d="0000010011" then--19
			reg1<=x"0000";--reg1<=source_ip2(31 downto 16);
			elsif count_dhcp_d="0000010100" then--20
			reg1<=x"0000";--reg1<=desti_ip1(15 downto 0);
			elsif count_dhcp_d="0000010101" then--21
			reg1<=x"0000";--reg1<=desti_ip1(31 downto 16);

			
			--UDP header
			
			elsif count_dhcp_d="0000010110" then--22
			reg1<=sp2;--68
			elsif count_dhcp_d="0000010111" then--23
			reg1<=dp1;--67
			elsif count_dhcp_d="0000011000" then--24
			reg1<=length_udp;--58 in decimal
			elsif count_dhcp_d="0000011001" then--25
			reg1<=not std_logic_vector(udp_chksum);
			
			--DHCP
			elsif count_dhcp_d="0000011010" then--26
			reg1<=x"0101";--htype&op
			elsif count_dhcp_d="0000011011" then--27
			reg1<=x"0006";--hops&hlen
			elsif count_dhcp_d="0000011100" then--28
			reg1<=x"abcd";--xid lsb
			elsif count_dhcp_d="0000011101" then--29
			reg1<=x"0001";--xid msb
			elsif count_dhcp_d="0000011110" then--30
			reg1<=x"0000";--secs
			elsif count_dhcp_d="0000011111" then--31
			reg1<=x"8000";--flags
			elsif count_dhcp_d="0000100000" then--32
			reg1<=x"0000";--clint ip lsb
			elsif count_dhcp_d="0000100001" then--33
			reg1<=x"0000";--clint ip msb
			elsif count_dhcp_d="0000100010" then--34
			reg1<=x"0000";--your ip lsb
			elsif count_dhcp_d="0000100011" then--35
			reg1<=x"0000";--your ip msb
			elsif count_dhcp_d="0000100100" then--36
			reg1<=x"0000";--server ip lsb
			elsif count_dhcp_d="0000100101" then--37
			reg1<=x"0000";--server ip msb
			elsif count_dhcp_d="0000100110" then--38
			reg1<=x"0000";--gateway ip lsb
			elsif count_dhcp_d="0000100111" then--39
			reg1<=x"0000";--gateway ip msb
			elsif count_dhcp_d="0000101000" then--40
			reg1<=mac_addr_fpga2(15 downto 0);--clint mac (15 0)
			elsif count_dhcp_d="0000101001" then--41
			reg1<=mac_addr_fpga2(31 downto 16);--clint mac (31 16)
			elsif count_dhcp_d="0000101010" then--42
			reg1<=mac_addr_fpga2(47 downto 32);--clint mac (47 32)
			elsif count_dhcp_d="0000101011" then--43
			reg1<=x"0000";--clint mac 0000 stuff
			elsif count_dhcp_d="0000101100" then--44
			reg1<=x"0000";--clint mac 0000 stuff
			elsif count_dhcp_d="0000101101" then--45
			reg1<=x"0000";--clint mac 0000 stuff
			elsif count_dhcp_d="0000101110" then--46
			reg1<=x"0000";--clint mac 0000 stuff
			elsif count_dhcp_d="0000101111" then--47
			reg1<=x"0000";--clint mac 0000 stuff
			elsif count_dhcp_d="0000110000" then--48
			reg1<=x"0000";--Option PAD&PAD
			elsif count_dhcp_d="0000110001" then--49
			reg1<=x"01"&x"35";--Option DHCP Type:53 octet 2&1
			elsif count_dhcp_d="0000110010" then--50
			reg1<=x"0001";--Option DHCP Type:53 octet 3
		   end if;
			
			--length and checksum udp
			--length_udp<=; udp_chksum<=;

		when s_dhcp_r =>--sending dhcp Discovery
			if count_dhcp_r="0000000001" then--1
			reg1<="0101010101010101";--preamble
			elsif (count_dhcp_r<4 and count_dhcp_r>1) then
			reg1<="0101010101010101";--preamble
			elsif count_dhcp_r="0000000100" then--4
			reg1<="1101010101010101";--preamble
			elsif count_dhcp_r="0000000101" then--5
			reg1<=dhcp_server_mac(15 downto 0);--target MAC
			elsif count_dhcp_r="0000000110" then--6
			reg1<=dhcp_server_mac(31 downto 16);--target MAC
			elsif count_dhcp_r="0000000111" then--7
			reg1<=dhcp_server_mac(47 downto 32);--target MAC
			
			elsif count_dhcp_r="0000001000" then--8
			reg1<=mac_addr_fpga2(15 downto 0);--sender MAC
			elsif count_dhcp_r="0000001001" then--9
			reg1<=mac_addr_fpga2(31 downto 16);--sender MAC
			elsif count_dhcp_r="0000001010" then--10
			reg1<=mac_addr_fpga2(47 downto 32);--sender MAC
			elsif count_dhcp_r="0000001011" then--11
			reg1<="0000000001101000";--reg1<=leng_type;
			
			--IP  header
			elsif count_dhcp_r="0000001100" then--12
			reg1<=type_of_serv&ip_header_length&version;
			elsif count_dhcp_r="0000001101" then--13
			reg1<=length_ip;
			elsif count_dhcp_r="0000001110" then--14
			reg1<=identi;
			elsif count_dhcp_r="0000001111" then--15
			reg1<=flag_ip&offset;
			elsif count_dhcp_r="0000010000" then--16
			reg1<=protocol&ttl;
			elsif count_dhcp_r="0000010001" then--17
			reg1<=not std_logic_vector(header_chksum);
			elsif count_dhcp_r="0000010010" then--18
			reg1<=x"0000";--source IP
			elsif count_dhcp_r="0000010011" then--19
			reg1<=x"0000";--source IP
			elsif count_dhcp_r="0000010100" then--20
			reg1<=dhcp_server_ip(15 downto 0);--target IP
			elsif count_dhcp_r="0000010101" then--21
			reg1<=dhcp_server_ip(31 downto 16);--target IP

			--UDP header
			elsif count_dhcp_r="0000010110" then--22
			reg1<=sp2;--0800
			elsif count_dhcp_r="0000010111" then--23
			reg1<=dp1;--1000
			elsif count_dhcp_r="0000011000" then--24
			reg1<=length_udp;--58
			elsif count_dhcp_r="0000011001" then--25
			reg1<=not std_logic_vector(udp_chksum);
			
			--DHCP
			elsif count_dhcp_r="0000011010" then--26
			reg1<=x"0101";--htype&op
			elsif count_dhcp_r="0000011011" then--27
			reg1<=x"0006";--hops&hlen
			elsif count_dhcp_r="0000011100" then--28
			reg1<=x"abcd";--xid lsb
			elsif count_dhcp_r="0000011101" then--29
			reg1<=x"0001";--xid msb
			elsif count_dhcp_r="0000011110" then--30
			reg1<=x"0000";--secs
			elsif count_dhcp_r="0000011111" then--31
			reg1<=x"8000";--flags
			elsif count_dhcp_r="0000100000" then--32
			reg1<=x"0000";--clint ip lsb
			elsif count_dhcp_r="0000100001" then--33
			reg1<=x"0000";--clint ip msb
			elsif count_dhcp_r="0000100010" then--34
			reg1<=x"0000";--your ip lsb
			elsif count_dhcp_r="0000100011" then--35
			reg1<=x"0000";--your ip msb
			elsif count_dhcp_r="0000100100" then--36
			reg1<=x"0000";--server ip lsb
			elsif count_dhcp_r="0000100101" then--37
			reg1<=x"0000";--server ip msb
			elsif count_dhcp_r="0000100110" then--38
			reg1<=x"0000";--gateway ip lsb
			elsif count_dhcp_r="0000100111" then--39
			reg1<=x"0000";--gateway ip msb
			elsif count_dhcp_r="0000101000" then--40
			reg1<=mac_addr_fpga2(15 downto 0);--clint mac (15 0)
			elsif count_dhcp_r="0000101001" then--41
			reg1<=mac_addr_fpga2(31 downto 16);--clint mac (31 16)
			elsif count_dhcp_r="0000101010" then--42
			reg1<=mac_addr_fpga2(47 downto 32);--clint mac (47 32)
			elsif count_dhcp_r="0000101011" then--43
			reg1<=x"0000";--clint mac 0000 stuff
			elsif count_dhcp_r="0000101100" then--44
			reg1<=x"0000";--clint mac 0000 stuff
			elsif count_dhcp_r="0000101101" then--45
			reg1<=x"0000";--clint mac 0000 stuff
			elsif count_dhcp_r="0000101110" then--46
			reg1<=x"0000";--clint mac 0000 stuff
			elsif count_dhcp_r="0000101111" then--47
			reg1<=x"0000";--clint mac 0000 stuff
			elsif count_dhcp_r="0000110000" then--48
			reg1<=x"0000";--Option PAD&PAD
			elsif count_dhcp_r="0000110001" then--49
			reg1<=x"01"&x"35";--Option DHCP Type:53 octet 2&1
			elsif count_dhcp_r="0000110010" then--50
			reg1<=x"0003";--Option DHCP Type:53 octet 3
		   end if;
			
			--length and checksum udp
			--length_udp<=; udp_chksum<=;
	
		when s_arp =>
			if count_arp="0000000001" then--1
			reg1<="0101010101010101";--preamble
			elsif (count_arp<4 and count_arp>1) then
			reg1<="0101010101010101";--preamble
			elsif count_arp="0000000100" then--4
			reg1<="1101010101010101";--preamble
			elsif count_arp="0000000101" then--5
			reg1<=mac_addr_fpga1(15 downto 0);--target mac
			elsif count_arp="0000000110" then--6
			reg1<=mac_addr_fpga1(31 downto 16);--target mac
			elsif count_arp="0000000111" then--7
			reg1<=mac_addr_fpga1(47 downto 32);--target mac
			
			elsif count_arp="0000001000" then--8
			reg1<=mac_addr_fpga2(15 downto 0);--mac address of source
			elsif count_arp="0000001001" then--9
			reg1<=mac_addr_fpga2(31 downto 16);--mac addr of source
			elsif count_arp="0000001010" then--10
			reg1<=mac_addr_fpga2(47 downto 32);--mac address of source
			elsif count_arp="0000001011" then--11
			reg1<="0000000000111000";--reg1<=leng_type;
			
			--ARP Start
			elsif count_arp="0000001100" then--12
			reg1<=x"0001";	--Hardware Type ARP
			elsif count_arp="0000001101" then--13
			reg1<=x"0800";	--Protocol Type ARP
			elsif count_arp="0000001110" then--14
			reg1<=x"0406";	--Protocol Addr Length&Hardware Addr Length
			elsif count_arp="0000001111" then--15
			reg1<=x"0002";	--OpCode = 2 for ARP Reply
			
			elsif count_arp="0000010000" then--16
			reg1<=mac_addr_fpga2(15 downto 0);	--sender HW Addr 
			elsif count_arp="0000010001" then--17
			reg1<=mac_addr_fpga2(31 downto 16);	--sender HW Addr
			elsif count_arp="0000010010" then--18
			reg1<=mac_addr_fpga2(47 downto 32);	--sender HW Addr
			elsif count_arp="0000010011" then--19
			reg1<=ip_addr_fpga2(15 downto 0);	--sender IP Address
			elsif count_arp="0000010100" then--20
			reg1<=ip_addr_fpga2(31 downto 16);	--sender IP Address
			
			elsif count_arp="0000010101" then--21
			reg1<=mac_addr_fpga1(15 downto 0);	 --target HW Addr
			elsif count_arp="0000010110" then--22
			reg1<=mac_addr_fpga1(31 downto 16); --target HW Addr
			elsif count_arp="0000010111" then--23
			reg1<=mac_addr_fpga1(47 downto 32); --target HW Addr
			elsif count_arp="0000011000" then--24
			reg1<=ip_addr_fpga1(15 downto 0);	--target IP Address
			elsif count_arp="0000011001" then--25
			reg1<=ip_addr_fpga1(31 downto 16);	--target IP Address
			elsif count_arp="0000011010" then--26 
			reg1<=x"0000";-- bit stuffing to make ARP 30 bytes, ARP+ETHER-CRC=52 bytes :)
			end if;
			
			
		when s_ping =>
			if count_ping="0000000001" then--1
			reg1<="0101010101010101";--preamble
			elsif (count_ping<4 and count_ping>1) then
			reg1<="0101010101010101";--preamble
			elsif count_ping="0000000100" then--4
			reg1<="1101010101010101";--preamble
			elsif count_ping="0000000101" then--5
			reg1<=mac_addr_fpga1(15 downto 0);--target MAC
			elsif count_ping="0000000110" then--6
			reg1<=mac_addr_fpga1(31 downto 16);--target MAC
			elsif count_ping="0000000111" then--7
			reg1<=mac_addr_fpga1(47 downto 32);--target MAC
			
			elsif count_ping="0000001000" then--8
			reg1<=mac_addr_fpga2(15 downto 0);--sender MAC
			elsif count_ping="0000001001" then--9
			reg1<=mac_addr_fpga2(31 downto 16);--sender MAC
			elsif count_ping="0000001010" then--10
			reg1<=mac_addr_fpga2(47 downto 32);--sender MAC
			elsif count_ping="0000001011" then--11
			reg1<="0000000001101000";--reg1<=leng_type;
			
			--IP  header
			elsif count_ping="0000001100" then--12
			reg1<=type_of_serv&ip_header_length&version;
			elsif count_ping="0000001101" then--13
			reg1<=length_ip;
			elsif count_ping="0000001110" then--14
			reg1<=identi;
			elsif count_ping="0000001111" then--15
			reg1<=flag_ip&offset;
			elsif count_ping="0000010000" then--16
			reg1<=ttl&protocol;
			elsif count_ping="0000010001" then--17
			reg1<=not std_logic_vector(header_chksum);
			elsif count_ping="0000010010" then--18
			reg1<=ip_addr_fpga2(15 downto 0);--source IP
			elsif count_ping="0000010011" then--19
			reg1<=ip_addr_fpga2(31 downto 16);--source IP
			elsif count_ping="0000010100" then--20
			reg1<=ip_addr_fpga1(15 downto 0);--target IP
			elsif count_ping="0000010101" then--21
			reg1<=ip_addr_fpga1(31 downto 16);--target IP

			
			--UDP header
			
			elsif count_ping="0000010110" then--22
			reg1<=sp2;--1000
			elsif count_ping="0000010111" then--23
			reg1<=dp1;--0800
			elsif count_ping="0000011000" then--24
			reg1<=length_udp;--000a
			
			elsif count_ping="0000011001" then--25
			reg1<=not std_logic_vector(udp_chksum);
			
			elsif count_ping="0000011010" then--26
			reg1<=std_logic_vector(seq_sent)&"0";--reg1<=sequence(15) + counter2(1);
		   end if;
		
		when s_stop=>
			if count_stop="0000000001" then--1
			reg1<="0101010101010101";--preamble
			elsif (count_stop<4 and count_stop>1) then
			reg1<="0101010101010101";--preamble
			elsif count_stop="0000000100" then--4
			reg1<="1101010101010101";--preamble
			elsif count_stop="0000000101" then--5
			reg1<=mac_addr_fpga1(15 downto 0);--target MAC
			elsif count_stop="0000000110" then--6
			reg1<=mac_addr_fpga1(31 downto 16);--target MAC
			elsif count_stop="0000000111" then--7
			reg1<=mac_addr_fpga1(47 downto 32);--target MAC
			
			elsif count_stop="0000001000" then--8
			reg1<=mac_addr_fpga2(15 downto 0);--sender MAC
			elsif count_stop="0000001001" then--9
			reg1<=mac_addr_fpga2(31 downto 16);--sender MAC
			elsif count_stop="0000001010" then--10
			reg1<=mac_addr_fpga2(47 downto 32);--sender MAC
			elsif count_stop="0000001011" then--11
			reg1<="0000000001101000";--reg1<=leng_type;
			
				--IP  header
			elsif count_stop="0000001100" then--12
			reg1<=type_of_serv&ip_header_length&version;
			elsif count_stop="0000001101" then--13
			reg1<=length_ip;
			elsif count_stop="0000001110" then--14
			reg1<=identi;
			elsif count_stop="0000001111" then--15
			reg1<=flag_ip&offset;
			elsif count_stop="0000010000" then--16
			reg1<=ttl&protocol;
			elsif count_stop="0000010001" then--17
			reg1<=not std_logic_vector(header_chksum);
			elsif count_stop="0000010010" then--18
			reg1<=ip_addr_fpga2(15 downto 0);--source IP
			elsif count_stop="0000010011" then--19
			reg1<=ip_addr_fpga2(31 downto 16);--source IP
			elsif count_stop="0000010100" then--20
			reg1<=ip_addr_fpga1(15 downto 0); --target IP
			elsif count_stop="0000010101" then--21
			reg1<=ip_addr_fpga1(31 downto 16); --target IP

			
			--UDP header
			
			elsif count_stop="0000010110" then--22
			reg1<=sp2;--1000
			elsif count_stop="0000010111" then--23
			reg1<=dp1;--0800
			elsif count_stop="0000011000" then--24
			reg1<=length_udp;--000a
			elsif count_stop="0000011001" then--25
			reg1<=not x"180b";
			
			elsif count_stop="0000011010" then--26
			reg1<="000000000000000"&"1";--reg1<=000000000000000(15) + 1(1);
			end if;
		
		when s_start=>
			if count_start="0000000001" then--1
			reg1<="0101010101010101";--preamble
			elsif (count_start<4 and count_start>1) then
			reg1<="0101010101010101";--preamble
			elsif count_start="0000000100" then--4
			reg1<="1101010101010101";--preamble
			elsif count_start="0000000101" then--5
			reg1<=mac_addr_fpga1(15 downto 0);--target MAC
			elsif count_start="0000000110" then--6
			reg1<=mac_addr_fpga1(31 downto 16);--target MAC
			elsif count_start="0000000111" then--7
			reg1<=mac_addr_fpga1(47 downto 32);--target MAC
			
			elsif count_start="0000001000" then--8
			reg1<=mac_addr_fpga2(15 downto 0);--sender MAC
			elsif count_start="0000001001" then--9
			reg1<=mac_addr_fpga2(31 downto 16);--sender MAC
			elsif count_start="0000001010" then--10
			reg1<=mac_addr_fpga2(47 downto 32);--sender MAC
			elsif count_start="0000001011" then--11
			reg1<="0000000001101000";--reg1<=leng_type;
			
				--IP  header
			elsif count_start="0000001100" then--12
			reg1<=type_of_serv&ip_header_length&version;
			elsif count_start="0000001101" then--13
			reg1<=length_ip;
			elsif count_start="0000001110" then--14
			reg1<=identi;
			elsif count_start="0000001111" then--15
			reg1<=flag_ip&offset;
			elsif count_start="0000010000" then--16
			reg1<=ttl&protocol;
			elsif count_start="0000010001" then--17
			reg1<=not std_logic_vector(header_chksum);
			elsif count_start="0000010010" then--18
			reg1<=ip_addr_fpga2(15 downto 0);--source IP
			elsif count_start="0000010011" then--19
			reg1<=ip_addr_fpga2(31 downto 16);--source IP
			elsif count_start="0000010100" then--20
			reg1<=ip_addr_fpga1(15 downto 0); --target IP
			elsif count_start="0000010101" then--21
			reg1<=ip_addr_fpga1(31 downto 16); --target IP

			
			--UDP header
			
			elsif count_start="0000010110" then--22
			reg1<=sp2;--1000
			elsif count_start="0000010111" then--23
			reg1<=dp1;--0800
			elsif count_start="0000011000" then--24
			reg1<=length_udp;--000a
			elsif count_start="0000011001" then--25
			reg1<=not x"180a";
			
			elsif count_start="0000011010" then--26
			reg1<="000000000000000"&"0";--reg1<=000000000000000(15) + 1(1);
			end if;
	
	  when others =>
		null;
		end case;
	end if;
	end process;




--2. CRC   --- VERIFIED!
crc_unit : entity work.crc
port map (clk=>clk,data_in=>crc_in,crc_en=>crc_en,rst=>crc_start_n,
			crc_out=>crc_out
			 );

process(clk)
begin
if rising_edge(clk) then
	case q_state is 
		when s_dhcp_d =>
			if count_dhcp_d="0000000000" then
			crc_t<="0";crc_in<=(others=>'0');
			crc_start_n<='1';
			else crc_start_n<='0';
			end if;
			
			if (count_dhcp_d>=2 and count_dhcp_d<=51)  then
				crc_in(15 + to_integer(crc_t)*16 downto to_integer(crc_t)*16)<= reg1;
				crc_t<=crc_t+1;
			end if;	
			
			if (count_dhcp_d>=2 and count_dhcp_d<=52) then
				if crc_t="1" then
				crc_en<='1';
				else crc_en<='0';
				end if;
			end if;
			
			if count_dhcp_d="0000110101" then--29 +24 = 53
			crc_final<=crc_out;
			end if;
		when s_dhcp_r =>
		   if count_dhcp_r="0000000000" then
			crc_t<="0";crc_in<=(others=>'0');
			crc_start_n<='1';
			else crc_start_n<='0';
			end if;
			
			if (count_dhcp_r>=2 and count_dhcp_r<=51)  then
				crc_in(15 + to_integer(crc_t)*16 downto to_integer(crc_t)*16)<= reg1;
				crc_t<=crc_t+1;
			end if;	
			
			if (count_dhcp_r>=2 and count_dhcp_r<=52) then
				if crc_t="1" then
				crc_en<='1';
				else crc_en<='0';
				end if;
			end if;
			
			if count_dhcp_r="0000110101" then--29 +24 = 53
			crc_final<=crc_out;
			end if;
		
	  when s_arp =>
			if count_arp="0000000000" then
				crc_t<="0";crc_in<=(others=>'0');
				crc_start_n<='1';
			else crc_start_n<='0';
			end if;
			
			if (count_arp>=2 and count_arp<=27)  then
				crc_in(15 + to_integer(crc_t)*16 downto to_integer(crc_t)*16)<= reg1;
				crc_t<=crc_t+1;
			end if;	
			
			if (count_arp>=2 and count_arp<=28) then
				if crc_t="1" then
				crc_en<='1';
				else crc_en<='0';
				end if;
			end if;
			
			if count_arp="0000011101" then--29 
			crc_final<=crc_out;
			end if;
			
		
		when s_ping =>
			if count_ping="0000000000" then
				crc_t<="0";crc_in<=(others=>'0');
				crc_start_n<='1';
			else crc_start_n<='0';
			end if;
			
			if (count_ping>=2 and count_ping<=27)  then
				crc_in(15 + to_integer(crc_t)*16 downto to_integer(crc_t)*16)<= reg1;
				crc_t<=crc_t+1;
			end if;	
			
			if (count_ping>=2 and count_ping<=28) then
				if crc_t="1" then
				crc_en<='1';
				else crc_en<='0';
				end if;
			end if;
			
			if count_ping="0000011101" then--29
			crc_final<=crc_out;
			end if;
			
		when s_stop =>
			if count_stop="0000000000" then
				crc_t<="0";crc_in<=(others=>'0');
				crc_start_n<='1';
			else crc_start_n<='0';
			end if;
			
			if (count_stop>=2 and count_stop<=27)  then
				crc_in(15 + to_integer(crc_t)*16 downto to_integer(crc_t)*16)<= reg1;
				crc_t<=crc_t+1;
			end if;	
			
			if (count_stop>=2 and count_stop<=28) then
				if crc_t="1" then
				crc_en<='1';
				else crc_en<='0';
				end if;
			end if;
			if count_stop="0000011101" then--29 
			crc_final<=crc_out;
			end if;
		
		when s_start =>
			if count_start="0000000000" then
				crc_t<="0";crc_in<=(others=>'0');
				crc_start_n<='1';
			else crc_start_n<='0';
			end if;
			
			if (count_start>=2 and count_start<=27)  then
				crc_in(15 + to_integer(crc_t)*16 downto to_integer(crc_t)*16)<= reg1;
				crc_t<=crc_t+1;
			end if;	
			
			if (count_start>=2 and count_start<=28) then
				if crc_t="1" then
				crc_en<='1';
				else crc_en<='0';
				end if;
			end if;
			if count_start="0000011101" then--29 
			crc_final<=crc_out;
			end if;
	when others =>
		null;
	end case;
end if;

end process;




--3. Reg1->Reg2->Reg3->Output   --VERIFIED!

	process(clk)
	begin
	if rising_edge(clk) then
		reg2<=reg1;
		reg3<=reg2;
		sop_tx_mac<='0';eop_tx_mac<='0';
		valid_out<='0';
		
		case q_state is 
		when s_dhcp_d =>
			if count_dhcp_d="0000000000" then send_t<="0";sop_tx_mac<='0';eop_tx_mac<='0';start_send_o<='0';
			elsif (count_dhcp_d="0000000100" or start_send_o='1') then
			start_send_o<='1';
			data_tx_mac(15 + to_integer(send_t)*16 downto to_integer(send_t)*16)<=reg3;
			send_t<= 1 + send_t;
				if count_dhcp_d="0000110101" then --53 when the last data before CRC goes out
				start_send_o<='0';
				end if;
			end if;
			
					--VALID_OUT
			if send_t="1" or count_dhcp_d="0000110111" then--55
				valid_out<='1';
				if count_dhcp_d="1011010010" then 
				send_t<=not send_t;
				end if;
			else 
				 valid_out<='0';
			end if;
						--SOP
			if count_dhcp_d="0000000101" then --5
				sop_tx_mac<='1';
			end if;
						--CRC
			if count_dhcp_d="0000110111" then -- 55
				data_tx_mac<=crc_final;--CRC OUTPUT
			end if;
						--EOP
			if count_dhcp_d="0000110111" then --31+24=55
				eop_tx_mac<='1';
			end if;
			
		when s_dhcp_r =>
			if count_dhcp_r="0000000000" then send_t<="0";sop_tx_mac<='0';eop_tx_mac<='0';start_send_o<='0';
			elsif (count_dhcp_r="0000000100" or start_send_o='1') then
			start_send_o<='1';
			data_tx_mac(15 + to_integer(send_t)*16 downto to_integer(send_t)*16)<=reg3;
			send_t<= 1 + send_t;
				if count_dhcp_r="0000110101" then --53 when the last data before CRC goes out
				start_send_o<='0';
				end if;
			end if;
			
					--VALID_OUT
			if send_t="1" or count_dhcp_r="0000110111" then--55
				valid_out<='1';
				if count_dhcp_r="1011010010" then 
				send_t<=not send_t;
				end if;
			else 
				 valid_out<='0';
			end if;
						--SOP
			if count_dhcp_r="0000000101" then --5
				sop_tx_mac<='1';
			end if;
						--CRC
			if count_dhcp_r="0000110111" then -- 55
				data_tx_mac<=crc_final;--CRC OUTPUT
			end if;
						--EOP
			if count_dhcp_r="0000110111" then --31+24=55
				eop_tx_mac<='1';
			end if;
			
		when s_arp =>
			if count_arp="0000000000" then send_t<="0";sop_tx_mac<='0';eop_tx_mac<='0';start_send_o<='0';
			elsif (count_arp="0000000100" or start_send_o='1') then
			start_send_o<='1';
			data_tx_mac(15 + to_integer(send_t)*16 downto to_integer(send_t)*16)<=reg3;
			send_t<= 1 + send_t;
				if count_arp="0000011101" then --29 when the last data before CRC goes out
				start_send_o<='0';
				end if;
			end if;
			
					--VALID_OUT
			if send_t="1" or count_arp="0000011111" then--31
				valid_out<='1';
			else 
				 valid_out<='0';
			end if;
						--SOP
			if count_arp="0000000101" then --5
				sop_tx_mac<='1';
			end if;
						--CRC
			if count_arp="0000011111" then -- 31
				data_tx_mac<=crc_final;--CRC OUTPUT
			end if;
						--EOP
			if count_arp="0000011111" then --31
				eop_tx_mac<='1';
			end if;
								
			
		when s_ping =>
			if count_ping="0000000000" then send_t<="0";sop_tx_mac<='0';eop_tx_mac<='0';start_send_o<='0';
			elsif (count_ping="0000000100" or start_send_o='1') then
			start_send_o<='1';
			data_tx_mac(15 + to_integer(send_t)*16 downto to_integer(send_t)*16)<=reg3;
			send_t<= 1 + send_t;
				if count_ping="0000011101" then --29 when the last data before CRC goes out
				start_send_o<='0';
				end if;
			end if;
			
					--VALID_OUT
			if send_t="1" or count_ping="0000011111" then--31
				valid_out<='1';
			else
				 valid_out<='0';
			end if;
						--SOP
			if count_ping="0000000101" then --5
				sop_tx_mac<='1';
			end if;
						--CRC
			if count_ping="0000011111" then -- 31
				data_tx_mac<=crc_final;--CRC OUTPUT
			end if;
						--EOP
			if count_ping="0000011111" then --31
				eop_tx_mac<='1';
			end if;
		
		when s_stop =>
			if count_stop="0000000000" then send_t<="0";sop_tx_mac<='0';eop_tx_mac<='0';start_send_o<='0';
			elsif (count_stop="0000000100" or start_send_o='1') then
			start_send_o<='1';
			data_tx_mac(15 + to_integer(send_t)*16 downto to_integer(send_t)*16)<=reg3;
			send_t<= 1 + send_t;
				if count_stop="0000011101" then --29 when the last data before CRC goes out
				start_send_o<='0';
				end if;
			end if;
			
					--VALID_OUT
			if send_t="1" or count_stop="0000011111" then--31
				valid_out<='1';
			else 
				 valid_out<='0';
			end if;
						--SOP
			if count_stop="0000000101" then --5
				sop_tx_mac<='1';
			end if;
						--CRC
			if count_stop="0000011111" then -- 31
				data_tx_mac<=crc_final;--CRC OUTPUT
			end if;
						--EOP
			if count_stop="0000011111" then --31
				eop_tx_mac<='1';
			end if;
		
		when s_start =>
			if count_start="0000000000" then send_t<="0";sop_tx_mac<='0';eop_tx_mac<='0';start_send_o<='0';
			elsif (count_start="0000000100" or start_send_o='1') then
			start_send_o<='1';
			data_tx_mac(15 + to_integer(send_t)*16 downto to_integer(send_t)*16)<=reg3;
			send_t<= 1 + send_t;
				if count_start="0000011101" then --29 when the last data before CRC goes out
				start_send_o<='0';
				end if;
			end if;
			
					--VALID_OUT
			if send_t="1" or count_start="0000011111" then--31
				valid_out<='1';
			else 
				 valid_out<='0';
			end if;
						--SOP
			if count_start="0000000101" then --5
				sop_tx_mac<='1';
			end if;
						--CRC
			if count_start="0000011111" then -- 31
				data_tx_mac<=crc_final;--CRC OUTPUT
			end if;
						--EOP
			if count_start="0000011111" then --31
				eop_tx_mac<='1';
			end if;
		when others =>
			null;
		end case;
	end if;
	end process;

end Behavioral;

