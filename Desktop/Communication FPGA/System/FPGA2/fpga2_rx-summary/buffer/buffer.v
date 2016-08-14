`timescale 1ns / 1ps

module buffer(
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
parameter buffersize = 262144; 
input clock,reset;
input buffervalidin;
input [15:0] bufferdatain;
input givedataout;
input [23:0] addressofdata;
output reg  [23:0] dataend,datastarting;
output reg buffervalidout;
output reg [15:0] bufferdataout;
reg [15:0] holddata [buffersize - 1:0];

always@(posedge clock or posedge reset)
begin
 if(reset == 1)
 begin
  dataend <= 23'b0;
  datastarting <= 23'b0;
  buffervalidout <= 0;
 // bufferdataout <= 16'b0;
 end//global reset is finished
 
 
 else if(clock == 1)
 begin
  if(buffervalidin == 1)
  begin
	dataend <= dataend + 1;
   holddata[dataend] <= bufferdatain;
  end
  if(givedataout == 1)
  begin
   if(addressofdata == datastarting)
	begin
	 datastarting <= datastarting + 1;
	end
	bufferdataout <= holddata[addressofdata];
	buffervalidout <= 1;
  end
  else
  begin
   buffervalidout <= 0;
  end
   
 end
end 
endmodule
