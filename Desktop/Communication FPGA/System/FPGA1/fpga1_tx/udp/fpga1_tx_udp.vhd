library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity udp is
port (
		clk,rst:in std_logic;
 		
		--TX Unit
		data_out_adc:	in std_logic_vector(255 downto 0);
		expo_adc: 	  	in std_logic_vector(3 downto 0);
		valid_out_adc: in std_logic;
		
		sop_tx_ip: 		out std_logic;
		data_tx_ip: 	out std_logic_vector(15 downto 0);
		eop_tx_ip: 		out std_logic;
		w_addr_udp: 	out unsigned(10 downto 0)
		);
end udp;

architecture Behavioral of udp is

--TX Unit


signal count: unsigned(5 downto 0):="000000";
signal count_r: unsigned(9 downto 0):="0000000000";
signal start_sending: std_logic:='0';
signal s_ahead: std_logic:='0';
signal s_ahead_delay: unsigned(4 downto 0):="00000";
signal valid_data,valid_data_en,valid_data_en1: std_logic;
signal valid_data_on: std_logic:='0';


signal chk_sum1,chk_sum,chk_b: unsigned(15 downto 0):="0000000000000000";
signal chk_t: unsigned(0 downto 0):="0";
signal chk_t2: unsigned(0 downto 0);

signal sp: std_logic_vector(15 downto 0)			:="0000100000000000";
signal dp: std_logic_vector(15 downto 0)			:="0001000000000000";
signal length_udp: std_logic_vector(15 downto 0):="0000010101110010"; 
signal chk_1: unsigned(15 downto 0)					:="0001110101110010";

	--TX RAM
	signal data_in_ram: std_logic_vector(7 downto 0);
	signal w_addr_ram,r_addr_ram: unsigned( 10 downto 0):="00000000000";
	signal data_out_ram: std_logic_vector(15 downto 0);

--RX Unit



--Other
signal feedback:std_logic:='0';


begin 
	
	--RAM 
	ram_tx : entity work.ram
	port map (
	clk=>clk, rst=>rst, data_in_ram=>data_in_ram, data_out_ram=>data_out_ram,
	we_ram=>valid_data_en, r_addr_ram=>r_addr_ram, w_addr_ram=>w_addr_ram);
	
	--taking data in from ADC 
	valid_data <= valid_out_adc and (not feedback);
	
	valid_data_en1<=valid_data or valid_data_on;
	process(clk)
	begin
	if rising_edge(clk) then
	valid_data_en<=valid_data_en1;
		if count="100001" then --when w_addr_ram = 1385
				valid_data_en<='0';			
		end if;
	chk_t2<=chk_t;
	end if;
	end process;
	
	
	
	process(clk,rst)
		begin
			if(rst='1') then
			w_addr_ram<="00000000000";data_in_ram<="00000000";count<="000000";
			chk_sum1<="0000000000000000";chk_b<="0000000000000000";chk_t<="0";
			elsif rising_edge(clk) then
				
				s_ahead<='0';
				if(valid_data='1' or valid_data_on='1') then
					valid_data_on<='1';
					if count="000000" then
					data_in_ram<=data_out_adc(7 + to_integer(count)*8 downto to_integer(count)*8);
					count<=count+1;
						chk_b(7 + to_integer(chk_t)*8 downto to_integer(chk_t)*8)<=
						unsigned(data_out_adc(7 + to_integer(count)*8 downto to_integer(count)*8));
						chk_t<=chk_t+1;
					elsif count="000001" then
					data_in_ram<=data_out_adc(7 + to_integer(count)*8 downto to_integer(count)*8);
					w_addr_ram<=w_addr_ram+1;
					count<=count+1;
						chk_b(7 + to_integer(chk_t)*8 downto to_integer(chk_t)*8)<=
						unsigned(data_out_adc(7 + to_integer(count)*8 downto to_integer(count)*8));
						chk_t<=chk_t+1;
					elsif count<32 then
					data_in_ram<=data_out_adc(7 + to_integer(count)*8 downto to_integer(count)*8);
					w_addr_ram<=w_addr_ram+1;
					count<=count+1;
						chk_b(7 + to_integer(chk_t)*8 downto to_integer(chk_t)*8)<=
						unsigned(data_out_adc(7 + to_integer(count)*8 downto to_integer(count)*8));
						chk_t<=chk_t+1;
					elsif count="100000" then
					data_in_ram<="0000"&expo_adc(3 downto 0);
					w_addr_ram<=w_addr_ram+1;
					count<=count+1;
						chk_b(7 + to_integer(chk_t)*8 downto to_integer(chk_t)*8)<=
						"0000"&unsigned(expo_adc(3 downto 0));
						chk_t<=chk_t+1;
					elsif count="100001" then
					w_addr_ram<=w_addr_ram+1;
					valid_data_on<='0';
					count<="000000";
					--maintaining w_addr_ram for 1 packet of data = 1386 bytes
						if w_addr_ram="10101101001" then --when w_addr_ram = 1385
						w_addr_ram<= "00000000000";s_ahead<='1';
						end if;
				  end if;
				end if;	
				
				if chk_t="0" and chk_t2="1" then
				chk_sum1<=chk_sum1+chk_b;
				end if;
				
				if s_ahead_delay="00010" then
				chk_sum1<="0000000000000000";
				end if;
 			end if;
	end process;
	
	--s_ahead meachanism
	process(clk,rst)
	begin
	if 	rst='1' then s_ahead_delay<="00000";
	elsif rising_edge(clk) then 
		if s_ahead='1' then s_ahead_delay<="00001";		 
		elsif s_ahead_delay="00000" then null;
		else	s_ahead_delay<=s_ahead_delay + 1;
		end if;
	end if;
	end process;
	
	-- DATA TAKEN IN THE BUFFER STORAGE, NOW TO TRANSMIT IT TO THE IP PROCESSOR
	
	process(clk)
	begin
		if rising_edge(clk) then
			if s_ahead_delay="00010" then -- at 2 length, sp,dp and chksum ready
			chk_sum<=not (chk_1+chk_sum1);
			r_addr_ram<="00000000000";count_r<="0000000000";start_sending<='0';
			
			elsif s_ahead_delay="00100" then
			data_tx_ip<=sp;sop_tx_ip<='1';
			start_sending<='1';

			elsif s_ahead_delay="00101" then
			data_tx_ip<=dp;sop_tx_ip<='0';

			elsif s_ahead_delay="00110" then
			data_tx_ip<=length_udp;
			
			elsif s_ahead_delay="00111" then
			data_tx_ip<=std_logic_vector(chk_sum);
			r_addr_ram<=r_addr_ram+2;
			
			elsif (count_r<691 and start_sending='1')  then
			data_tx_ip<=data_out_ram;
			r_addr_ram<=r_addr_ram+2;
			count_r<=count_r+1;
			
			elsif count_r="1010110011" then--691 here r_addr_ram=1384, data_out is of 1382,data_tx of 1380
			data_tx_ip<=data_out_ram;
			count_r<=count_r+1;
			
			elsif count_r="1010110100" then--692
			eop_tx_ip<='1';
			data_tx_ip<=data_out_ram;
			start_sending<='0';
			count_r<=count_r+1;
			elsif count_r="1010110101" then--693
			count_r<="0000000000";
			eop_tx_ip<='0';
			
			end if;
	end if;
	end process;
	
	w_addr_udp<=w_addr_ram;
	


end Behavioral;



