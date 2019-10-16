//Counter widths
parameter Row_size = 11;
parameter Col_size = 11;

//States for horizontal controller

parameter s_HRST = 3'h0;
parameter s_HS = 3'h1;
parameter s_HBP = 3'h2;
parameter s_HACT = 3'h3;
parameter s_HFP = 3'h4;

//States for vertical controller

parameter s_VRST = 3'h0;
parameter s_VS = 3'h1;
parameter s_VBP = 3'h2;
parameter s_VACT = 3'h3;
parameter s_VFP = 3'h4;


/////////////////////////////////////////////////////////////////////////////////////////////////////////

////////640x480///////////

//Horizontal timing

parameter t1H = 10'd96;
parameter t2H = 10'd144;
parameter t3H = 10'd784;
parameter t4H = 10'd800;


//Vertical timing

parameter t1V = 10'd2;
parameter t2V = 10'd31;
parameter t3V = 10'd511;
parameter t4V = 10'd521;

///////////////////////////

////////for testing///////////
/*
//Horizontal timing

parameter t1H = 11'd2;
parameter t2H = 11'd4;
parameter t3H = 11'd6;
parameter t4H = 11'd8;


//Vertical timing

parameter t1V = 11'd2;
parameter t2V = 11'd4;
parameter t3V = 11'd6;
parameter t4V = 11'd8;
*/
///////////////////////////

//t1 = Tpw
//t2 = Tpw + Tbp
//t3 = Tpw + Tbp + Tdisp
//t4 = Tpw + Tbp + Tdisp + Tfp