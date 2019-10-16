//========================================
//Memory configuration register parameters
//========================================

//========================================
parameter Reg_sel = 2'b10; 		 //Select Bus Conifguration Register
parameter Op_mode = 1'b0;  		 //Synchronous mode
parameter Init_lat = 1'b1;  		 //Fixed Latency
parameter Lat_cnt = 3'b000;		 //Latency code 8 (9 clocks before data) 
parameter Wait_pol = 1'b1;			 //Wait polarity high
parameter Wait_cfg = 1'b0;	 		 //Wait asserted during delay
parameter Drv_stg = 2'b01; 		 //Drive strength 1/2
parameter Brst_wrp = 1'b1;	 		 //No burst wrap
parameter Brst_lngth = 3'b100;	 //Burst length 32 words
//========================================
//States for configuration state machine
//========================================
parameter s_cfg_PowerUp = 		4'd0;
parameter s_cfg_RegWr_init = 	4'd1;
parameter s_cfg_RegWr_CE = 		4'd2;
parameter s_cfg_RegWr_ADV = 	4'd3;
parameter s_cfg_RegWr_nWE = 	4'd4;
parameter s_cfg_RegWr_WE = 		4'd5;
parameter s_cfg_RegWr_End = 	4'd6;
parameter s_cfg_Adr5Rd_CE = 	4'd7;
parameter s_cfg_Adr5Rd_OE = 	4'd8;
parameter s_cfg_Adr5Rd_RdDQ = 	4'd9;
parameter s_cfg_Adr5Rd_End = 	4'd10;
parameter s_cfg_Adr5Wr_CE = 	4'd11;
parameter s_cfg_Adr5Wr_WE = 	4'd12;
parameter s_cfg_Adr5Wr_End = 	4'd13;
//========================================
//States for burst acces state machine
//========================================
parameter s_brst_wait10 = 		4'd0;
parameter s_brst_idle = 		4'd1;

parameter s_brst_wr_start = 	4'd2;
parameter s_brst_wr_nCE = 		4'd3;
parameter s_brst_wr_nADV = 		4'd4;
parameter s_brst_wr_Addr = 		4'd5;
parameter s_brst_wr_Ren = 		4'd6;
parameter s_brst_wr_nRen = 		4'd7;
parameter s_brst_wr_End = 		4'd8;

parameter s_brst_rd_start = 	4'd9;
parameter s_brst_rd_nCE = 		4'd10;
parameter s_brst_rd_nADV = 		4'd11;
parameter s_brst_rd_Addr = 		4'd12;
parameter s_brst_rd_Ren = 		4'd13;
parameter s_brst_rd_nRen = 		4'd14;
parameter s_brst_rd_End = 		4'd15;
//========================================
//Burst access state machine parameters
parameter Burst_length = 32;
parameter Opcode = {3'b000, Reg_sel, 2'b00, Op_mode, Init_lat, Lat_cnt, Wait_pol, 1'b0, Wait_cfg, 2'b00, Drv_stg, Brst_wrp, Brst_lngth};
