//========================================
//States for arbiter state machine
//========================================
parameter s_arb_idle = 			4'd0;
parameter s_arb_cam_req_go = 	4'd1;
parameter s_arb_cam_req = 		4'd2;
parameter s_arb_vga_req_go = 	4'd3;
parameter s_arb_vga_req = 		4'd4;
//========================================
parameter brst_no = 9600;
//parameter brst_no = 4;
parameter max_addr = (brst_no-1)*32;
parameter max_addr0 = (brst_no-1)*32;
parameter max_addr1 = (2*brst_no-1)*32;