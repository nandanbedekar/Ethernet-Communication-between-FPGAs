`timescale 1ns / 1ps

module udprec(
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
	 
	 checksummatch
    );
input reset,clock;
input udpvalidin,udpsof,udpeof;
input [15:0] udpdatain;
input crcmatch;
input [15:0] intudpport;
output reg startvalid, stopvalid, sequencevalid;
output reg [14:0] sequenceno;
output reg value;
output reg dhcpsof,dhcpeof;
output reg dhcpvalidin;
output reg [15:0] dhcpdatain;
output reg checksummatch;

reg [15:0] destudpport;
reg [15:0] length;

reg [15:0] checksum;

reg flag;

reg mode;

reg [2:0] counter;
	 
always@(posedge clock or posedge reset)
begin
 if(reset == 1)
 begin
 startvalid <= 0;
 stopvalid <= 0;
 sequencevalid <= 0;
 sequenceno <= 15'b0;
 value <= 0;
 dhcpvalidin <= 0;
 dhcpdatain <= 16'b0;
 dhcpsof <= 0;
 dhcpeof <= 0;
 checksummatch <= 0;
 destudpport <= 16'b0;
 checksum <= 16'b0;
 flag <= 0;
 mode <= 0;
 counter <= 3'b0;
 end //global reset is finished
 
 else if(clock == 1)
 begin
  
  if(udpsof == 1)
  begin
   flag <= 1;
  end
  
  if((udpsof == 1)||(flag == 1))
  begin
   if(udpvalidin == 1)
	begin
	 case(counter)
	 3'b0:
	 begin
	 checksum <= checksum + udpdatain;
	 counter <= counter + 1;
	 end
	 3'b1:
	 begin
	 counter <= counter + 1;
	 checksum <= checksum + udpdatain;
	 /*if(udpdatain != intudpport[7:0])
	 begin
	  flag<=0;
	  counter <= 4'b0;
	  checksum <= 16'b0;
	 end*/
	 end
	 3'b10:
	 begin
	  checksum <= checksum + udpdatain;
	  counter <= counter + 1;
	  length <= udpdatain;
	 end
	 3'b11:
	 begin
	  checksum <= checksum + udpdatain;
	  counter <= counter + 1;
	 end
	 3'b100:
	 begin
	 if((length == 16'b1010)&&(crcmatch == 1))
	 begin
	  if((checksum + udpdatain) == 16'b1111111111111111)
	  begin
	   checksummatch <= 1;
	  end
	  sequenceno <= udpdatain[15:1];
	  value <= udpdatain[0];
     mode <= 1;
	  if((udpdatain[15:1] == 15'b0)&&(udpdatain[0] == 0))
     begin
	   startvalid <= 1;
	  end
	  if((udpdatain[15:1] == 15'b0)&&(udpdatain[0] == 1))
	  begin
	   stopvalid <= 1;
	  end
	  if((udpdatain[15:1] != 15'b0)&&(udpdatain[0] == 0))
	  begin
	   sequencevalid <= 1;
	  end
	 end//length == 16'b1010
	 else if(length != 16'b1010)
	 begin
	  dhcpsof <= 1;
	  dhcpvalidin <= 1;
	  dhcpdatain <= udpdatain;
	  mode <= 0;
	  checksum <= checksum + udpdatain;
	 end//end else
	 counter <= counter + 1;
	end//3'b100
	
	3'b101:
	begin
	
	 if(mode == 0)
	 begin
	  if(dhcpvalidin == 1)
	  begin
	  dhcpdatain <= udpdatain;
	  checksum <= checksum + udpdatain;
	  end
	  if(dhcpsof == 1)
	  dhcpsof <= 0;
	  if(udpeof == 1)
	  begin
	   if(((checksum + udpdatain) == 16'b1111111111111111)&&(crcmatch == 1))
		begin
		 checksummatch <= 1;
		end
	   if(dhcpvalidin == 1)
	   begin
	   dhcpeof <= 1;
	   end
	  end//udpeof == 1
	  
    end//end mode 0
	 

	end//end 3'b101
  endcase
	
	end//validin
  end//sof||flag
	 
  if(mode == 0)
  begin
   if(checksummatch == 1)
	begin
	 checksummatch <= 0;
	end
   if(dhcpeof == 1)
   begin
	 counter <= 3'b0;
  	 checksum <= 16'b0;
	 dhcpeof <= 0;
	 dhcpvalidin <= 0;
	 flag <=0;
   end
  end	 
	 
  if((mode == 1)) //MODE 1
  begin
   if(checksummatch == 1)
	begin
	 checksummatch <= 0;
	end
   if(startvalid == 1)
	begin
	 startvalid <= 0;
	 counter <= 3'b0;
	 checksum <= 16'b0;
	 mode <= 0;
	 flag <= 0;
	end
	if(stopvalid == 1)
   begin
	 stopvalid <= 0;
	 counter <= 3'b0;
	 checksum <= 16'b0;
	 mode <= 0;
	 flag <= 0;
	end
	if(sequencevalid == 1)
	begin
	 sequencevalid <= 0;
	 counter <= 3'b0;
	 checksum <= 16'b0;
	 mode <= 0;
	 flag <= 0;
	end
  end//end mode == 1
 end//posedge clock ended
end // always
endmodule
