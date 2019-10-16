`timescale 1ns / 1ps

module href_counter(
    input px_clk,
    input href,
    input vsync,
	 input rst,
    output wr_en
    );
reg fr_en_ff, fr_en_nxt;
reg href_en_ff, href_en_nxt;
reg px_en_ff, px_en_nxt;
reg vsync_ff, href_ff;
reg stop_ff, stop_nxt;

reg [9:0] frame_count;
reg [9:0] href_count;
reg [9:0] px_count;

	//Combinational logic
	always @(*)
	begin

		if ((href_count <= 10'd480)&(~vsync_ff))
			href_en_nxt = 1'b1;
			else href_en_nxt = 1'b0;


		if ((px_count < (10'd640 - 10'd1))&(href))
			px_en_nxt = 1'b1;
			else px_en_nxt = 1'b0;
		
		stop_nxt = 1'b0;
		
		if (frame_count == 10'd2 )
				begin
				fr_en_nxt = 1'b1;
				end
			else 
				begin
				fr_en_nxt = 1'b0;
				if (frame_count == 10'd3 )
				stop_nxt = 1'b1;
				end
		
	end

   //Frames counter
   always @(posedge vsync or posedge rst)
      if (rst)
         frame_count <= 0;
      else if (~stop_ff)
         frame_count <= frame_count + 10'd1;
   //Lines counter
   always @(posedge href or posedge vsync_ff)
      if (vsync_ff)
         href_count <= 0;
      else if (href_en_ff)
         href_count <= href_count + 10'd1;
	//Pixel counter	
	always @(posedge px_clk or negedge href_ff)
      if (~href_ff)
         px_count <= 0;
      else //if (px_en_ff)
         px_count <= px_count + 10'd1;

always @(posedge px_clk)
	begin
	if (rst)
		begin
		href_en_ff <= 1'b0;
		px_en_ff <= 1'b0;
		vsync_ff <= 1'b0;
		href_ff <= 1'b0;
		fr_en_ff <= 1'b0;
		stop_ff <= 1'b0;
		end
	else
		begin
		href_en_ff <= href_en_nxt;
		px_en_ff <= px_en_nxt;
		vsync_ff <= vsync;
		href_ff <= href;
		fr_en_ff <= fr_en_nxt;
		stop_ff <= stop_nxt;
		end
	end
	
assign wr_en = href_en_ff & href_ff & px_en_ff & fr_en_ff;

endmodule