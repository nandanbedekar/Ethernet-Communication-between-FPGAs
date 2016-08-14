`timescale 1ns / 1ps


module FGPA1_tb;

	// Inputs
	reg reset;
	reg clock;
	reg [255:0] adcdataout;
	reg [3:0] adcexpout;
	reg adcvalidout;
	reg validin;
	reg sof;
	reg eof;
	reg [31:0] datain;
	//reg [47:0] inthwaddr;
	reg [15:0] intudpport;


	// Outputs
	wire fpga1validout;
	wire fpga1sof;
	wire fpga1eof;
	wire [31:0] fpga1dataout;



   reg [6:0] counter;
	integer i,filewrite,scan_file,fileread,newline;
	integer d=100,s=115,e=101,v=118,r;
	reg [31:0] rnd;
	reg [31:0] exp;
	
	// Instantiate the Unit Under Test (UUT)
	FPGA1 uut (
		.reset(reset), 
		.clock(clock), 
		.adcdataout(adcdataout), 
		.adcexpout(adcexpout), 
		.adcvalidout(adcvalidout), 
		.fpga1validout(fpga1validout), 
		.fpga1sof(fpga1sof), 
		.fpga1eof(fpga1eof), 
		.fpga1dataout(fpga1dataout), 
		.validin(validin), 
		.sof(sof), 
		.eof(eof), 
		.datain(datain), 
		//.inthwaddr(inthwaddr), 
		.intudpport(intudpport) 
	);

	initial begin
		// Initialize Inputs
		reset <= 0;
		clock <= 0;
		adcdataout <= 256'b0;
		adcexpout <= 4'b0;
		adcvalidout <= 0;
		validin <= 0;
		sof <= 0;
		eof <= 0;
		datain <= 32'b0;
	//	inthwaddr <= 48'b0;
		intudpport <= 16'b0;
		counter <= 7'b0;
		reset <= 1;
		#5
		reset <= 0;

		filewrite = $fopen("C:/Users/Arpan Vyas/Desktop/FPGA/FPGA1/output_cases.txt","w");
		fileread = $fopen("C:/Users/Arpan Vyas/Desktop/FPGA/FPGA1/input_cases.txt","r");
	end
	
always #5 clock = !clock;
always@(posedge clock)
begin
 if(counter == 7'b111111)
 begin
  for(i = 1; i < 9; i = i + 1)
  begin 
   adcdataout[32*i - 1-:32] <= $random();
	exp <= 8'b100;
  end
  adcexpout <= 4'b0;
  adcvalidout <= 1;
  counter <= 7'b0;
 end
 else
 begin
  counter <= counter + 1;
 end
 if(counter == 7'b0)
 begin
  adcvalidout <= 0;
 end
end//end always

always@(posedge clock or posedge reset)
begin
 if(reset == 1)
 begin
 end
 
 else if(clock == 1)
 begin
 
  if(fpga1validout == 1)
  begin
   if(fpga1sof == 1)
	begin
    $fwrite(filewrite,"%c",s);
	 $fwrite(filewrite,"%b\n",fpga1dataout);
	end
	else if(fpga1eof == 1)
	begin
	 $fwrite(filewrite,"%c",e);
	 $fwrite(filewrite,"%b\n",fpga1dataout);
	end
	else if((fpga1sof != 1)&&(fpga1eof != 1))
	begin
	 $fwrite(filewrite,"%c",d);
	 $fwrite(filewrite,"%b\n",fpga1dataout);
	end
  end//end fpgavalidout  == 1
  else if(fpga1validout != 1)
  begin
   $fwrite(filewrite,"%c\n",v);
  end
 
  r = $fgetc(fileread);
  if(r == v)
  begin
   validin <= 0;
	newline = $fgetc(fileread);
  end
  else if(r == s)
  begin
   sof <= 1;
	validin <= 1;
	scan_file = $fscanf(fileread,"%b\n",rnd[31:0]);
   datain <= rnd;
  end
  else if(r == d)
  begin
   validin <= 1;
   scan_file = $fscanf(fileread,"%b\n",rnd[31:0]);
   datain <= rnd;
  end
  else if(r == e)
  begin
   validin <= 1;
	eof <= 1;
   scan_file = $fscanf(fileread,"%b\n",rnd[31:0]);
   datain <= rnd;
  end
  
  if(eof == 1)
  begin
   eof <= 0;
  end
  if(sof == 1)
  begin
   sof <= 0;
  end
 end//clock
end//end always
      
endmodule

