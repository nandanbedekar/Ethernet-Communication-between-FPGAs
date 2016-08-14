`timescale 1ns / 1ps

module arprec2(
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
input reset,clock;
input arpvalidin;
input arpsof,arpeof;
input [15:0] arpdatain;
input crcmatch;
input [47:0] inthwaddr;
input [31:0] intipaddr;
output reg arpvalidout;
output reg [47:0] desthwaddr;
output reg [31:0] destipaddr;

reg flag;

reg count;

reg [3:0] counter;

always@(posedge clock or posedge reset)
begin
 if(reset == 1)
 begin
  arpvalidout <= 0;
  desthwaddr <= 48'b0;
  destipaddr <= 32'b0;
  counter <= 4'b0;
  flag <= 0;
  count <= 1'b0;
 end//global reset finished
  
 else if(clock == 1)
 begin
 
  if(arpsof == 1)
  begin
  flag <= 1;
  end
  
  if((flag == 1)||(arpsof == 1))
  begin
   if(arpvalidin == 1)
	begin
   case (counter)
	4'b0:begin
		  counter <= counter + 1;
	    if(arpdatain != 16'b1)
	    begin
	    counter <= 0;
	    flag <= 0;
       end
	  end
	4'b1: begin
		   counter <= counter + 1;
	   if(arpdatain != 16'b100000000000)
		begin
	   flag <= 0;
		counter <= 0;
		end

    	end
	4'b10:begin
		  counter <= counter + 1;
	  if(arpdatain != 16'b10000000110)
	  begin
	  flag <= 0;
	  counter <= 0;
	  end

	  end
	4'b11:begin
		  counter <= counter + 1;
	  if(arpdatain != 16'b1)
	  begin
	  flag <= 0;
	  counter <= 0;
	  end

	  end
	4'b100:begin
	 //starting the intake of sourceaddr
	  desthwaddr[15:0] <= arpdatain; 	 
     counter <= counter + 1;
     end
   4'b101:begin
	  desthwaddr[31:16] <= arpdatain;
     counter <= counter + 1;
     end
   4'b110:begin
     //intake of sourceaddr complete
	  desthwaddr[47:32] <= arpdatain;
     counter <= counter + 1;
     end
   4'b111:begin
     //starting the intake of source ip
	  destipaddr[15:0] <= arpdatain;
     counter <= counter + 1;
     end
   4'b1000:begin
     //ending the intake of sourceip
     destipaddr[31:16] <= arpdatain;
     counter <= counter + 1;
     end
   4'b1001:begin
	  //starting the intake of destaddr
     counter <= counter + 1;
	  /*if(arpdatain != inthwaddr[15:0])
	  begin
	   flag<=0;
		counter <= 4'b0;
	  end*/
     end
   4'b1010:begin
	   counter <= counter + 1;
		/*if(arpdatain != inthwaddr[31:16])
		begin
		 flag <= 0;
		 counter <= 4'b0;
		end*/
      end
   4'b1011:begin
      //ending the intake of the destaddr
      counter <= counter + 1;
		/*if(arpdatain != inthwaddr[47:32])
		begin
	   flag <= 0;
		counter <= 0;
		end*/
      end
   4'b1100:begin
      //starting the intake of destipaddr
		counter <= counter + 1;
		/*if(arpdatain[15:0] != intipaddr[15:0])
		begin
		flag <= 0;
		counter <= 4'b0;
		end*/
      end
   4'b1101:begin
      //ending the intake of destipaddr
		/*if((arpdatain[15:0] != intipaddr[31:16]))
		begin
	   flag <= 0;
		counter <= 4'b0;
		end*/
		count <= 1'b1;
		end
	endcase
	end//validin
	
	if((count == 1'b1)&&(flag == 1))
	begin
	 if(crcmatch == 1)
	 begin
	  arpvalidout <= 1;
	 end	
	end//end count
	
	if(arpvalidout == 1)
	begin
	 arpvalidout <= 0;
	 counter <= 4'b0;
	 flag <=0;
	 count <= 1'b0;
	end
	
  end//end sof||flag
 end// end clock
end//end always	
endmodule
