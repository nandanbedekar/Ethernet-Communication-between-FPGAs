`timescale 1ns / 1ps

module summary(
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
input reset,clock;
input validin;
input sof,eof;
input [31:0] datain;
input [47:0] inthwaddr;
input [15:0] intudpport;
output arpvalidout;
output [47:0] desthwaddr;
output [31:0] destipaddr;
output startvalid,stopvalid,sequencevalid;
output [14:0] sequenceno;
output value;
output dhcpoffer;
output dhcpacknowledge;
output [31:0] YIAddr;
output [31:0] SIAddr;
output [31:0] ipleasetime;
output [47:0] sourceaddr;

reg [31:0] intipaddr;

//Wire coming out from the headerclipping module
wire [15:0] arpdatain;
wire [15:0] dhcpdatain;

//wires coming out from dhcpmodule module

//wires coming out from the arp module


headerclipper h1 (
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
	 
	 crcmatch,
	 checksummatch,
	 
	 sourceaddr
	 );

arprec a1(
      reset,
   	clock,
		
		arpvalidin,
		arpsof,
		arpdatain,
		
		crcmatch,
		
		inthwaddr,
		intipaddr,
		
		arpvalidout,
		desthwaddr,
		destipaddr
		);
		
dhcprec d1 (
        reset,
		  clock,
		  
		  dhcpvalidin,
		  dhcpsof,
		  dhcpeof,
		  dhcpdatain,
		  
		  checksummatch,
		  
		  dhcpoffer,
		  dhcpacknowledge,
		  YIAddr,
		  SIAddr,
		  ipleasetime
		  );
		  
always@(posedge clock or posedge reset)
begin
 if(reset == 1)
 begin
  intipaddr <= 32'b0;
 end
 
 else if(clock == 1)
 begin
  if(dhcpacknowledge == 1)
  begin
   intipaddr <= YIAddr;
  end
 end
end//end always
		
endmodule
