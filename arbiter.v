`timescale 1ns / 1ps

module arbiter(
    input clk80,
	input rst,
    output Go,
    input Done,
    output Wr,
    output [22:0] brst_Addr,
    output vga_rst,
    input cam_req,
    input vga_req
    );

`include "arbiter_const.inc"

reg [3:0] arb_state_ff, arb_state_nxt;

reg cam_req_ff, vga_req_ff;
reg init_done_ff, init_done_nxt;
reg Go_ff, Go_nxt, Wr_ff, Wr_nxt, vga_rst_ff, vga_rst_nxt;

reg [22:0] brst_Addr_ff, brst_Addr_nxt;
reg [22:0] wr_ptr_ff, wr_ptr_nxt;
reg [22:0] rd_ptr_ff, rd_ptr_nxt;

reg [19:0] init_count_ff, init_count_nxt;
reg [9:0] count_ff, count_nxt;
reg [9:0] prio_count_ff, prio_count_nxt;

reg wr_loc_nxt, wr_loc_ff;
reg rd_loc_nxt, rd_loc_ff;
reg [1:0] rd_no_nxt, rd_no_ff;

	//Arbiter state machine combinational logic
always @( * )
begin
		arb_state_nxt = arb_state_ff;
		count_nxt = count_ff;
		init_count_nxt = init_count_ff;
		Go_nxt = Go_ff;
		Wr_nxt = Wr_ff;
		vga_rst_nxt = vga_rst_ff;
		brst_Addr_nxt = brst_Addr_ff;
		wr_ptr_nxt = wr_ptr_ff;
		rd_ptr_nxt = rd_ptr_ff;
		init_done_nxt = init_done_ff;
		prio_count_nxt = prio_count_ff;
		wr_loc_nxt = wr_loc_ff;
		rd_loc_nxt = rd_loc_ff;
		rd_no_nxt = rd_no_ff;
		
		case(arb_state_ff)
		
				s_arb_idle	: begin	
					if (init_count_ff < brst_no-1)// + brst_no/4) 
						begin	//fill frame buffer1
							if (cam_req_ff)
								begin							
								arb_state_nxt = s_arb_cam_req_go;	//*******Go to cam req
								count_nxt = 1;
								if (~init_done_ff)
									init_count_nxt = init_count_ff + 20'd1;
								end
						end
					else	
						begin	//normal behaviour
						if (cam_req_ff & ~vga_req_ff)	//cam_req
							begin
							if (~init_done_ff)	
							init_count_nxt = init_count_ff + 20'd1;
							arb_state_nxt = s_arb_cam_req_go;	//----->Go to cam req
							count_nxt = 1;
							//prio_count_nxt = 0;
							end
						
						if (~cam_req_ff & vga_req_ff)	//vga_req
							begin
							if (~init_done_ff)
							init_count_nxt = init_count_ff + 20'd1;
							arb_state_nxt = s_arb_vga_req_go;	//----->Go to vga req
							count_nxt = 1;
							//prio_count_nxt = 0;
							end
				
						if ((cam_req_ff) & (vga_req_ff))	//vga_req and cam_req
							begin					
								if (prio_count_ff < 3) //<<--- cu 3,6 ,12 merge cel mai bine
									begin
									arb_state_nxt = s_arb_vga_req_go;	//----->Go to vga req
									//arb_state_nxt = s_arb_cam_req_go;	//----->Go to cam req
									count_nxt = 1;
									prio_count_nxt = prio_count_ff + 10'd1;
									if (~init_done_ff)
									init_count_nxt = init_count_ff + 20'd1;
									end
								else
									begin
									arb_state_nxt = s_arb_cam_req_go;	//----->Go to cam req
									//arb_state_nxt = s_arb_vga_req_go;	//----->Go to vga req
									if (~init_done_ff)
									init_count_nxt = init_count_ff + 20'd1;
									count_nxt = 1;
									prio_count_nxt = 0;
									end								
							end
						if (init_count_ff >= brst_no-1)	//start vga controller
							begin
							vga_rst_nxt = 0;
							init_done_nxt = 1;
							end
						end
				end
				//==================================================================================================================================================================
				s_arb_cam_req_go	: begin	
					if (Done)
						begin
						count_nxt = count_ff + 10'd1;						
						Wr_nxt = 1'b1;
						Go_nxt = 1'b1;		
						end
					if (count_ff == 3)
						begin
						arb_state_nxt = s_arb_cam_req;
						//brst_Addr_nxt = wr_ptr_ff;	//mem_addr = wr_ptr
						
						if (~wr_loc_ff) //buffer0
						begin
							if (wr_ptr_ff == max_addr0)	
								begin
								wr_loc_nxt = 1'b1; //reset to buffer 1
								wr_ptr_nxt = wr_ptr_ff + 23'd32; 
								end
							else						//increment wr ptr
								wr_ptr_nxt = wr_ptr_ff + 23'd32;
							end
						
						
						if (wr_loc_ff) //buffer1
						begin
							if (wr_ptr_ff == max_addr1)	
								begin
								wr_loc_nxt = 1'b0; 			 //reset to buffer 0
								wr_ptr_nxt = 23'd0; 	
								end
							else						//increment wr ptr
								wr_ptr_nxt = wr_ptr_ff + 23'd32;
							end
						end
					if (count_ff == 2)
						begin
						//arb_state_nxt = s_arb_cam_req;
						brst_Addr_nxt = wr_ptr_ff;	//mem_addr = wr_ptr
						end
				end
				//========================
				s_arb_cam_req	: begin	
					Go_nxt = 0;
					
					if (Done)
					begin				
					arb_state_nxt = s_arb_idle;
					end
				end
				//========================
				s_arb_vga_req_go	: begin	
					if (Done)
						begin
						count_nxt = count_ff + 10'd1;												
						Wr_nxt = 0;
						Go_nxt = 1;						
						end
					if (count_ff == 3)
					begin
						arb_state_nxt = s_arb_cam_req;
						//brst_Addr_nxt = rd_ptr_ff;
						
						if (~rd_loc_ff)	//buffer0
						begin
							if (rd_no_ff == 3)	//frame4
								begin
									if (rd_ptr_ff == max_addr0)
										begin
										rd_ptr_nxt = rd_ptr_ff + 23'd32;	//point to addr1 from buffer1
										rd_loc_nxt = 1'b1;					//point to buffer1
										rd_no_nxt = rd_no_ff + 2'd1;		//counter resets from 11 to 00
										end
									else
										rd_ptr_nxt = rd_ptr_ff + 23'd32;	//increment address
									
								end
							else
								begin
									if (rd_ptr_ff == max_addr0)
										begin
										rd_ptr_nxt = 23'd0;		//point to addr0
										rd_no_nxt = rd_no_ff + 2'd1;	//increment counter
										end
									else
										rd_ptr_nxt = rd_ptr_ff + 23'd32;	//increment address
								end
						end
					
					
						if (rd_loc_ff)	//buffer1
						begin
							if (rd_no_ff == 3)	//frame4
								begin
									if (rd_ptr_ff == max_addr1)
										begin
										rd_ptr_nxt = 23'd0;					//point to addr0 from buffer0
										rd_loc_nxt = 1'b0;					//point to buffer0
										rd_no_nxt = rd_no_ff + 2'd1;		//counter resets from 11 to 00
										end
									else
										rd_ptr_nxt = rd_ptr_ff + 23'd32;	//increment address
									
								end
							else
								begin
									if (rd_ptr_ff == max_addr1)
										begin
										rd_ptr_nxt = max_addr0 + 23'd32;	//point to addr0
										rd_no_nxt = rd_no_ff + 2'd1;		//increment counter
										end
									else
										rd_ptr_nxt = rd_ptr_ff + 23'd32;	//increment address
								end
						end
					end
					if (count_ff == 2)
					begin
					brst_Addr_nxt = rd_ptr_ff;
					end
				end
				//========================	
				s_arb_vga_req	: begin	
					Go_nxt = 0;
					
					if (Done)
					begin				
					arb_state_nxt = s_arb_idle;
					end
				end
				//========================	
			
		endcase

end
	
	//Arbiter state machine registers
always @(posedge clk80 or posedge rst)
begin
	if (rst)
		begin
		arb_state_ff <= s_arb_idle;
		count_ff <= 10'd1;
		init_count_ff <= 20'd0;
		Go_ff <= 1'b0;
		Wr_ff <= 1'b0;
		vga_rst_ff <= 1'b1;
		brst_Addr_ff <= 23'd0;
		wr_ptr_ff <= 23'd0;
		rd_ptr_ff <= 23'd0;
		init_done_ff <= 1'b0;
		prio_count_ff <= 10'd0;
		wr_loc_ff <= 1'b0;
		rd_loc_ff <= 1'b0;
		rd_no_ff <= 2'd0;
		cam_req_ff <= 1'b0;
		vga_req_ff <= 1'b0;
		end
	else 
		begin
		arb_state_ff <= arb_state_nxt;
		count_ff <= count_nxt;
		init_count_ff <= init_count_nxt;
		Go_ff <= Go_nxt;
		Wr_ff <= Wr_nxt;
		vga_rst_ff <= vga_rst_nxt;
		brst_Addr_ff <= brst_Addr_nxt;
		wr_ptr_ff <= wr_ptr_nxt;
		rd_ptr_ff <= rd_ptr_nxt;
		init_done_ff <= init_done_nxt;
		prio_count_ff <= prio_count_nxt;
		wr_loc_ff <= wr_loc_nxt;
		rd_loc_ff <= rd_loc_nxt;
		rd_no_ff  <= rd_no_nxt ;
		cam_req_ff <= cam_req;
		vga_req_ff <= vga_req;
		end
end

assign Go = Go_ff;
assign Wr = Wr_ff;
assign brst_Addr = brst_Addr_ff;
assign vga_rst = vga_rst_ff;


endmodule
