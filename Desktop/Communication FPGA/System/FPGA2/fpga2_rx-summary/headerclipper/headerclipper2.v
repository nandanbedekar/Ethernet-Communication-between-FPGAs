`timescale 1ns / 1ps

module headerclipper2(
    reset,
	 clock,
	 validin,
	 sof,
	 eof,
	 datain,
	 inthwaddr,
	 intipaddr,
	 intudpport,
	 arpvalidin,
	 arpsof,
	 arpeof,
	 arpdatain,
	 startvalid,
	 stopvalid,
	 sequencevalid,
	 sequenceno,
	 value,
	 dhcpvalidin,
	 dhcpsof,
	 dhcpeof,
	 dhcpdatain,
	 validtodatastorage,
	 datatoRAMsof,
	 datatoRAMeof,
	 length,
	 datatoRAM,
	 crcmatch,
	 checksummatch,
	 sourceaddr
    );
input reset,clock;
input sof,eof,validin;
input [31:0] datain;
input [47:0] inthwaddr;
input [31:0] intipaddr;
input [15:0] intudpport;
output arpvalidin;
output arpsof,arpeof;
output [15:0] arpdatain;
output startvalid, stopvalid, sequencevalid;
output [14:0] sequenceno;
output value;
output dhcpvalidin;
output dhcpsof, dhcpeof;
output [15:0] dhcpdatain;
output validtodatastorage;
output datatoRAMsof, datatoRAMeof;
output [15:0] length;
output [15:0] datatoRAM;
output crcmatch,checksummatch;
output [47:0] sourceaddr;

 
wire [15:0] ipdatain;
wire [15:0] udpdatain;
	  
ethernet2 e1(
     reset,
     clock,
	  validin,
	  sof,
	  eof,
	  datain,
	  inthwaddr,
	  ipvalidin,
	  ipsof,
	  ipeof,
	  ipdatain,
	  arpvalidin,
	  arpsof,
	  arpeof,
	  arpdatain,
	  crcmatch,
	  sourceaddr
	  );
	  
iprec2 i1(
     reset,
	  clock,
	  ipsof,
	  ipeof,
	  ipvalidin,
	  ipdatain,
	  intipaddr,
	  udpvalidin,
	  udpsof,
	  udpeof,
	  udpdatain
	  );
	  
udprec2 u1(
     reset,
	  clock,
	  udpsof,
	  udpeof,
	  udpvalidin,
	  udpdatain,
	  crcmatch,
	  intudpport,
	  startvalid,
	  stopvalid,
	  sequencevalid,
	  sequenceno,
	  value,
	  dhcpvalidin,
	  dhcpsof,
	  dhcpeof,
	  dhcpdatain,
	  validtodatastorage,
	  datatoRAMsof,
	  datatoRAMeof,
	  length,
	  datatoRAM,
	  checksummatch
	  );

endmodule
