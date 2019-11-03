`timescale 1ns / 1ps

module top(
	//Psram signals
	output 	[22:0]	mem_Addr,
	inout 	[15:0] 	mem_DQ,
	output mem_nCE,			//Chip enable
   output mem_nOE,			//Output enable
   output mem_nWE,			//Write enable
   output mem_nADV,			//Address valid
   output mem_CRE,			//Control register enable
   output mem_nLB,			//Lower byte enable
   output mem_nUB,			//Upper byte enable
	output mem_clk,			//Clock output to memory
	output mem_cfgDone,		//Memory configuration flag
	//Camera signals
	output cam_sioc_o,		//I2C clock line for camera configuration
	inout  cam_siod_io,		//I2C data line for camera configuration
	output cam_cfg_done,		//Camera configuration done flag
	output cam_pwdn_o,		//Camera power down
	//-----------//
	input cam_pclk,			//Camera pixel clock input
	output cam_xclk,			//Camera global clock output
	input cam_href_i,			//Href input from camera
	input cam_vsync_i,		//Hsync input from camera
	input [7:0] cam_din,		//Video data from camera
	//VGA signals
	output vga_hs,				//VGA horizontal sync signal
	output vga_vs,				//VGA vertical sync signal
	output [2:0] vga_red,	//VGA red color signal
	output [2:0] vga_green,	//VGA green color signal
	output [1:0] vga_blue,	//VGA blue color signal
	//System clock and reset
	input clk,					//System clock 100 MHz
	input rst,					//Global reset
	//Others
	output cam_err_l,			//cam FIFO error
	output vga_err_l,			//vga FIFO error
	//for DEBUG//
	input latch_r
    );
	 
	 wire blank;
	 wire brst_Go;						//Burst start operation 
	 wire [22:0] brst_Addr_in;		//Burst address 
	 wire brst_Wr;						//Burst write  ; 1=write ; 0=read
	 wire brst_Done;					//Burst done flag
	 wire brst_ren;					//Burst read enable to fifo
	 wire [15:0] brst_din;			//Burst write data in
	 wire brst_wen;					//Burst write enable to fifo
	 wire [15:0] brst_dout;			//Burst data output
	 
	 wire clk24;	//xclk
	 wire clk25;	//vga_controller clock and vga buffer clock(READ)
	 wire clk80;	//mem_clk and vga buffer clock(WRITE)
	 wire nclk80;	//camera buffer clock(READ)
	 //wire clk100;	//memory configuration state machine clock
	 wire clk160;	//burst access state machine clock
		
	 assign cam_pwdn_o = 1'b0;
		
	 wire [7:0] vga_data;
	 assign vga_red = blank ? 3'b000 : vga_data[7:5];
	 assign vga_green = blank ? 3'b000 :  vga_data[7:5];
	 assign vga_blue = blank ? 2'b00 : vga_data[7:6];
	 
	 wire [7:0] cam_buff_dout;
	 assign brst_din = {8'd0, cam_buff_dout};
	 
	 reg brst_Go_ff;
	 reg Y, href_ff;
	 wire vsync_ok, vga_vs_ok;
	 reg  vsync_ff, vga_vs_ff;
	 reg [3:0] frame_cnt;
	 reg [3:0] frame_cnt2;
SR_latch SR1(
.R(latch_r),
.S(cam_err),
.Q(cam_err_l)
);

SR_latch SR2(
.R(latch_r),
.S(vga_err),
.Q(vga_err_l)
);

always @(posedge cam_pclk or posedge rst)begin
	if (rst)
		frame_cnt <= 0;
	else if ((~cam_vsync_i&vsync_ff)&&(frame_cnt<4))
		frame_cnt <= frame_cnt + 1;
end

assign vsync_ok = (frame_cnt == 4) ? 1 : 0;

always @(posedge clk25 or posedge rst)begin
	if (rst)
		frame_cnt2 <= 0;
	else if ((vga_vs&~vga_vs_ff)&&(frame_cnt2<4))
		frame_cnt2 <= frame_cnt2 + 1;
end

assign vga_vs_ok = (frame_cnt2 == 4) ? 1 : 0;

always @(posedge clk25)begin
		vga_vs_ff <= vga_vs;
end
always @(posedge cam_pclk)begin
		href_ff <= cam_href_i;
		vsync_ff <= cam_vsync_i;
	end
		
always @(posedge cam_pclk or posedge rst) begin
	if (rst)
		Y <= 1;
	else if (cam_href_i==0 & href_ff==1)begin
		Y <= 1;
	end
	else if (cam_href_i==1)
		Y <= ~Y;
end

Camera_buffer Camera_buffer (
  .rst(rst|(~mem_cfgDone)), 
  .wr_clk(cam_pclk),
  .rd_clk(nclk80),
  .din(cam_din), 
  .wr_en(cam_cfg_done&cam_href_i&~Y&vsync_ok), 
  .rd_en(brst_ren),
  .dout(cam_buff_dout), 
  .overflow(cam_err), 
  .prog_full(cam_req)
);

psram_ctrl psram_ctrl(
	 //Memory signals
    .Addr(mem_Addr),			//Address bus
	 .DQ(mem_DQ),				//Data bus
    .nCE(mem_nCE),			//Chip enable
    .nOE(mem_nOE),			//Output enable
    .nWE(mem_nWE),			//Write enable
    .nADV(mem_nADV),			//Address valid
    .CRE(mem_CRE),			//Control register enable
    .nLB(mem_nLB),			//Lower byte enable
    .nUB(mem_nUB),			//Upper byte enable
	 //.clk_mem(mem_clk),		//Clock output to memory

    .cfgDone(mem_cfgDone),		//Memory configuration flag
     //Arbiter interface
	 .brst_Go(brst_Go_ff),				//Burst start operation input
	 .brst_Addr_in(brst_Addr_in),	//Burst address 
	 .brst_Wr(brst_Wr),				//Burst write input ; 1=write , 0=read
	 .brst_Done(brst_Done),			//Burst done flag
	 //
	 //Interface to CAM buffer
	 .brst_ren(brst_ren),			//Burst read enable to fifo
	 .brst_din(brst_din),			//Burst write data in
	 //Interface to VGA buffer
	 .brst_wen(brst_wen),			//Burst write enable to fifo
	 .brst_dout(brst_dout),			//Burst data out
	 
	 .clk160_i(clk160),			//Clock for burst access state machine
	 .clk100_i(clk100),			//Clock for configuration state machine
	 .rst(rst),					//Reset input
	 .mem_clk_en(mem_clk_en)
    );

VGA_buffer VGA_buffer (
  .rst(rst|(~mem_cfgDone)),
  .wr_clk(clk80), 
  .rd_clk(clk25), 
  .din(brst_dout[7:0]), 
  .wr_en(brst_wen), 
  .rd_en(~blank&vga_vs_ok), 
  .dout(vga_data), 
  .underflow(vga_err),
  .prog_empty(vga_req)
);

arbiter arbiter(
    //.clk80(clk80),
	 .clk80(clk160),
	 .rst(rst|(~mem_cfgDone)),
    .Go(brst_Go),
    .Done(brst_Done),
    .Wr(brst_Wr),
    .brst_Addr(brst_Addr_in),
    .vga_rst(vga_rst),
    .cam_req(cam_req),
    .vga_req(vga_req)
    );
//Additional ff stage
//bug fix for psram controller mem_clk en on negedge
always @(posedge clk80)
      if (rst) begin
         brst_Go_ff <= 0;
      end else begin
         brst_Go_ff <= brst_Go;
      end

 CameraSetup CameraSetup (
		 .clk_i(clk24), 
		 .rst_i(~rst), 
		 .done(cam_cfg_done), 
		 .sioc_o(cam_sioc_o), 
		 .siod_io(cam_siod_io)
 );
  /*
 vga_ctrl vga_ctrl(
	.px_clk(clk25),
	.rst(vga_rst),	
	.hs(vga_hs),
	.vs(vga_vs),
	.blank(blank)
);
*/

dispaly_timing_controller vga_ctrl(
.clk(clk25),
.rst(vga_rst),
.hs(vga_hs),
.vs(vga_vs),
.active_video_area(blank),
.x(),
.y()
);
		
clock_manager_core clocking_unit
   (									// Clock in ports
    .clk(clk),      				// IN
										// Clock out ports
    .clk160(clk160),     		// OUT
    //.clk80_CE(mem_clk_en),  	// IN
    .clk80(clk80),     			// OUT
    //.clk80n_CE(mem_clk_en),  	// IN
    .clk80n(nclk80),     		// OUT
    .clk25(clk25),     			// OUT
	 .clk100(clk100));    		// OUT
	 
	 //Memory clock enable

BUFGCE BUFGCE_clk_mem_o (
      .O(clk_80_gt),   
      .CE(mem_clk_en), 
      .I(clk80)    
   );
	
BUFGCE BUFGCE_clk_mem_n_o (
      .O(clk_n_80_gt),   
      .CE(mem_clk_en), 
      .I(nclk80)    
   );
	
ODDR2 #(
   // The following parameters specify the behavior
   // of the component.
   .DDR_ALIGNMENT("NONE"), // Sets output alignment
                           // to "NONE", "C0" or "C1"
   .INIT(1'b0),    // Sets initial state of the Q 
                   //   output to 1'b0 or 1'b1
   .SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC"
                   //   set/reset
)
ODDR2_inst (
   .Q(mem_clk),   // 1-bit DDR output data
   .C0(clk_80_gt), // 1-bit clock input
   .C1(clk_n_80_gt), // 1-bit clock input
//   .C0(clk_n_80_gt), // 1-bit clock input
//   .C1(clk_80_gt), // 1-bit clock input
   .CE(1'b1), // 1-bit clock enable input
   .D0(1'b1), // 1-bit data input (associated with C0)
   .D1(1'b0), // 1-bit data input (associated with C1)
   .R(1'b0),   // 1-bit reset input
   .S(1'b0)    // 1-bit set input
);    // OUT

ODDR2 #(
   // The following parameters specify the behavior
   // of the component.
   .DDR_ALIGNMENT("NONE"), // Sets output alignment
                           // to "NONE", "C0" or "C1"
   .INIT(1'b0),    // Sets initial state of the Q 
                   //   output to 1'b0 or 1'b1
   .SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC"
                   //   set/reset
)
ODDR2_inst2 (
   .Q(cam_xclk),   // 1-bit DDR output data
   .C0(clk24), // 1-bit clock input
   .C1(~clk24), // 1-bit clock input
   .CE(1'b1), // 1-bit clock enable input
   .D0(1'b1), // 1-bit data input (associated with C0)
   .D1(1'b0), // 1-bit data input (associated with C1)
   .R(1'b0),   // 1-bit reset input
   .S(1'b0)    // 1-bit set input
);	

DCM_SP #(
      .CLKDV_DIVIDE(2),                   // CLKDV divide value
                                            // (1.5,2,2.5,3,3.5,4,4.5,5,5.5,6,6.5,7,7.5,8,9,10,11,12,13,14,15,16).
      .CLKFX_DIVIDE(25),                     // Divide value on CLKFX outputs - D - (1-32)
      .CLKFX_MULTIPLY(6),                   // Multiply value on CLKFX outputs - M - (2-32)
      .CLKIN_DIVIDE_BY_2("FALSE"),          // CLKIN divide by two (TRUE/FALSE)
      .CLKIN_PERIOD(20.0),                  // Input clock period specified in nS
      .CLKOUT_PHASE_SHIFT("NONE"),          // Output phase shift (NONE, FIXED, VARIABLE)
      .CLK_FEEDBACK("1X"),                  // Feedback source (NONE, 1X, 2X)
      .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), // SYSTEM_SYNCHRNOUS or SOURCE_SYNCHRONOUS
      .DFS_FREQUENCY_MODE("LOW"),           // Unsupported - Do not change value
      .DLL_FREQUENCY_MODE("LOW"),           // Unsupported - Do not change value
      .DSS_MODE("NONE"),                    // Unsupported - Do not change value
      .DUTY_CYCLE_CORRECTION("TRUE"),       // Unsupported - Do not change value
      .FACTORY_JF(16'hc080),                // Unsupported - Do not change value
      .PHASE_SHIFT(0),                      // Amount of fixed phase shift (-255 to 255)
      .STARTUP_WAIT("FALSE")                // Delay config DONE until DCM_SP LOCKED (TRUE/FALSE)
   )
   DCM_SP_24 (
		.PSEN(1'b0),
		.DSSEN(1'b0), 
      .CLKFX(clk24),       // 1-bit output: Digital Frequency Synthesizer output (DFS)
      .CLKIN(clk100),       // 1-bit input: Clock input
      .RST(1'b0)            // 1-bit input: Active high reset input
   );

endmodule
