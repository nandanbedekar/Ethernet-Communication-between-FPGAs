`timescale 1ns / 1ps

module ethernet2(
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
input reset,clock,validin;
input sof, eof;
input [31:0] datain;
input [47:0] inthwaddr;
output reg ipvalidin;
output reg ipsof, ipeof;
output reg [15:0] ipdatain;
output reg arpvalidin;
output reg arpsof, arpeof;
output reg [15:0] arpdatain;
output reg crcmatch;
output reg [47:0] sourceaddr;
	
reg[2:0] counter;
	 
reg crcen;
wire [31:0] crcstore;
reg [31:0] crcin;
reg [31:0] crc;

reg flag;

reg [15:0] store;
reg [15:0] temp;
reg toggle;

reg ping;
reg typeofdata;

crcgenerator c1 (
     clock,
	  crcen,
	  sof,
	  crcin,
	  crcstore
	  );

always@(posedge clock or posedge reset)
begin
 if(reset == 1)
 begin
  ipvalidin <= 0;
  ipsof <= 0;
  ipeof <= 0;
  ipdatain <= 16'b0;
  arpvalidin <= 0;
  arpsof <= 0;
  arpeof <= 0;
  arpdatain <= 16'b0;
  crcmatch <= 0;
  counter <= 3'b0;
  crcen <= 0;
  crcin <= 32'b0;
  crc <= 32'b0;
  flag <= 0;
  store <= 16'b0;
  temp <= 32'b0;
  toggle <= 0;
  ping <= 0;
  typeofdata <= 0;
  sourceaddr <= 48'b0;
 end//global reset is finished
 
 else if(clock == 1)
 begin
 
  if(sof == 1)//We have to keep storing data until eof comes
  begin
   flag <= 1;
  end
 
 if((flag == 1) || (sof == 1))
 begin
  if(validin == 1)
  begin
  crcen <= 1;
  crcin <= datain;
  case(counter)
  3'b0:
  begin
  //preamble[31:0] <= datain;
  counter <= counter + 1;
  if(datain != 32'b01010101010101010101010101010101)
  begin
   flag <=0;
	counter <=0;
  end
  end
  3'b1:
  begin
  //preamble[63:32] <= datain;
  counter <= counter + 1;
  if(datain != 32'b11010101010101010101010101010101)
  begin
   flag <=0;
	counter <=0;
  end
  end
  3'b10:
  begin
  //sourceaddr[31:0] <= datain;
  counter <= counter + 1;
  end
  3'b11:
  begin
  //sourceaddr[47:32] <= datain[15:0];
  //destaddr[15:0] <= datain[31:16];
  counter <= counter + 1;
  /*if(datain[31:16] != inthwaddr[15:0])
  begin
  flag <= 0;
  end*/
  end
  3'b100:
  begin
  //destaddr[47:16] <= datain;
  counter <= counter + 1;
  /*if(datain != inthwaddr[47:16])
  begin
  flag <= 0;
  end*/
  end
  3'b101:
  begin
  counter <= counter + 1;
  store <= datain[31:16];
  
  if(datain[15:0]== 16'b111000)
  begin
   ping <= 1;
  end
  else
  begin
   ping <= 0;
  end
  if(datain[31:16] == 16'b1)
  begin
   typeofdata <= 1;
  end
  else
  begin
   typeofdata <= 0;
  end
  
  end//3'b101
  default:
  begin
  //configuring the relevent validout
  if(arpsof == 1)
  begin
   arpsof <= 0;
  end
  if(ipsof == 1)
  begin
   ipsof <= 0;
  end
  if((typeofdata == 1)&&(ping == 1))
  begin
  	arpdatain <= store;
   arpvalidin <= 1;
   arpsof <= 1;
   ping <= 0;
  end
  if(typeofdata == 0)
  begin
  	ipdatain <= store;
	ipvalidin <= 1;
	ipsof <= 1;
	typeofdata <= 1;
  end
  
  if(eof == 1)
  begin
   crc <= datain;
	flag <= 0;
   if(arpvalidin == 1)
	begin
	 arpeof <= 1;
	end//end arpvalidin
	if(ipvalidin == 1)
	begin
	 ipeof <= 1;
	end//end ipvalidin
  end//end eof
  
  
  end//default
  endcase 

  end//end validin
  else
   begin
	crcen <= 0;
	end
  end//end sof||flag
  
  if((toggle == 0)&&((arpvalidin == 1)||(ipvalidin == 1)))
  begin
   temp <= datain[31:16];
   ipdatain <= datain[15:0];
	arpdatain <= datain [15:0];
	toggle <= !toggle;
  end
  if((toggle == 1)&&((arpvalidin == 1)||(ipvalidin == 1)))
  begin
   ipdatain <= temp[15:0];
	arpdatain <= temp [15:0];
   toggle <= !toggle;
  end
  
  if(ipeof == 1)
  begin
   ipeof <= 0;
	ipvalidin <= 0;
	toggle <= 0;
	if(crc == crcstore)
	begin
	 crcmatch <= 1;
	end
	else
	counter <= 0;
  end
  if(arpeof == 1)
  begin
   arpeof <= 0;
	arpvalidin <= 0;
	toggle <= 0;
	if(crc == crcstore)
	begin
	 crcmatch <= 1;
	end
	else
	counter <=0;
  end
  if(crcmatch == 1)
  begin
   crcmatch <= 0;
	counter <= 0;
  end
 end//end clock
end //always
endmodule
