`timescale 1ns / 1ps

module datastorage(
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
 
input reset,clock;
input validtodatastorage;
input datatoRAMsof, datatoRAMeof;
input [15:0] length;
input [15:0] datatoRAM;
input checksummatch;
output reg buffervalidin;
output reg [15:0] bufferdatain;

reg flag;

reg[3:0] counter;
reg[3:0] currentcount;
reg[15:0] lengtharray [15:0];

reg [15:0] datastoringRAM [32768 - 1:0];
reg [15:0] locationprev,location;

reg [15:0] index;
reg [15:0] startlocation;

always@(posedge clock or posedge reset)
begin
 if(reset == 1)
 begin
  buffervalidin <= 0;
 // bufferdatain <= 16'b0;
  location <= 16'b0;
  locationprev <= 16'b0;
  startlocation <= 16'b0;
  index <= 16'b0;
  flag <= 0;
  counter <= 4'b0;
  currentcount <= 4'b0;
 end//global reset finishes with this
 
 else if(clock == 1)
 begin
 
  if(datatoRAMsof == 1)//when start of frame comes keep taking data
  begin
  flag <= 1;
  lengtharray[currentcount + counter] <= (length/2);
  end
  
  if((datatoRAMsof == 1)||(flag == 1))
  begin
   if(validtodatastorage == 1)
	begin
	 datastoringRAM[location] <= datatoRAM;
	 location <= location + 1;
	end//end validtodatastorage
	
	if(datatoRAMeof == 1)
	begin
	 if(checksummatch != 1)
	 begin
	  location <= locationprev;
	 end
	 else if(checksummatch == 1)
	 begin
	  locationprev <= location + 1;
	  counter <= counter + 1;
	 end
	end//datatoRAMeof == 1
  end // end sof||flag
  
  if((counter > 0))
  begin
   if(buffervalidin != 1)
	begin
    buffervalidin <= 1;
	 index <= startlocation + lengtharray[currentcount];
	 bufferdatain <= datastoringRAM[startlocation];
	 startlocation <= startlocation + 1;
	end
   if((buffervalidin == 1)&&((startlocation + 1) != index))
   begin
	 if(startlocation == index)
	 begin
	  buffervalidin <= 0;
     counter <= counter + 4'b1111;
	 end
	 else
	 begin
 	 bufferdatain <= datastoringRAM[startlocation];
	 startlocation <= startlocation + 1;
    end
   end//buffervalidin == 1
   else if((buffervalidin == 1)&&((startlocation + 1) == index))
   begin
   currentcount <= currentcount + 1;
	startlocation <= startlocation + 1;
   end
  end//end counter > 0
  
 end//end clock
end//end always  

endmodule
