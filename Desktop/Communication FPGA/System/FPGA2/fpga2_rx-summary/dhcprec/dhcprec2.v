`timescale 1ns / 1ps

module dhcprec2(
    reset,
	 clock,
	 validin,
	 sof,
	 eof,
	 datain,
	 checksummatch,
	 dhcpoffer,
	 dhcpacknowledge,
	 YIAddr,
	 SIAddr,
	 ipleasetime
    );
input reset,clock;
input validin,sof,eof;
input [15:0] datain;
input checksummatch;
output reg dhcpoffer;
output reg dhcpacknowledge;
output reg [31:0] YIAddr;
output reg [31:0] SIAddr;
output reg [31:0] ipleasetime;


reg [7:0] hlen;
reg [31:0] xids,CIAddr,GIAddr;
reg [15:0] secs,flags;
reg [127:0] CHAddr;

reg [4:0] counter;
reg [7:0] count;

reg [1:0] mode;

reg [31:0] serverid;
reg [127:0] intCHAddr;
reg [7:0] dhcpmssgtype;

reg [7:0] optionno,optionlength;

reg flag;


always@(posedge clock or posedge reset)
begin
 if(reset == 1)
 begin
 hlen <= 8'b0;
 counter <= 5'b0;
 xids <= 32'b0;
 CIAddr <= 32'b0;
 YIAddr <= 32'b0;
 GIAddr <= 32'b0;
 CHAddr <= 128'b0;
 SIAddr <= 32'b0;
 secs <= 16'b0;
 flags <= 16'b0;
 mode <= 2'b0;
 count <= 8'b0;
// subnetmask <= 64'b0;
// router <= 64'b0;
 intCHAddr <= 128'b0;
 serverid <= 32'b0;
 dhcpmssgtype <= 0;
 ipleasetime <= 7'b0;
 flag <= 0;
 optionno <= 8'b0;
 optionlength <= 8'b0;
 dhcpoffer <= 0;
 dhcpacknowledge <= 0;
 end
 
 else if(clock == 1)
 begin
 
  if( sof == 1) // when start of frame is detected keep taking data
  begin
   flag <= 1;
  end
  
  if((flag == 1)||(sof == 1))//flag == 1 started
  begin
  if((validin == 1))
  begin
  if(counter < 5'b10110)
  begin
   case(counter)
	5'b0: begin
	        counter <= counter + 1;
			  /*if(datain[7:0] != 8'b10)
           begin
           flag <= 0;
           end	*/
			  /*if(datain[15:8] != 8'b1)
			  begin
			  flag <= 0;
			  end*/
	       end
	5'b1: begin
	        counter <= counter + 1;
			  /*if(datain[7:0] != 8'b110)
			  begin
			  flag <= 0;
			  end*/
	       end
   5'b10: begin
	        counter <= counter + 1;
	        xids[15:0] <=  datain;
	        end
	5'b11: begin
	        counter <= counter + 1;
			  xids[31:16] <= datain;
	        end
	5'b100:begin
	         counter <= counter + 1;
	         secs <= datain;
	        end
   5'b101:begin
	         counter <= counter + 1;
	         flags <= datain;
	        end
   5'b110:begin
	         counter <= counter + 1;
	         CIAddr[15:0] <= datain;
	        end
	5'b111:begin
	         counter <= counter + 1;
	         CIAddr[31:16] <= datain; 
	        end
	5'b1000:begin
	          counter <= counter + 1;
	          YIAddr[15:0] <= datain;
	         end
	5'b1001:begin
	          counter <= counter + 1;
	          YIAddr[31:16] <= datain;
	         end
	5'b1010:begin
	          counter <= counter + 1;
	          SIAddr[15:0] <= datain;
	         end
	5'b1011:begin
	          counter <= counter + 1;
	          SIAddr[31:16] <= datain;
	         end
	5'b1100:begin
	          counter <= counter + 1;
	          //gateway starts
	         end
	5'b1101:begin
	          counter <= counter + 1;
	          //gateway ends
	         end
	5'b1110:begin
	          counter <= counter + 1;
	          CHAddr[15:0] <= datain;
				 /*if(datain != intCHAddr[15:0])
				 begin
				 flag <= 0;
				 counter <= 0;
				 end*/
				 end
	5'b1111:begin
	          counter <= counter + 1;
	          CHAddr[31:16] <= datain;
				 /*if(datain != intCHAddr[31:16])
				 begin
				 flag <= 0;
				 counter <= 0;
				 end*/
	         end
	5'b10000:begin
	           counter <= counter + 1;
	           CHAddr[47:32] <= datain;
				  /*if(datain != intCHAddr[47:32])
				  begin
				  flag <= 0;
				  counter <= 0;
				  end*/
	          end
	5'b10001:begin
	           counter <= counter + 1;
	           CHAddr[63:48] <= datain;
				  /*if(datain != intCHAddr[63:48])
				  begin
				  flag <= 0;
				  counter <= 0;
				  end*/
	          end
	5'b10010:begin
	           counter <= counter + 1;
	           CHAddr[79:64] <= datain;
				  /*if(datain != intCHAddr[79:64])
				  begin
				  flag <= 0;
				  counter <= 0;
				  end*/
	          end
	5'b10011:begin
	           counter <= counter + 1;
	           CHAddr[95:80] <= datain;
				  /*if(datain != intCHAddr[95:80])
				  begin
				  flag <= 0;
				  counter <= 0;
				  end*/
	          end
	5'b10100:begin
		        counter <= counter + 1;
	           CHAddr[111:96] <= datain;
				  /*if(datain != intCHAddr[111:96])
				  begin
				  flag <= 0;
				  counter <= 0;
				  end*/
	          end
	5'b10101:begin
		        counter <= counter + 1;
	           CHAddr[127:112] <= datain;
				  /*if(datain != intCHAddr[127:112])
				  begin
				  flag <= 0;
				  counter <= 0;
				  end*/
	          end
	/*16'b10110:begin
	          sname[15:0] <= datain;
				 end
	16'b10111:begin
	          sname[31:16] <= datain;
				 end
	16'b11000:begin
				 sname[47:32] <= datain;
				 end
	16'b11001:begin
				 sname[63:48] <= datain;
				 end
	16'b11010:begin
				 file[15:0] <= datain;
				 end
	16'b11100:begin
	          file[31:16] <= datain;
				 end
	16'b11101:begin
	          file[47:32] <= datain;
				 end
	16'b11110:begin
	          file[63:48] <= datain;
				 end
	16'b11111:begin
	          file[79:64] <= datain;
				 end
	16'b100000:begin
	           file[95:80] <= datain;
				  end
	16'b100001:begin
				  file[111:96] <= datain;
				  end
	16'b100010:begin
				  file[127:112] <= datain;
				  end*/
   endcase
	end //counter <16'b10110
	
  else if(counter > 5'b10101)//corresponds to eof != 1;
  begin
   if(mode == 2'b0)            //MODE 0
	begin
	 optionno <= datain[7:0];
	 if(datain[7:0] == 8'b00000000)
	 begin
	  if(datain[15:8] == 8'b00000000)
	  begin
	  end
	  else if(datain [15:8] == 8'b11111111)
	  begin
	  flag <= 0;//the end has come
	   if(checksummatch == 1)
		begin
	    if(dhcpmssgtype == 8'b10)
		 begin
		  dhcpoffer <= 1;
		 end
		 if(dhcpmssgtype == 8'b101)
		 begin
		  dhcpacknowledge <= 1;
		 end
		 mode <= 2'b11;
		end
		else
		begin
		 mode <= 2'b0;
		end
	  counter <=0;
	  end
	  else
	  begin
	   optionno <= datain[15:8];
		mode <= 2'b01;
	  end
	 end
	 else if(datain[7:0] == 8'b11111111)
	 begin
	 flag <= 0; //the end has come--
	 if(checksummatch == 1)
	 begin
		 if(dhcpmssgtype == 8'b10)
		 begin
		  dhcpoffer <= 1;
		 end
		 if(dhcpmssgtype == 8'b101)
		 begin
		  dhcpacknowledge <= 1;
		 end
	 mode <= 2'b11;
	 end
	 else
	 begin
	  mode <= 2'b0;
	 end
	 counter <= 0;
	 end
	 else
	 begin
	 optionlength <= datain[15:8];
	 mode <= 2'b10;
	 end
   end
   if(mode == 2'b10)          //MODE 2
   begin
    if(optionlength > 8'b10) // len>2 
    begin
     optionlength <= optionlength + 8'b11111110;
	  
     case(optionno)
		8'b110011://ipleasetime option
		begin
		ipleasetime[count*8 + 15-:16] <= datain;
		count <= count + 2'b10;
		if(count >= 8'b10)
		begin
		count <= 8'b0;
		end
		end
		8'b110110://server identifier option
		begin
		serverid[8*count+15-:16] <= datain;
		/*if(datain[7:0] != SIAddr )
		begin
		flag <= 0;
		counter <= 0;
		end*/ 
		count <= count + 2'b10;
		if(count >= 8'b10)
		begin
		count <= 8'b0;
		end
		end
		endcase
    end//optionlength > 2
	 
	 
	 
	 
	 
	 if(optionlength == 8'b10) //len = 2
	 begin
	  optionlength <= optionlength + 8'b11111110;

		case(optionno)
		8'b110011://ipleasetime option
		begin
		ipleasetime[count*8 + 15-:16] <= datain;
		count <= count + 8'b10;
		if(count >= 8'b10)
		begin
		count <= 8'b0;
		end
		end
		8'b110110://server identifier option
		begin
		serverid[8*count+15-:16] <= datain;
		/*if(datain[7:0] != SIAddr )
		begin
		flag <= 0;
		counter <= 0;
		end*/ 
		count <= count + 8'b10;
		if(count >= 8'b10)
		begin
		count <= 8'b0;
		end
		end
		endcase
	  mode <= 2'b0;
	 end//end optionlength == 2
	 
	 
	 
	 
	 if(optionlength == 8'b1) //len = 1
	 begin
	 
		case(optionno)
		8'b110011://ipleasetime option
		begin
		ipleasetime[31:24] <= datain[7:0];
		end
		/*8'b110100://option-overload option
		begin
		optionoverload <= datain[7:0];
		if(datain[7:0] == 8'b1)
		begin
		//only file contains options
		end
		if(datain[7:0] == 8'b10)
		begin
		//only sname  contains options
		end
		if(datain[7:0] == 8'b11)
		begin
		//both sname and file contains options
		end
		end*/
		8'b110101://dhcp messagetype option
		begin
		dhcpmssgtype <= datain[7:0];
		end
		8'b110110://server identifier option
		begin
		serverid[31:24] <= datain[7:0];
		/*if(datain[7:0] != SIAddr )
		begin
		flag <= 0;
		counter <= 0;
		end*/ 
		end
		endcase


	  optionno <= datain[15:8];
	  if(datain[15:8] == 8'b00000000)
	  begin
	  mode <= 2'b00;
	  end
	  else if(datain[15:8] == 8'b11111111)
	  begin
	   flag <= 0; //the end has come
		if(checksummatch == 1)
		begin
	    if(dhcpmssgtype == 8'b10)
		 begin
		  dhcpoffer <= 1;
		 end
		 if(dhcpmssgtype == 8'b101)
		 begin
		  dhcpacknowledge <= 1;
		 end
	   mode <= 2'b11;
		end
		else
		begin
		 mode <= 2'b0;
		end
		counter <= 0;
	  end
	  else
	  begin
		mode <= 2'b01;
	  end
	 end//end optionlength == 1
   end//end mode == 2'b10
	if(mode == 2'b01)               //MODE 1
	begin
	 optionlength <= datain[7:0] + 8'b11111111;
	 if(datain[7:0] == 8'b1)
	 begin
	 
		case(optionno)
		/*8'b110100://option-overload option
		begin
		optionoverload <= datain[7:0];
		if(datain[7:0] == 8'b1)
		begin
		//only file contains options
		end
		if(datain[7:0] == 8'b10)
		begin
		//only sname  contains options
		end
		if(datain[7:0] == 8'b11)
		begin
		//both sname and file contains options
		end
		end*/
		8'b110101://dhcp messagetype option
		begin
		dhcpmssgtype <= datain[7:0];
		end
		endcase

	  mode <= 2'b0;
	 end//end optionlength = 1
	 if(datain[7:0] != 8'b1)
	 begin
	 case(optionno)
		/*8'b1://subnet option
		begin
		subnetmask[7:0] <= datain[15:8];
		count <= count + 1;
		end
		8'b11://router list option
		begin
		router[7:0] <= datain[15:8];
		count <= count + 1;
		//more needs to be added
		end*/
		8'b110011://ipleasetime option
		begin
		ipleasetime[7:0] <= datain[15:8];
		count <= count + 1;
		end
		/*8'b110100://option-overload option
		begin
		optionoverload <= datain[7:0];
		if(datain[15:8] == 8'b1)
		begin
		//only file contains options
		end
		if(datain[15:8] == 8'b10)
		begin
		//only sname  contains options
		end
		if(datain[15:8] == 8'b11)
		begin
		//both sname and file contains options
		end
		end*/
		8'b110101://dhcp messagetype option
		begin
		dhcpmssgtype <= datain[15:8];
		end
		8'b110110://server identifier option
		begin
		serverid[7:0] <= datain[15:8];
		count <= count + 1;
		/*if(datain[7:0] != SIAddr )
		begin
		flag <= 0;
		counter <= 0;
		end*/ 
		end
		endcase
	mode <= 2'b10;
	 end//optionlength !=1
	end//mode 1
	
	
	
  end//end eof != 1
  end //validin 
  end//flag == 1
  
  	if(mode == 2'b11)              //MODE 3
	begin
	  dhcpoffer <= 0;
	  dhcpacknowledge <= 0;
	  mode <= 2'b00;
	  counter <= 5'b0;
	  count <= 8'b0;
	end//mode 3 ended
	
 end//clock
end//always

endmodule
