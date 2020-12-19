module md5update(clk,string,input_len,en,complete,A,B,C,D);
	
	
	input clk;
	input [8:0] input_len;//64bit的数，表示信息的字节数
	input [511:0]string;//字节 * 8bit
	input en;
	
	output reg complete;//计算结束标
	
	
	reg [511:0]update_str;//字节 * 8bit
	reg [8:0]update_str_length;//字节数
	//reg [57:0] div_group;	//切割，每组512bit 
	reg [9:0] remain_byte;	//余下的bit数，需要进行相应的填充
	reg [5:0] padding;//填充的字符？
	input [31:0] A;
	input [31:0] B;
	input [31:0] C;
	input [31:0] D;
	reg [31:0] a;
	reg [31:0] b;
	reg [31:0] c;
	reg [31:0] d;
	reg [31:0] temp;
	
	`define F(x,y,z) ((x&y) | ((~x)&z))
	`define G(X,Y,Z) ((X&Z) | (Y&(~Z)))
	`define H(X,Y,Z) (X ^ Y ^ Z)
   `define I(X,Y,Z) (Y ^ (X| (~Z)))
	
	always @ (posedge en)
	begin
		a = A;
		b = B;
		c = C;
		d = D;
		/*
		  0xd76aa478,0xe8c7b756,0x242070db,0xc1bdceee,
        0xf57c0faf,0x4787c62a,0xa8304613,0xfd469501,0x698098d8,
        0x8b44f7af,0xffff5bb1,0x895cd7be,0x6b901122,0xfd987193,
        0xa679438e,0x49b40821,0xf61e2562,0xc040b340,0x265e5a51,
        0xe9b6c7aa,0xd62f105d,0x02441453,0xd8a1e681,0xe7d3fbc8,
        0x21e1cde6,0xc33707d6,0xf4d50d87,0x455a14ed,0xa9e3e905,
        0xfcefa3f8,0x676f02d9,0x8d2a4c8a,0xfffa3942,0x8771f681,
        0x6d9d6122,0xfde5380c,0xa4beea44,0x4bdecfa9,0xf6bb4b60,
        0xbebfbc70,0x289b7ec6,0xeaa127fa,0xd4ef3085,0x04881d05,
        0xd9d4d039,0xe6db99e5,0x1fa27cf8,0xc4ac5665,0xf4292244,
        0x432aff97,0xab9423a7,0xfc93a039,0x655b59c3,0x8f0ccc92,
        0xffeff47d,0x85845dd1,0x6fa87e4f,0xfe2ce6e0,0xa3014314,
        0x4e0811a1,0xf7537e82,0xbd3af235,0x2ad7d2bb,0xeb86d391
		*/
		
		//(b&c) | ((~b)&d)
		
		temp = a + `F(b,c,d) + string[31:0]   + 32'h78a46ad7;
		temp = {temp[24:0],temp[31:25]};
		a = b + temp;
		
		temp = d + `F(a,b,c) + string[63:32]  + 32'h56b7c7e8;
		temp = {temp[19:0],temp[31:20]};
		d = a + temp;
		
		temp = c + `F(d,a,b) + string[95:64]  + 32'hdb702024;
		temp = {temp[14:0],temp[31:15]};
		c = d + temp;
		 
		temp = b + `F(c,d,a) + string[127:96] + 32'heecebdc1; 
		temp = {temp[9:0],temp[31:10]};
		b = c + temp;
		 
		temp = a + `F(b,c,d) + string[159:128]+ 32'haf0f7cf5; 
		temp = {temp[24:0],temp[31:25]};
		a = b + temp;
		
		temp = d + `F(a,b,c) + string[191:160]+ 32'h2ac68747; 
		temp = {temp[19:0],temp[31:20]};
		d = a + temp;
		
		temp = c + `F(d,a,b) + string[223:192]+ 32'h134630a8; 
		temp = {temp[14:0],temp[31:15]};
		c = d + temp;
		
		temp = b + `F(c,d,a) + string[255:224]+ 32'h019546fd; 
		temp = {temp[9:0],temp[31:10]};
		b = c + temp;
		
		temp = a + `F(b,c,d) + string[287:256]+ 32'hd8988069; 
		temp = {temp[24:0],temp[31:25]};
		a = b + temp;
		
		temp = d + `F(a,b,c) + string[319:288]+ 32'haff7448b; 
		temp = {temp[19:0],temp[31:20]};
		d = a + temp;
		
		temp = c + `F(d,a,b) + string[351:320]+ 32'hb15bffff; 
		temp = {temp[14:0],temp[31:15]};
		c = d + temp;
		
		temp = b + `F(c,d,a) + string[383:352]+ 32'hbed75c89; 
		temp = {temp[9:0],temp[31:10]};
		b = c + temp;
		
		temp = a + `F(b,c,d) + string[415:384]+ 32'h2211906b; 
		temp = {temp[24:0],temp[31:25]};
		a = b + temp;
		
		temp = d + `F(a,b,c) + string[447:416]+ 32'h937198fd; 
		temp = {temp[19:0],temp[31:20]};
		d = a + temp;
		
		temp = c + `F(d,a,b) + string[479:448]+ 32'h8e4379a6; 
		temp = {temp[14:0],temp[31:15]};
		c = d + temp;
		
		temp = b + `F(c,d,a) + string[511:480]+ 32'h2108b449; 
		temp = {temp[9:0],temp[31:10]};
		b = c + temp;
		
		//GG
		
		temp = a + `G(b,c,d) + string[63:32] +  32'h62251ef6; 
		temp = {temp[26:0],temp[31:27]};
		a = b + temp;
		
		temp = d + `G(a,b,c) + string[223:192]+  32'h40b340c0; 
		temp = {temp[22:0],temp[31:23]};
		d = a + temp;
		
		temp = c + `G(d,a,b) + string[479:448]+  32'h515a5e26; 
		temp = {temp[17:0],temp[31:18]};
		c = d + temp;
		
		temp = b + `G(c,d,a) + string[31:0]+ 32'haac7b6e9; 
		temp = {temp[11:0],temp[31:12]};
		b = c + temp;
		
		//
		temp = a + `G(b,c,d) + string[192:160]+ 32'h5d102fd6; 
		temp = {temp[26:0],temp[31:27]};
		a = b + temp;
		
		temp = d + `G(a,b,c) + string[351:320]+ 32'h53144402; 
		temp = {temp[22:0],temp[31:23]};
		d = a + temp;
		
		temp = c + `G(d,a,b) + string[511:480]+ 32'h81e6a1d8; 
		temp = {temp[17:0],temp[31:18]};
		c = d + temp;
		
		temp = b + `G(c,d,a) + string[159:128]+ 32'hc8fbd3e7; 
		temp = {temp[11:0],temp[31:12]};
		b = c + temp;
		
		//
		temp = a + `G(b,c,d) + string[319:288]+ 32'he6cde121; 
		temp = {temp[26:0],temp[31:27]};
		a = b + temp;
		
		temp = d + `G(a,b,c) + string[479:448]+ 32'hd60737c3; 
		temp = {temp[22:0],temp[31:23]};
		d = a + temp;
		
		temp = c + `G(d,a,b) + string[127:96]+ 32'h870dd5f4; 
		temp = {temp[17:0],temp[31:18]};
		c = d + temp;
		
		temp = b + `G(c,d,a) + string[287:256]+ 32'hed145a45; 
		temp = {temp[11:0],temp[31:12]};
		b = c + temp;
		
		//
		temp = a + `G(b,c,d) + string[447:416]+ 32'h05e9e3a9; 
		temp = {temp[26:0],temp[31:27]};
		a = b + temp;
		
		temp = d + `G(a,b,c) + string[95:64]+ 32'hf8a3effc; 
		temp = {temp[22:0],temp[31:23]};
		d = a + temp;
		
		temp = c + `G(d,a,b) + string[255:224]+ 32'hd9026f67; 
		temp = {temp[17:0],temp[31:18]};
		c = d + temp;
		
		temp = b + `G(c,d,a) + string[415:384]+ 32'h8a4c2a8d; 
		temp = {temp[11:0],temp[31:12]};
		b = c + temp;
	end
	
endmodule
