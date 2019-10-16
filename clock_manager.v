`timescale 1ns / 1ps

module clock_manager(
    input clk,		//100
    output xclk,	//24
    output vga_clk,//25
	 output xclk_p,
	 output clk80,	//80
	 output nclk80,//n80
	 output clk160//160
    );

wire clk_fb,xclk_n;
	
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
   DCM_SP_24_25 (
		.PSEN(1'b0),
		.DSSEN(1'b0), 
      .CLK0(clk_fb),         // 1-bit output: 0 degree clock output
      .CLKDV(vga_clk),       // 1-bit output: Divided clock output
      .CLKFX(xclk_p),       // 1-bit output: Digital Frequency Synthesizer output (DFS)
		.CLKFX180(xclk_n),
      .CLKFB(clk_fb),       // 1-bit input: Clock feedback input
      .CLKIN(clk),       // 1-bit input: Clock input
      .RST(1'b0)            // 1-bit input: Active high reset input
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
   .Q(xclk),   // 1-bit DDR output data
   .C0(xclk_p), // 1-bit clock input
   .C1(xclk_n), // 1-bit clock input
   .CE(1'b1), // 1-bit clock enable input
   .D0(1'b1), // 1-bit data input (associated with C0)
   .D1(1'b0), // 1-bit data input (associated with C1)
   .R(1'b0),   // 1-bit reset input
   .S(1'b0)    // 1-bit set input
);	

DCM_SP #(
      .CLKDV_DIVIDE(2.0),                   // CLKDV divide value
                                            // (1.5,2,2.5,3,3.5,4,4.5,5,5.5,6,6.5,7,7.5,8,9,10,11,12,13,14,15,16).
      .CLKFX_DIVIDE(5),                     // Divide value on CLKFX outputs - D - (1-32)
      .CLKFX_MULTIPLY(4),                   // Multiply value on CLKFX outputs - M - (2-32)
      .CLKIN_DIVIDE_BY_2("FALSE"),          // CLKIN divide by two (TRUE/FALSE)
      .CLKIN_PERIOD(10.0),                  // Input clock period specified in nS
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
   DCM_SP_clk80 (
//      .CLK0(CLK0),         // 1-bit output: 0 degree clock output
//      .CLK180(CLK180),     // 1-bit output: 180 degree clock output
//      .CLK270(CLK270),     // 1-bit output: 270 degree clock output
//      .CLK2X(CLK2X),       // 1-bit output: 2X clock frequency clock output
//      .CLK2X180(CLK2X180), // 1-bit output: 2X clock frequency, 180 degree clock output
//      .CLK90(CLK90),       // 1-bit output: 90 degree clock output
//      .CLKDV(CLKDV),       // 1-bit output: Divided clock output
      .CLKFX(clk80),       // 1-bit output: Digital Frequency Synthesizer output (DFS)
      .CLKFX180(nclk80), // 1-bit output: 180 degree CLKFX output
//      .LOCKED(LOCKED),     // 1-bit output: DCM_SP Lock Output
//      .PSDONE(PSDONE),     // 1-bit output: Phase shift done output
//      .STATUS(STATUS),     // 8-bit output: DCM_SP status output
//      .CLKFB(CLKFB),       // 1-bit input: Clock feedback input
      .CLKIN(clk)       // 1-bit input: Clock input
//      .DSSEN(DSSEN),       // 1-bit input: Unsupported, specify to GND.
//      .PSCLK(PSCLK),       // 1-bit input: Phase shift clock input
//      .PSEN(PSEN),         // 1-bit input: Phase shift enable
//      .PSINCDEC(PSINCDEC), // 1-bit input: Phase shift increment/decrement input
//      .RST(RST)            // 1-bit input: Active high reset input
   );

DCM_SP #(
      .CLKDV_DIVIDE(2.0),                   // CLKDV divide value
                                            // (1.5,2,2.5,3,3.5,4,4.5,5,5.5,6,6.5,7,7.5,8,9,10,11,12,13,14,15,16).
      .CLKFX_DIVIDE(5),                     // Divide value on CLKFX outputs - D - (1-32)
      .CLKFX_MULTIPLY(8),                   // Multiply value on CLKFX outputs - M - (2-32)
      .CLKIN_DIVIDE_BY_2("FALSE"),          // CLKIN divide by two (TRUE/FALSE)
      .CLKIN_PERIOD(10.0),                  // Input clock period specified in nS
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
   DCM_SP_clk160 (
//      .CLK0(CLK0),         // 1-bit output: 0 degree clock output
//      .CLK180(CLK180),     // 1-bit output: 180 degree clock output
//      .CLK270(CLK270),     // 1-bit output: 270 degree clock output
//      .CLK2X(CLK2X),       // 1-bit output: 2X clock frequency clock output
//      .CLK2X180(CLK2X180), // 1-bit output: 2X clock frequency, 180 degree clock output
//      .CLK90(CLK90),       // 1-bit output: 90 degree clock output
//      .CLKDV(CLKDV),       // 1-bit output: Divided clock output
      .CLKFX(clk160),       // 1-bit output: Digital Frequency Synthesizer output (DFS)
//      .CLKFX180(CLKFX180), // 1-bit output: 180 degree CLKFX output
//      .LOCKED(LOCKED),     // 1-bit output: DCM_SP Lock Output
//      .PSDONE(PSDONE),     // 1-bit output: Phase shift done output
//      .STATUS(STATUS),     // 8-bit output: DCM_SP status output
//      .CLKFB(CLKFB),       // 1-bit input: Clock feedback input
      .CLKIN(clk)       // 1-bit input: Clock input
//      .DSSEN(DSSEN),       // 1-bit input: Unsupported, specify to GND.
//      .PSCLK(PSCLK),       // 1-bit input: Phase shift clock input
//      .PSEN(PSEN),         // 1-bit input: Phase shift enable
//      .PSINCDEC(PSINCDEC), // 1-bit input: Phase shift increment/decrement input
//      .RST(RST)            // 1-bit input: Active high reset input
   );

endmodule
