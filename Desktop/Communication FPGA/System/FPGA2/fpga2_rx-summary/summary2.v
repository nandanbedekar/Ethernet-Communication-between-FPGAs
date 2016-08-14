`timescale 1ns / 1ps

module summary2(
    reset,			//control -> all modules
	 clock,
	 
	 validin,		//control,input -> headerclipper 
	 sof,
	 eof,
	 datain,
	 
	 givedataout,   //control -> buffer
	 addressofdata,
	 
	 inthwaddr,		 //control -> headerclipper
	 intudpport,
	 
	 arpvalidout,   //output -> arprec
	 desthwaddr,
	 destipaddr,
	 
	 startvalid,    //output -> headerclipper's udp
	 stopvalid,
	 sequencevalid,
	 sequenceno,
	 value,
	 
	 dhcpoffer,		 //output -> dhcp
	 dhcpacknowledge,
	 YIAddr,
	 SIAddr,
	 ipleasetime,
	 
	 buffervalidout,//output -> buffer
	 bufferdataout,
	 datastarting,
	 dataend,
	 
	 sourceaddr     //output -> headerclipper's ethernet
    );
input reset,clock;
input validin,sof,eof;
input [31:0] datain;
input givedataout;
input [23:0] addressofdata;
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
output buffervalidout;
output [15:0] bufferdataout;
output [23:0] datastarting;
output [23:0] dataend;
output [47:0] sourceaddr;

//Wire coming out from the headerclipping module
wire [15:0] arpdatain;
wire [15:0] dhcpdatain;
wire [15:0] length;
wire [15:0] datatoRAM; 

//wire coming out from the datastorage module
wire [15:0] bufferdatain;

//wires coming out from dhcpmodule module


//wires coming out from the arp module

//wires coming out from the buffer module



reg [31:0] intipaddr;


headerclipper2 h1 (
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

arprec2 a1(
      reset,
   	clock,
		arpvalidin,
		arpsof,
		arpeof,
		arpdatain,
		crcmatch,
		inthwaddr,
		intipaddr,
		arpvalidout,
		desthwaddr,
		destipaddr
		);
		
dhcprec2 d1 (
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
		 
buffer b1 (
       reset,
		 clock,
		 buffervalidin,
		 bufferdatain,
		 givedataout,
		 addressofdata,
		 datastarting,
		 dataend,
		 buffervalidout,
		 bufferdataout
		 );
		 
datastorage ds1 (
          reset,
			 clock,
			 validtodatastorage,
			 datatoRAMsof,
			 datatoRAMeof,
			 length,
			 datatoRAM,
			 checksummatch,
			 buffervalidin,
			 bufferdatain
			 );
		
		
always@(posedge clock or posedge reset)
begin
 if(reset == 1)
 begin
  intipaddr <= 31'b0;
 end
 
 else if(clock == 1)
 begin
  if(dhcpacknowledge == 1)
  begin
   intipaddr <= YIAddr;
  end
 end
end//always
		endmodule
