`timescale 1ns / 1ps
module vga_ctrl(
	px_clk,
	rst,
	hs,
	vs,
	blank
	   );

`include "vga_const.inc"
	   
input px_clk, rst;
output hs, vs, blank;

// ========================================
// State register
// ========================================
reg [2:0] h_state, h_state_nxt, v_state, v_state_nxt;
// ========================================
// Internal signals
// ========================================
reg hs_ff, hs_nxt;
reg vs_ff, vs_nxt;
reg hblank_ff, hblank_nxt;
reg vblank_ff, vblank_nxt;
reg row_en_ff, row_en_nxt;
reg col_en_ff, col_en_nxt;

reg [Row_size-1:0] ln_ff, ln_nxt;
reg [Col_size-1:0] px_ff, px_nxt;

reg [Row_size-1:0] row_ff, row_nxt;
reg [Col_size-1:0] col_ff, col_nxt;
// ========================================
// Combinational block
// ========================================
assign blank = hblank_ff || vblank_ff;
assign hs = hs_ff;
assign vs = vs_ff;

//Horizontal controller state machine
always @*
	
begin

	h_state_nxt = h_state;
	hblank_nxt = hblank_ff;
	hs_nxt = hs_ff;
	px_nxt = px_ff;
	ln_nxt = ln_ff;
	col_nxt = col_ff;
	col_en_nxt = col_en_ff;
	row_en_nxt = row_en_ff;
	
	case(h_state)
	
		///RESET============================================0
		s_HRST	: begin			
		h_state_nxt = s_HS;
		hblank_nxt = 1'b1;
		hs_nxt = 1'b1;
		end
		
		///HS========================================================1
		s_HS	: begin
		px_nxt = px_ff + 1;
		//hs_nxt = 1'b1;
		if (px_ff==(t1H-1))
			begin
			h_state_nxt = s_HBP;
			hs_nxt = 1'b0;
			end
		end
		
		///HBP=======================================================2
		s_HBP	: begin
		px_nxt = px_ff + 1;
		   if (px_ff==(t2H-2))
		      col_en_nxt = 1'b1;
			if (px_ff==(t2H-1))
				begin
				h_state_nxt = s_HACT;
				hblank_nxt = 1'b0;
				col_nxt = col_ff + 1;
				end
						end
		
		///HACT==================================================3
		s_HACT	: begin
		px_nxt = px_ff + 1;
		
		if (col_ff==(t3H-t2H-1))
			col_nxt = 0;
			else
			begin
			if (col_ff>0)
			col_nxt = col_ff + 1;
			end
		
		if (px_ff==(t3H-2))		
			col_en_nxt = 1'b0;
		if (px_ff==(t3H-1))
			begin
			h_state_nxt = s_HFP;
			hblank_nxt = 1'b1;
		
			end
						end
		
		///HFP=======================================================4
		s_HFP	: begin
		px_nxt = px_ff + 1;
		
		
		if (px_ff==(t4H-2))
			begin
			if (ln_ff < (t4V-1))
					ln_nxt = ln_ff + 1;
				else 
					ln_nxt = 0;
			end
		if (px_ff==(t4H-1))
			begin
			h_state_nxt = s_HS;
			hs_nxt = 1'b1;
			px_nxt = 0;
			end
					end
		///===========================================================
	endcase
end
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//Vertical controller state machine
always @*
	
begin

	v_state_nxt = v_state;
	vblank_nxt = vblank_ff;
	vs_nxt = vs_ff;
	row_nxt = row_ff;
	case(v_state)
	
		///RESET============================================0
		s_VRST	: begin			
		v_state_nxt = s_VS;
		vs_nxt = 1'b1;
		end
		
		///VS========================================================1
		s_VS	: begin
		vblank_nxt = 1'b1;
		vs_nxt = 1'b1;
		if (ln_ff==t1V)
			begin
			v_state_nxt = s_VBP;
			vs_nxt = 1'b0;
			end
		end
		
		///VBP=======================================================2
		s_VBP	: begin
			if (ln_ff==t2V)
				begin
				v_state_nxt = s_VACT;
				vblank_nxt = 1'b0;
				row_en_nxt = 1'b1;
				end
		end
		
		///VACT==================================================3
		s_VACT	: begin
		
		if (ln_ff==t3V)
			begin
			v_state_nxt = s_VFP;
			vblank_nxt = 1'b1;
			row_en_nxt = 1'b0;
			end
		end
		
		///VFP=======================================================4
		s_VFP	: begin
		if (ln_ff==0)
			begin
			v_state_nxt = s_VS;
			vs_nxt = 1'b1;
			end
		end
		///===========================================================
	endcase
end
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// ========================================
// Register Update
// ========================================

always @(posedge px_clk or posedge rst)
begin
	if (rst)
	begin
	h_state <= s_HRST;
	v_state <= s_VRST;
	px_ff <= 0;
	ln_ff <= 0;
	row_ff <= 0;
	col_ff <= 0;
	hs_ff <= 1'b0;
	vs_ff <= 1'b0;
	hblank_ff <= 1'b1;
	vblank_ff <= 1'b1;
	col_en_ff <= 1'b0;
	row_en_ff <= 1'b0;
	end
	
	else
	
	begin
	h_state <= h_state_nxt;
	v_state <= v_state_nxt;
	
	hs_ff <= hs_nxt;
	vs_ff <= vs_nxt;
	
	hblank_ff <= hblank_nxt;
	vblank_ff <= vblank_nxt;
	
	px_ff <= px_nxt;
	ln_ff <= ln_nxt;
	
	row_ff <= row_nxt;
	col_ff <= col_nxt;
	
	col_en_ff <= col_en_nxt;
	row_en_ff <= row_en_nxt;
	end
end

endmodule
