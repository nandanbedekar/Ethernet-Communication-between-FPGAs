`timescale 1ns / 1ps

module iprec2(
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
input reset, clock;
input ipvalidin,ipsof,ipeof;
input [15:0] ipdatain;
input [31:0] intipaddr;
output reg udpvalidin;
output reg udpsof,udpeof;
output reg [15:0] udpdatain;

//reg [15:0] totallength;
//reg [31:0] fragmentation;
//reg [7:0] timetolive;
//reg [7:0] protocol;
reg [15:0] headerchecksum;

reg [3:0] counter;

reg flag;

always@(posedge clock or posedge reset)
begin
 if(reset == 1)
 begin
  udpvalidin <= 0;
  udpdatain <= 16'b0;
//  typeofservice <= 8'b0;
//  fragmentation <= 32'b0;
//  timetolive <= 8'b0;
//  protocol <= 8'b0;
  headerchecksum <= 16'b0;
  flag <= 0;
  counter <= 4'b0;
  udpsof <= 0;
  udpeof <= 0;
  
 end //global reset is finshed
 
 else if(clock == 1)
 begin
  
  if(ipsof == 1)
  begin
   flag <= 1;
  end
  
  if((flag == 1)||(ipsof == 1))
  begin
   if(ipvalidin == 1)
	begin
	case (counter)
	4'b0:
	begin
	 //version check
	 counter <= counter + 1;
	 headerchecksum <= headerchecksum + ipdatain;
	 if(ipdatain[3:0] != 4'b100)
	 begin
	  flag <= 0;
	  headerchecksum <= 16'b0;
	  counter <= 4'b0;
	 end
	 //IHL check
	 if(ipdatain[7:4] != 4'b101)
	 begin
	  flag <= 0;
	  headerchecksum <= 16'b0;
	  counter <= 4'b0;
    end
    //type of serivce is taken
   end
   4'b1:
	begin
	//total length check
	counter <= counter + 1;
	headerchecksum <= headerchecksum + ipdatain;
	end
	4'b10:
	begin
	//fragmentation check
	counter <= counter + 1;
	headerchecksum <= headerchecksum + ipdatain;
	if(ipdatain != 16'b1)
	begin
	 flag <= 0;
	 headerchecksum <= 16'b0;
	 counter <= 4'b0;
	end
	end
	4'b11:
	begin
	//fragmentation
	counter <= counter + 1;
	headerchecksum <= headerchecksum + ipdatain;
	if(ipdatain != 16'b0)
	begin
	 flag <= 0;
	 headerchecksum <= 0;
	 counter <= 0;
	end
	end
   4'b100:
	begin
	counter <= counter + 1;
	headerchecksum <= headerchecksum + ipdatain;
	//timetolive <= ipdatain[7:0];
	//protocol <= ipdatain[15:8];
	if(ipdatain[7:0] == 8'b0)
	begin
	 flag<=0;
	 headerchecksum <= 16'b0;
	 counter <= 4'b0;
	end
	/*if(ipdatain[15:8] != 8'b10001)
	begin
	 flag <= 0;
	 headerchecksum <= 16'b0;
	 counter <= 4'b0;
	end*/
	end
	4'b101:
	begin
	//headerchecksum
	counter <= counter + 1;
	headerchecksum <= headerchecksum + ipdatain;
	end
	4'b110:
	begin
	//source ip
	counter <= counter + 1;
	headerchecksum <= headerchecksum + ipdatain;
	end
	4'b111:
	begin
	//source ip
	counter <= counter + 1;
	headerchecksum <= headerchecksum + ipdatain;
	end
	4'b1000:
	begin
	//dest ip
   counter <= counter + 1;
	headerchecksum <= headerchecksum + ipdatain;
	/* if(ipdatain[15:0] != intipaddr[15:0])
	 begin
	 flag <= 0;
	 headerchecksum <= 16'b0;
	 counter <= 4'b0;
	 end*/
	end
	4'b1001:
	begin
	//dest ip
	 counter <= counter + 1;
	 headerchecksum <= headerchecksum + ipdatain;
	 /*if(ipdatain[15:0] != intipaddr[31:16])
	 begin
	 flag <= 0;
	 headerchecksum <= 16'b0;
	 counter <= 16'b0;
	 end*/
	end
	default:
	begin
	 if(/*(headerchecksum == 16'b1111111111111111)&&*/(counter == 16'b1010))
	 begin
	 udpsof <= 1;
	 udpvalidin <= 1;
	 udpdatain <= ipdatain;
	 counter <= 16'b1011;
	 end
	 else if(/*(headerchecksum != 16'b1111111111111111)&&*/(counter == 16'b1010))
	 begin
	  flag <= 0;
	  headerchecksum <= 16'b0;
     counter <= 4'b0;	  
	 end
	 if(udpsof == 1)
	 begin
	  udpsof <= 0;
	 end
	 if(ipeof == 1)
	 begin
	  udpeof <= 1;
	  udpdatain <= ipdatain;
	 end
	 else if(udpvalidin == 1)
	 begin
	 udpdatain <= ipdatain;
	 end
	 end//default
	 endcase
	end//end validin
  end//flag||sof
  
  if(udpeof == 1)
	 begin
	  udpeof <= 0;
	  udpvalidin <= 0;
	  counter <= 4'b0;
	  headerchecksum <= 16'b0;
	  flag <= 0;
	 end
 end //clock == 1
end //always
  


endmodule
