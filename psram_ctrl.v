`timescale 1ns / 1ps
 
module psram_ctrl(
	 //Memory signals
    output [22:0] Addr,	//Address bus
	 inout [15:0] DQ,		//Data bus
    output nCE,			//Chip enable
    output nOE,			//Output enable
    output nWE,			//Write enable
    output nADV,			//Address valid
    output CRE,			//Control register enable
    output nLB,			//Lower byte enable
    output nUB,			//Upper byte enable
	 //output clk_mem,	//Clock output to memory

	 output [2:0] LED,	//for debug
	 output cfgDone,		//Memory configuration flag
	 
	 input brst_Go,				//Burst start operation input
	 input [22:0] brst_Addr_in,//Burst address 
	 input brst_Wr,				//Burst write input ; 1=write , 0=read
	 output brst_Done,			//Burst done flag
	 output brst_ren,			//Burst read enable to fifo
	 input [15:0] brst_din,		//Burst write data in
	 output brst_wen,			//Burst write enable to fifo
	 output [15:0] brst_dout,	//Burst 
	 
	 input clk160_i,		//Clock for burst access state machine
	 input clk100_i,		//Clock for configuration state machine
	 //input clk80_i,			 //Burst clock
	 //input clk80_n_i,			//Burst clock inverted
	 input rst,				//Reset input
	 
	 output mem_clk_en
    );

`include "psram_param.inc"	

reg DQ_sel;

wire Done;
wire [15:0] DQ_in;
wire clk_80_gt, clk_n_80_gt;

//Configuration state machine registers
reg [3:0] cfg_state_nxt, cfg_state_ff;
reg cfgDone_ff, cfgDone_nxt;
reg [15:0] rd_data_nxt, rd_data_ff;
reg [15:0] DQ_ff, DQ_nxt;
reg [22:0] Addr_ff, Addr_nxt;
reg DQ_wr_ff, DQ_wr_nxt, DQ_rd_ff, DQ_rd_nxt;
reg nCE_ff, nADV_ff, nOE_ff, nWE_ff, nLB_ff, nUB_ff, CRE_ff, Done_ff;
reg nCE_nxt, nADV_nxt, nOE_nxt, nWE_nxt, nLB_nxt, nUB_nxt, CRE_nxt, Done_nxt;
reg [14:0] count_ff, count_nxt;

//Burst access state machine registers
reg [3:0] brst_state_nxt, brst_state_ff;
reg [15:0] brst_DQ_ff, brst_DQ_nxt;
reg [22:0] brst_Addr_ff, brst_Addr_nxt;
reg brst_nCE_ff, brst_nADV_ff, brst_nOE_ff, brst_nWE_ff, brst_nLB_ff, brst_nUB_ff, brst_CRE_ff;
reg brst_nCE_nxt, brst_nADV_nxt, brst_nOE_nxt, brst_nWE_nxt, brst_nLB_nxt, brst_nUB_nxt, brst_CRE_nxt;
reg [14:0] brst_count_ff, brst_count_nxt;
reg brst_mem_clk_en_ff, brst_mem_clk_en_nxt;
reg brst_ren_ff, brst_ren_nxt;
reg brst_wen_ff, brst_wen_nxt;
reg brst_done_ff, brst_done_nxt;


//Configuration state machine combinational logic
always @( * )
begin	
		cfg_state_nxt = cfg_state_ff;
		Addr_nxt = Addr_ff;
		DQ_nxt =DQ_ff;
		nCE_nxt = nCE_ff;
		nADV_nxt = nADV_ff;
		nOE_nxt = nOE_ff;
		nWE_nxt = nWE_ff;
		CRE_nxt = CRE_ff;
		count_nxt = count_ff;
		nUB_nxt = nUB_ff;
		nLB_nxt = nLB_ff;
		Done_nxt = Done_ff;
		rd_data_nxt = rd_data_ff;
		DQ_wr_nxt = DQ_wr_ff;
		DQ_rd_nxt = DQ_rd_ff;
		cfgDone_nxt = cfgDone_ff;
		
		case(cfg_state_ff)
			//Chip power up
			s_cfg_PowerUp	: begin
				count_nxt = count_ff+15'd1;
				if (count_ff == 15'd20000)
				begin
				cfg_state_nxt = s_cfg_RegWr_init;
				count_nxt = 15'd1;
				end
			end
			//Configuration Register Write
			s_cfg_RegWr_init	: begin
				CRE_nxt = 1'b1;
				
				count_nxt = count_ff + 15'd1;
				if (count_ff == 15'd2)
				cfg_state_nxt = s_cfg_RegWr_CE;
			end
			
			s_cfg_RegWr_CE	: begin
				Addr_nxt = Opcode;
				nCE_nxt = 1'b0;
				nADV_nxt = 1'b0;
				
				count_nxt = count_ff + 15'd1;
				if (count_ff == 15'd3)
				cfg_state_nxt = s_cfg_RegWr_ADV;
			end
			
			s_cfg_RegWr_ADV	: begin
				nADV_nxt = 1'b1;
			
				count_nxt = count_ff + 15'd1;
				if (count_ff == 15'd4)
				cfg_state_nxt = s_cfg_RegWr_nWE;
			end
			
			s_cfg_RegWr_nWE	: begin
				nWE_nxt = 1'b0;
				Addr_nxt = 23'd0;
				
				count_nxt = count_ff + 15'd1;
				if (count_ff == 15'd9)
				cfg_state_nxt = s_cfg_RegWr_WE;
			end
			
			s_cfg_RegWr_WE	: begin
				nWE_nxt = 1'b1;
			
				count_nxt = count_ff + 15'd1;
				if (count_ff == 15'd10)
				cfg_state_nxt = s_cfg_RegWr_End;
			end
			
			s_cfg_RegWr_End	: begin
				CRE_nxt = 1'b0;
				nCE_nxt = 1'b1;
				
				
				count_nxt = count_ff + 15'd1;
				if (count_ff == 15'd12)
				begin
				cfg_state_nxt = s_cfg_Adr5Rd_CE;
				count_nxt = 1;
				end
			end
			//READ ARRAY Addr 5
			s_cfg_Adr5Rd_CE	: begin
				nCE_nxt = 1'b0;
				nUB_nxt = 1'b0; 
				nLB_nxt = 1'b0;
				nADV_nxt = 1'b0;
				Addr_nxt = 23'd5;
				
				count_nxt = count_ff + 15'd1;
				if (count_ff == 15'd6)
				cfg_state_nxt = s_cfg_Adr5Rd_OE;
			end
			
			s_cfg_Adr5Rd_OE	: begin
				nOE_nxt = 1'b0;
				
				count_nxt = count_ff + 15'd1;
				if (count_ff == 15'd7)
				cfg_state_nxt = s_cfg_Adr5Rd_RdDQ;
			end
			
			s_cfg_Adr5Rd_RdDQ	: begin
				count_nxt = count_ff + 15'd1;
				if (count_ff == 15'd10)
				begin
				cfg_state_nxt = s_cfg_Adr5Rd_End;
				rd_data_nxt = DQ_in;
				end
				//Latch DQ lines
				if (count_ff == 15'd9)
				begin
				nADV_nxt = 1'b1;
				DQ_rd_nxt = 1'b1;			
				end
			end
			
			s_cfg_Adr5Rd_End	: begin
				nCE_nxt = 1'b1;
				nUB_nxt = 1'b1; 
				nLB_nxt = 1'b1;
				nOE_nxt = 1'b1;
				//nADV_nxt = 1'b1;
				Addr_nxt = 23'd0;
				DQ_rd_nxt = 1'b0;
				
				count_nxt = count_ff + 15'd1;
				if ((count_ff == 15'd12)&(~Done_ff))
				begin
				cfg_state_nxt = s_cfg_Adr5Wr_CE;
				count_nxt = 1;
				end
				
				if (Done_ff)
				cfgDone_nxt = 1'b1;
				end
			//Write test value at addr 5	
			s_cfg_Adr5Wr_CE	: begin
				nCE_nxt = 1'b0;
				nUB_nxt = 1'b0; 
				nLB_nxt = 1'b0;
				nOE_nxt = 1'b0;
				nADV_nxt = 1'b0;
				Addr_nxt = 23'd5;
				
				count_nxt = count_ff + 15'd1;
				if (count_ff == 15'd1)
				cfg_state_nxt = s_cfg_Adr5Wr_WE;
			end
			
			s_cfg_Adr5Wr_WE	: begin
				nWE_nxt = 1'b0;
				
				count_nxt = count_ff + 15'd1;
				if (count_ff == 15'd11)
				cfg_state_nxt = s_cfg_Adr5Wr_End;
				if (count_ff == 15'd9)
				nADV_nxt = 1'b1;
				if (count_ff == 15'd6)
				begin
				DQ_nxt = 3'd5;
				DQ_wr_nxt = 1'b1;
				end
			end
			
			s_cfg_Adr5Wr_End	: begin
				nCE_nxt = 1'b1;
				nUB_nxt = 1'b1; 
				nLB_nxt = 1'b1;
				nOE_nxt = 1'b1;
				//nADV_nxt = 1'b1;
				nWE_nxt = 1'b1;
				Addr_nxt = 23'd0;
				DQ_wr_nxt = 1'b0;
				
				count_nxt = count_ff + 15'd1;
				if (count_ff == 15'd13)
				begin
				cfg_state_nxt = s_cfg_Adr5Rd_CE; //Set done flag and go to read array address 5
				count_nxt = 1;
				Done_nxt = 1'b1;
				DQ_nxt = 3'd0;
				end				
			end
			endcase

end

//Burst access state machine combinational logic
always @( * )
begin
		brst_state_nxt = brst_state_ff;
		brst_Addr_nxt = brst_Addr_ff;
		brst_DQ_nxt = brst_DQ_ff;
		brst_nCE_nxt = brst_nCE_ff;
		brst_nADV_nxt = brst_nADV_ff;
		brst_nOE_nxt = brst_nOE_ff;
		brst_nWE_nxt = brst_nWE_ff;
		brst_CRE_nxt = brst_CRE_ff;
		brst_count_nxt = brst_count_ff;
		brst_nLB_nxt = brst_nLB_ff;
		brst_nUB_nxt = brst_nUB_ff;
		brst_ren_nxt = brst_ren_ff;
		brst_done_nxt = brst_done_ff;
		brst_mem_clk_en_nxt = brst_mem_clk_en_ff;
		brst_wen_nxt = brst_wen_ff;
		
		case(brst_state_ff)

				s_brst_wait10	: begin	//If configuration is done wait 10 clocks then go to idle state
					if (cfgDone_ff)
					begin
					brst_count_nxt = brst_count_ff + 15'd1;
					end
					if (brst_count_ff == 15'd10)
					begin
					brst_state_nxt = s_brst_idle;
					brst_count_nxt = 1;
					end
				end
				
				s_brst_idle	: begin
					if (brst_Go)
					begin
					brst_done_nxt = 1'b0;
					if (brst_Wr)
						brst_state_nxt = s_brst_wr_start;
						else
						brst_state_nxt = s_brst_rd_start;
					end
				end
				
				s_brst_wr_start : begin
				
										brst_nCE_nxt = 1'b0;
										brst_nADV_nxt = 1'b0;
										brst_nLB_nxt = 1'b0;
										brst_nUB_nxt = 1'b0;
										brst_nWE_nxt = 1'b0;
										brst_nOE_nxt = 1'b1;	
										brst_Addr_nxt = brst_Addr_in;
										brst_mem_clk_en_nxt = 1'b1;	//Start burst clock				
				
					brst_count_nxt = brst_count_ff + 15'd1;
					if (brst_count_ff == 15'd2)
					brst_state_nxt = s_brst_wr_nCE;
						

				end
				
				s_brst_wr_nCE : begin	// state 3
					/* brst_nCE_nxt = 1'b0;
					brst_nADV_nxt = 1'b0;
					brst_nLB_nxt = 1'b0;
					brst_nUB_nxt = 1'b0;
					brst_nWE_nxt = 1'b0;
					brst_nOE_nxt = 1'b1;	
					brst_Addr_nxt = brst_Addr_in;
					brst_mem_clk_en_nxt = 1'b1;	//Start burst clock */
					
				
					brst_count_nxt = brst_count_ff + 15'd1;
					if (brst_count_ff == 15'd4)
					begin
					brst_state_nxt = s_brst_wr_nADV;
					brst_nADV_nxt = 1'b1;
					brst_nWE_nxt = 1'b1;
					end
				end
				
				s_brst_wr_nADV : begin
					//brst_nADV_nxt = 1'b1;
					//brst_nWE_nxt = 1'b1;
				
					brst_count_nxt = brst_count_ff + 15'd1;
					if (brst_count_ff == 15'd5)
					brst_state_nxt = s_brst_wr_Addr;
				end
				
				s_brst_wr_Addr : begin
					//brst_Addr_nxt = 24'd10;	//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				
					brst_count_nxt = brst_count_ff + 15'd1;
					if (brst_count_ff == 15'd7 + 15'd11)
					brst_state_nxt = s_brst_wr_Ren;
				end
					
				s_brst_wr_Ren : begin
					brst_ren_nxt = 1'b1;
					
					brst_count_nxt = brst_count_ff + 15'd1;
					if (brst_count_ff == 15'd7 + 2*Burst_length + 15'd12) begin
						brst_state_nxt = s_brst_wr_nRen;
						brst_ren_nxt = 1'b0;
					end
				end
				
				s_brst_wr_nRen : begin
					// brst_ren_nxt = 1'b0;
					
					brst_count_nxt = brst_count_ff + 15'd1;
					if (brst_count_ff == 15'd7 + 2*Burst_length + 15'd2 + 15'd11)//12 <------
					brst_mem_clk_en_nxt = 1'b0;	//Stop burst clock
					if (brst_count_ff == 15'd7 + 2*Burst_length + 15'd2 + 15'd13)
					brst_state_nxt = s_brst_wr_End;
				end
				
				s_brst_wr_End : begin
					brst_nLB_nxt = 1'b1;
					brst_nUB_nxt = 1'b1;
					brst_nCE_nxt = 1'b1;
					
					brst_count_nxt = brst_count_ff + 15'd1;
					if (brst_count_ff == 15'd7 + 2*Burst_length + 15'd3 + 15'd13)
					begin
					brst_state_nxt = s_brst_idle;
					brst_count_nxt = 15'd1;
					brst_done_nxt = 1'b1;
					end
				end
				
				s_brst_rd_start : begin
				
					brst_nCE_nxt = 1'b0;
					brst_nADV_nxt = 1'b0;
					brst_nLB_nxt = 1'b0;
					brst_nUB_nxt = 1'b0;
					brst_Addr_nxt = brst_Addr_in;
					brst_mem_clk_en_nxt = 1'b1;	//Start burst clock
				
					brst_count_nxt = brst_count_ff + 15'd1;
					if (brst_count_ff == 15'd2)
					brst_state_nxt = s_brst_rd_nCE;
				end
				
				s_brst_rd_nCE : begin
					/* brst_nCE_nxt = 1'b0;
					brst_nADV_nxt = 1'b0;
					brst_nLB_nxt = 1'b0;
					brst_nUB_nxt = 1'b0;
					brst_Addr_nxt = brst_Addr_in;
					brst_mem_clk_en_nxt = 1'b1;	//Start burst clock */
				
					brst_count_nxt = brst_count_ff + 15'd1;
					if (brst_count_ff == 15'd4)
					begin
					brst_state_nxt = s_brst_rd_nADV;
					brst_nADV_nxt = 1'b1;
					end
				end
				
				s_brst_rd_nADV : begin
					//brst_nADV_nxt = 1'b1;
				
					brst_count_nxt = brst_count_ff + 15'd1;
					if (brst_count_ff == 15'd5)
					brst_state_nxt = s_brst_rd_Addr;
				end
				
				s_brst_rd_Addr : begin
					//brst_Addr_nxt = 24'd10;	//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				
					brst_count_nxt = brst_count_ff + 15'd1;
					if (brst_count_ff == 15'd6)
					brst_nOE_nxt = 1'b0;
					if (brst_count_ff == 15'd7 + 15'd11)
					brst_state_nxt = s_brst_rd_Ren;
				end
				
				s_brst_rd_Ren : begin
					if (brst_count_ff == 15'd7 + 15'd13)
					brst_wen_nxt = 1'b1;
					
					brst_count_nxt = brst_count_ff + 15'd1;
					if (brst_count_ff == 15'd7 + 2*Burst_length + 15'd11)
					begin
					brst_mem_clk_en_nxt = 1'b0;	//Stop burst clock
					end
					if (brst_count_ff == 15'd7 + 2*Burst_length + 15'd12)
					begin
					brst_state_nxt = s_brst_rd_nRen;
					//brst_mem_clk_en_nxt = 1'b0;	//Stop burst clock
					end
				end
				
				s_brst_rd_nRen : begin
					brst_wen_nxt = 1'b0;
					
					brst_count_nxt = brst_count_ff + 15'd1;
					//if (brst_count_ff == 15'd84)//15'd7 + 2*Burst_length + 15'd2 + 15'd13)
					//brst_mem_clk_en_nxt = 1'b0;	//Stop burst clock
					if (brst_count_ff == 15'd7 + 2*Burst_length + 15'd2 + 15'd13)
					begin
					brst_state_nxt = s_brst_rd_End;
					
					end
				end
				
				s_brst_rd_End : begin
					brst_nLB_nxt = 1'b1;
					brst_nUB_nxt = 1'b1;
					brst_nCE_nxt = 1'b1;
					brst_nOE_nxt = 1'b1;
					
					
					brst_count_nxt = brst_count_ff + 15'd1;
					if (brst_count_ff == 15'd7 + 2*Burst_length + 15'd3 + 15'd13)
					begin
					brst_state_nxt = s_brst_idle;
					brst_count_nxt = 15'd1;
					brst_done_nxt = 1'b1;
					end
				end
		endcase

end

//Configuration state machine registers
always @(posedge clk100_i or posedge rst)
begin
	if (rst)
		begin
		cfg_state_ff <= 4'd0;
		Addr_ff <= 23'd0;
		DQ_ff <= 16'd0;
		nCE_ff<=1'b1;
		nADV_ff<=1'b1;
		nOE_ff<=1'b1;
		nWE_ff<=1'b1;
		nLB_ff<=1'b1;
		nUB_ff<=1'b1;
		CRE_ff<=1'b0;
		count_ff <= 15'd1;
		Done_ff<=1'b0;
		rd_data_ff<=3'd0;
		DQ_wr_ff <= 1'b0;
		DQ_rd_ff <= 1'b0;
		cfgDone_ff <= 1'b0;
		end
	else 
		begin
		cfg_state_ff <= cfg_state_nxt;
		Addr_ff <= Addr_nxt;
		DQ_ff <= DQ_nxt;
		nCE_ff <= nCE_nxt;
		nADV_ff <= nADV_nxt;
		nOE_ff <= nOE_nxt;
		nWE_ff <= nWE_nxt;
		CRE_ff <= CRE_nxt;
		count_ff <= count_nxt;
		nLB_ff <= nLB_nxt;
		nUB_ff <= nUB_nxt;
		Done_ff<=Done_nxt;
		rd_data_ff<=rd_data_nxt;
		DQ_wr_ff <= DQ_wr_nxt;
		DQ_rd_ff <= DQ_rd_nxt;
		cfgDone_ff <= cfgDone_nxt;
		end
end

//Burst state machine registers
always @(posedge clk160_i or posedge rst)
begin
	if (rst)
		begin
		brst_state_ff <= s_brst_wait10;
		brst_Addr_ff <= 23'd0;
		brst_DQ_ff <= 16'd0;
		brst_nCE_ff<=1'b1;
		brst_nADV_ff<=1'b1;
		brst_nOE_ff<=1'b1;
		brst_nWE_ff<=1'b1;
		brst_nLB_ff<=1'b1;
		brst_nUB_ff<=1'b1;
		brst_CRE_ff<=1'b0;
		brst_count_ff <= 15'd1;
		brst_mem_clk_en_ff <= 1'b0;
		brst_ren_ff <= 1'b0;
		brst_wen_ff <= 1'b0;
		brst_done_ff <= 1'b1;
		end
	else 
		begin
		brst_state_ff <= brst_state_nxt;
		brst_Addr_ff <= brst_Addr_nxt;
		brst_DQ_ff <= brst_DQ_nxt;
		brst_nCE_ff <= brst_nCE_nxt;
		brst_nADV_ff <= brst_nADV_nxt;
		brst_nOE_ff <= brst_nOE_nxt;
		brst_nWE_ff <= brst_nWE_nxt;
		brst_CRE_ff <= brst_CRE_nxt;
		brst_count_ff <= brst_count_nxt;
		brst_nLB_ff <= brst_nLB_nxt;
		brst_nUB_ff <= brst_nUB_nxt;
		brst_mem_clk_en_ff <= brst_mem_clk_en_nxt;
		brst_ren_ff <= brst_ren_nxt;
		brst_wen_ff <= brst_wen_nxt;
		brst_done_ff <= brst_done_nxt;
		end
end

always @(posedge clk160_i or posedge rst)
begin
	if (rst)
		begin
		DQ_sel <= 1'b0;
		end
	else begin
		 if (~brst_ren_ff & brst_ren_nxt)
			DQ_sel <= 1'b1;
		 else if (~brst_ren_ff & ~brst_ren_nxt)
			DQ_sel <= 1'b0;
	end
end

assign brst_ren = brst_ren_ff;
assign brst_wen = brst_wen_ff;
assign brst_dout = DQ;
assign brst_Done = brst_done_ff;

//Memory signals
assign Addr =(cfgDone) ? (brst_Addr_ff):(Addr_ff);
// assign DQ = (cfgDone) ? (brst_ren ? brst_din : 16'bz) : (DQ_wr_ff ? DQ_ff : 16'bz) ;
assign DQ = (cfgDone) ? (DQ_sel ? brst_din : 16'bz) : (DQ_wr_ff ? DQ_ff : 16'bz) ;
assign DQ_in = (DQ_rd_ff) ? DQ : 16'd0;	//nu era necesar dar il las asa. Pt burst nu mai trebuie facut la fel
assign nCE = (cfgDone) ? (brst_nCE_ff) : (nCE_ff);
assign nADV = (cfgDone) ? brst_nADV_ff : nADV_ff;
assign nOE = (cfgDone) ? brst_nOE_ff : nOE_ff;
assign nWE = (cfgDone) ? brst_nWE_ff : nWE_ff;
assign CRE = (cfgDone) ? brst_CRE_ff : CRE_ff;
assign nLB = (cfgDone) ? brst_nLB_ff : nLB_ff;
assign nUB = (cfgDone) ? brst_nUB_ff : nUB_ff;
assign mem_clk_en = brst_mem_clk_en_ff;

//Controller flags
assign LED = rd_data_ff[2:0];
assign cfgDone = cfgDone_ff;

endmodule
