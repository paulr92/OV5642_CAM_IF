`timescale 1ns / 1ps
//Output format Y dummy Y dummy .....
module sim_camera(
input xclk,
input n_rst,
output pclk,
output reg vsync,
output reg href,
output reg [7:0] data
);

parameter WIDTH   = 640; 				// Image width
parameter HEIGHT  = 480; 				// Image height
parameter INFILE  = "input.hex"; 		// image file
parameter sizeOfWidth = 8;				// data width
parameter sizeOfLengthReal = 921600;	// image data : 307200 bytes: 640 * 480 * 3
parameter NumOfChannels = 3;			// input image is coded in 3 channels RGB888

// counting variables
integer i, j, row, col;
reg [7 : 0]   raw_img [0 : sizeOfLengthReal-1];					// memory to store  8-bit data raw image
reg [7 : 0]   y_img   [0 : (sizeOfLengthReal/NumOfChannels)-1];	// memory to store  8-bit data luminance image
reg Y;
assign pclk = xclk;

initial begin
    $readmemh(INFILE,raw_img,0,sizeOfLengthReal-1); // read file from INFILE
	 for(i=0; i<HEIGHT; i=i+1) begin
		for(j=0; j<WIDTH; j=j+1) begin
			y_img[WIDTH*i+j] = raw_img[WIDTH*3*(HEIGHT-i-1)+3*j+0]; // save Y component
		end
	end
		
end

// counting column and row index  for reading memory 
always@(posedge pclk, negedge n_rst)
begin
    if(~n_rst) begin
        row <= 0;
		col <= 0;
    end
	else begin
		if(Y) begin
			if(col == WIDTH - 1 && row == HEIGHT - 1) begin
				col <= 0;
				row <= 0;
			end
			else if(col == WIDTH - 1) begin
				col <= 0;
				row <= row + 1;
			end
			else 
				col <= col + 1; // reading 1 pixels in parallel		end
		end
	end
end


initial @(posedge n_rst)
	begin
		href=1'b0;
		vsync=1'b0;
		data=0;
		repeat(5)
		gen_frame();		
	end

task gen_pixel();
// DATA_G0 = org_G[WIDTH * row + col   ] + VALUE;
   @(negedge pclk) begin
		data = Y ? 'hff : y_img[WIDTH * row + col];
		Y = ~Y;
   end
endtask

task gen_href_period();
begin
   href = 1'b0;
   # 104_000;	//104us
   href = 1'b1;
   //# 26_660;	//26us
   repeat (640*2) @(negedge pclk);
   href = 1'b0;
end
endtask

task gen_vs_period();
begin
   vsync = 1'b0;
   # 66_000_000;	//66ms
   vsync = 1'b1;
   # 164_403;	//164us
   end
endtask

task gen_line;
begin
	fork
		begin
			gen_href_period();
		end
		begin
			Y = 0;
			#104_000; //104us
			repeat(640*2)
				gen_pixel();
		end
	join
end
endtask

task gen_frame;
begin
	fork
	gen_vs_period();
	begin
	repeat(480)
	gen_line();
	end
	join
end
endtask

endmodule