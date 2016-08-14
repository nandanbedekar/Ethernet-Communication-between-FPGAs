`timescale 1ns / 1ps

module FPGA1(
    reset,
	 clock,
	 
	 //TX part
    adcdataout,
    adcexpout,
	 adcvalidout,
	 
	 fpga1validout,
	 fpga1sof,
	 fpga1eof,
	 fpga1dataout,
	 
	 //RX part
	 validin,
	 sof,
	 eof,
	 datain,
	 
	 //Common to RX and Tx
	// inthwaddr,
	 intudpport
    );
	 
input reset, clock;
input adcvalidout;
input [3:0] adcexpout;
input [255:0] adcdataout;
input validin;
input sof, eof;
input [31:0] datain;
//input [47:0] inthwaddr;
input [15:0] intudpport;

output fpga1validout;
output fpga1sof, fpga1eof;
output [31:0] fpga1dataout;
reg [47:0] inthwaddr = 48'h1aef93b4c001;

wire arpvalidout;
wire [47:0] desthwaddr;
wire [31:0] destipaddr;
wire startvalid, stopvalid,sequencevalid;
wire [14:0] sequenceno;
wire value;
wire dhcpoffer, dhcpacknowledge;
wire [31:0] YIAddr;
wire [31:0] SIAddr;
wire [31:0] ipleasetime;
wire [47:0] sourceaddr;

wire [15:0] seqcounter;
assign seqcounter[0] = value;
assign seqcounter[15:1] = sequenceno;  

summary uut(
 reset,
 clock,
 validin,
 sof,
 eof,
 datain,
 inthwaddr,
 intudpport,
 arpvalidout,
 desthwaddr,
 destipaddr,
 startvalid,
 stopvalid,
 sequencevalid,
 sequenceno,
 value,
 dhcpoffer,
 dhcpacknowledge,
 YIAddr,
 SIAddr,
 ipleasetime,
 sourceaddr
 );
 
fpga1_tx TX (
   .rst(reset),
	.clk(clock),
   .data_out_adc(adcdataout),
   .expo_adc(adcexpout),	
   .valid_out_adc(adcvalidout),
	.sop_tx_mac(fpga1sof),
	.data_tx_mac(fpga1dataout),
	.eop_tx_mac(fpga1eof),
	.mac_addr_fpga1(inthwaddr),
	.valid_out(fpga1validout),
	.valid_arp(arpvalidout),
	.ip_dest2_arp(destipaddr),
	.mac_dest2_arp(desthwaddr),
	.ping_valid(sequencevalid),
	.seq_counter(seqcounter),
	.stop_valid(stopvalid),
	.start_valid(startvalid),
	.dhcp_o_valid(dhcpoffer),
	.dhcp_server_mac(sourceaddr),
	.dhcp_server_ip(SIAddr),
	.dhcp_a_valid(dhcpacknowledge),
	.ip_addr_fpga1_dhcp(YIAddr),
	.lease_time(ipleasetime)
	);
	
endmodule
