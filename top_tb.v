`timescale 1ns / 10ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   20:09:30 08/06/2015
// Design Name:   top
// Module Name:   D:/FPGA/Licenta/camera_interface_project/camera_interface_project/top_tb.v
// Project Name:  camera_interface_project
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module top_tb;
	//Inputs
	reg clk;
	reg rst;
	wire [15:0] mem_DQ;
	// Outputs
	wire [22:0] mem_Addr;
	wire mem_nCE;
	//wire mem_nOE;
	wire mem_nWE;
	wire mem_nADV;
	//wire mem_CRE;
	//wire mem_nLB;
	//wire mem_nUB;
	wire mem_clk;
	//wire mem_cfgDone;
	//wire cam_sioc_o;
	//wire cam_cfg_done;
	//wire cam_pwdn_o;
	//wire cam_xclk;
	//wire vga_hs;
	//wire vga_vs;
	wire [2:0] vga_red;
	wire [2:0] vga_green; 
	wire [1:0] vga_blue;
	wire cam_err_l;
	wire vga_err_l;
	wire [7:0] cam_din;
	
	wire [2:0] r,g;
	wire [1:0] b;
	// Bidirs
	
	//wire cam_siod_io;
	
	assign r = uut.vga_red;
	assign g = uut.vga_green;
	assign b = uut.vga_blue;
	
	cellram cellram (
    .clk(mem_clk), 
    .adv_n(mem_nADV),
    .cre(mem_CRE),
    .ce_n(mem_nCE),
    .oe_n(mem_nOE),
    .we_n(mem_nWE),
    .lb_n(mem_nLB),
    .ub_n(mem_nUB),
    .addr(mem_Addr),
    .dq(mem_DQ) 
); 
	
	sim_camera sim_camera(
		 .xclk(cam_xclk),
		 .n_rst(~rst),
		 .pclk(cam_pclk),
		 .href(cam_href_i),
		 .vsync(cam_vsync_i),
		 .data(cam_din)
);
	
	// Instantiate the Unit Under Test (UUT)
	top uut (
	//top_synth uut (
		.mem_Addr(mem_Addr), 
		.mem_DQ(mem_DQ), 
		.mem_nCE(mem_nCE), 
		.mem_nOE(mem_nOE), 
		.mem_nWE(mem_nWE), 
		.mem_nADV(mem_nADV), 
		.mem_CRE(mem_CRE), 
		.mem_nLB(mem_nLB), 
		.mem_nUB(mem_nUB), 
		.mem_clk(mem_clk), 
		.mem_cfgDone(mem_cfgDone), 
		.cam_sioc_o(cam_sioc_o), 
		.cam_siod_io(cam_siod_io), 
		.cam_cfg_done(cam_cfg_done), 
		.cam_pclk(cam_pclk), 
		.cam_xclk(cam_xclk), 
		.cam_href_i(cam_href_i), 
		.cam_vsync_i(cam_vsync_i), 
		.cam_din(cam_din), 
		.vga_hs(vga_hs), 
		.vga_vs(vga_vs), 
		.vga_red(vga_red), 
		.vga_green(vga_green), 
		.vga_blue(vga_blue), 
		.clk(clk), 
		.rst(rst), 
		.cam_err_l(cam_err_l), 
		.vga_err_l(vga_err_l)

	);
	
	image_write im_wr(
	  .HCLK(uut.clk25),
	  .HRESETn(rst),
	  .hsync(~uut.blank),
	  .DATA_IN({r,g,b}),
	  .Write_Done()
	);
	
	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 1;
		// Wait 100 ns for global reset to finish
		#100;
		rst = 0;  
		#50;
		force uut.CameraSetup.done = 1'b1;
		// Add stimulus here
		#58_000_000;//58ms
		$finish;

	end
   
	always begin
	#5 clk = ~clk;
	end
endmodule

