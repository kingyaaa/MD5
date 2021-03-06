
//=======================================================
//  This code is generated by Terasic System Builder
//=======================================================

module exp12(

	//////////// CLOCK //////////
	input 		          		CLOCK2_50,
	input 		          		CLOCK3_50,
	input 		          		CLOCK4_50,
	input 		          		CLOCK_50,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// SW //////////
	input 		     [9:0]		SW,

	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// Seg7 //////////
	output		     [6:0]		HEX0,
	output		     [6:0]		HEX1,
	output		     [6:0]		HEX2,
	output		     [6:0]		HEX3,
	output		     [6:0]		HEX4,
	output		     [6:0]		HEX5,

	//////////// VGA //////////
	output		          		VGA_BLANK_N,
	output		     [7:0]		VGA_B,
	output		          		VGA_CLK,
	output		     [7:0]		VGA_G,
	output		          		VGA_HS,
	output		     [7:0]		VGA_R,
	output		          		VGA_SYNC_N,
	output		          		VGA_VS,

	//////////// PS2 //////////
	inout 		          		PS2_CLK,
	inout 		          		PS2_CLK2,
	inout 		          		PS2_DAT,
	inout 		          		PS2_DAT2
);



//=======================================================
//  REG/WIRE declarations
//=======================================================
wire [7:0] ascii;
wire [9:0] h_addr;
wire [9:0] v_addr;
wire [23:0]vga_data;
wire ready;
wire wclk,en;
wire [7:0] outdata,trdata;
wire Nwren;
wire [63:0] total_len;
wire [8:0] strlen;

wire [31:0] print;
wire [7:0] number;
wire [63:0] temp;
//=======================================================
//  Structural coding
//=======================================================


asc2pdot(
 .clk(CLOCK_50),
 .vga_clk(VGA_CLK),
 .ascii(ascii),
 .v_addr(v_addr),
 .blank_n(VGA_BLANK_N),
 .vga_data(vga_data),
 .en(en),
 .reset(~KEY[0]),
 //.count_wren(number),
 .total_length(temp)
);


clkgen #(25000000) vgaclk(
	.clkin(CLOCK_50),
	.rst(~KEY[0]),
	.clken(1'b1),
	.clkout(VGA_CLK)
);

kbd mykbd(
	.clk(CLOCK_50),
	.clrn(KEY[0]),
	.ps2_clk(PS2_CLK),
	.ps2_data(PS2_DAT),
	.outdata(ascii),
	.en(en)
);

vga_ctrl myvga_ctrl(
	.pclk(VGA_CLK),
	.reset(KEY[0]),
	.vga_data(vga_data),
	.h_addr(h_addr),
	.v_addr(v_addr),
	.hsync(VGA_HS),
	.vsync(VGA_VS),
	.valid(VGA_BLANK_N),
	.vga_r(VGA_R),
	.vga_g(VGA_G),
	.vga_b(VGA_B)
);


seven sv5(
	.in_q({1'b0,temp[23:20]}),
	.h(HEX5)
);

seven sv4(
	.in_q({1'b0,temp[19:16]}),
	.h(HEX4)
);

seven sv3(
	.in_q({1'b0,temp[15:12]}),
	.h(HEX3)
);

seven sv2(
	.in_q({1'b0,temp[11:8]}),
	.h(HEX2)
);

seven sv1(
	.in_q({1'b0,temp[7:4]}),
	.h(HEX1)
);

seven sv0(
	.in_q({1'b0,temp[3:0]}),
	.h(HEX0)
);

assign LEDR[7:0] = temp[31:24]; 

endmodule
