module md5update(clk,string,input_len,en,complete,A,B,C,D,a,b,c,d,count);
	
	
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
	output reg [31:0] a;
	output reg [31:0] b;
	output reg [31:0] c;
	output reg [31:0] d;
	reg [31:0] temp;
	
	`define F(x,y,z) ((x&y) | ((~x)&z))
	`define G(x,y,z) ((x&z) | (y&(~z)))
	`define H(x,y,z) (x ^ y ^ z)
	`define I(x,y,z) (y ^ (x | (~z)))
	
	//计数器
	output reg [7:0]count;
	
	initial
	begin
		a = 0;
		b = 0;
		c = 0;
		d = 0;
		count = 0;
		complete=0;
	end
	always @ (posedge en)
	begin	
	
		a = A;
		b = B;
		c = C;
		d = D;
		
		//FF:1
		//(b&c) | ((~b)&d)
		//temp = a + `F(b,c,d) + string[31:0]   + 32'hd76aa478;
		//32'hd76aa478
		//temp = a + ((b&c) | ((~b)&d)) + string[511:480] + 32'hd76aa478;
		//temp = {temp[24:0],temp[31:25]};
		//a = b + temp;
		//a = b + ((a+((b&c)|((~b)&d))+string[31:0]+32'h7da6_4a87)<< 7  |  (a+((b&c)|((~b)&d))+string[31:0]+32'h7da6_4a87)>>(32- 7) ); 
		//a = b + ((a+((b&c)|((~b)&d))+string[ 0]+32'hd76a_a478)<< 7  |  (a+((b&c)|((~b)&d))+mes_part[ 0]+32'hd76a_a478)>>(32- 7) );
		
		temp = d + `F(a,b,c) + string[63:32]  + 32'he8c7b756;//e8c7b756
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
		
		temp = a + `G(b,c,d) + string[63:32] +  	32'hf61e2562; 
		temp = {temp[26:0],temp[31:27]};
		a = b + temp;
		
		temp = d + `G(a,b,c) + string[223:192]+	32'hc040b340; 
		temp = {temp[22:0],temp[31:23]};
		d = a + temp;
		
		temp = c + `G(d,a,b) + string[479:448]+  	32'h265e5a51; 
		temp = {temp[17:0],temp[31:18]};
		c = d + temp;
		
		temp = b + `G(c,d,a) + string[31:0]+ 		32'he9b6c7aa; 
		temp = {temp[11:0],temp[31:12]};
		b = c + temp;
		
		//
		temp = a + `G(b,c,d) + string[192:160]+ 	32'hd62f105d; 
		temp = {temp[26:0],temp[31:27]};
		a = b + temp;
		
		temp = d + `G(a,b,c) + string[351:320]+ 	32'h2441453; 
		temp = {temp[22:0],temp[31:23]};
		d = a + temp;
		
		temp = c + `G(d,a,b) + string[511:480]+ 	32'hd8a1e681; 
		temp = {temp[17:0],temp[31:18]};
		c = d + temp;
		
		temp = b + `G(c,d,a) + string[159:128]+ 	32'he7d3fbc8; 
		temp = {temp[11:0],temp[31:12]};
		b = c + temp;
		
		//
		temp = a + `G(b,c,d) + string[319:288]+ 	32'h21e1cde6; 
		temp = {temp[26:0],temp[31:27]};
		a = b + temp;
		
		temp = d + `G(a,b,c) + string[479:448]+ 	32'hc33707d6; 
		temp = {temp[22:0],temp[31:23]};
		d = a + temp;
		
		temp = c + `G(d,a,b) + string[127:96]+ 	32'hf4d50d87; 
		temp = {temp[17:0],temp[31:18]};
		c = d + temp;
		
		temp = b + `G(c,d,a) + string[287:256]+ 	32'h455a14ed; 
		temp = {temp[11:0],temp[31:12]};
		b = c + temp;
		
		//
		temp = a + `G(b,c,d) + string[447:416]+ 	32'ha9e3e905; 
		temp = {temp[26:0],temp[31:27]};
		a = b + temp;
		
		temp = d + `G(a,b,c) + string[95:64]+ 		32'hfcefa3f8; 
		temp = {temp[22:0],temp[31:23]};
		d = a + temp;
		
		temp = c + `G(d,a,b) + string[255:224]+ 	32'h676f02d9; 
		temp = {temp[17:0],temp[31:18]};
		c = d + temp;
		
		temp = b + `G(c,d,a) + string[415:384]+ 	32'h8d2a4c8a; 
		temp = {temp[11:0],temp[31:12]};
		b = c + temp;
		
		//HH	
		
		temp= a + `H(b,c,d) + string[191:160] +32'h4239faff;
		temp={temp[27:0],temp[31:28]};
		a=b+temp;
	
		temp = d + `H(a,b,c) + string[287:256]+ 32'h81f67187; 
		temp = {temp[20:0],temp[31:21]};
		d = a  + temp;
	
		temp = c + `H(d,a,b) + string[383:352]+ 32'h22619d6d; 
		temp = {temp[15:0],temp[31:16]};
		c = d + temp;
	
		temp = b + `H(c,d,a) + string[479:448]+ 32'h0c38e5fd; 
		temp = {temp[8:0],temp[31:9]};
		b = c + temp;
		//
		temp= a + `H(b,c,d) + string[63:32] +32'h44eabea4;
		temp={temp[27:0],temp[31:28]};
		a=b+temp;

		temp = d + `H(a,b,c) + string[159:128]+ 32'ha9cfde4b; 
		temp = {temp[20:0],temp[31:21]};
		d = a  + temp;
		
		temp = c + `H(d,a,b) + string[255:224]+ 32'h604bbbf6; 
		temp = {temp[15:0],temp[31:16]};
		c = d + temp;
		
		temp = b + `H(c,d,a) + string[351:320]+ 32'h70bcbfbe; 
		temp = {temp[8:0],temp[31:9]};
		b = c + temp;
		//
		temp= a + `H(b,c,d) + string[447:416] +32'hc67e9b28;
		temp={temp[27:0],temp[31:28]};
		a=b+temp;

		temp = d + `H(a,b,c) + string[31:0]+ 32'hfa27a1ea; 
		temp = {temp[20:0],temp[31:21]};
		d = a  + temp;
		
		temp = c + `H(d,a,b) + string[127:96]+ 32'h8530efd4; 
		temp = {temp[15:0],temp[31:16]};
		c = d + temp;
		
		temp = b + `H(c,d,a) + string[223:192]+ 32'h051d8804; 
		temp = {temp[8:0],temp[31:9]};
		b = c + temp;
		//
		temp= a + `H(b,c,d) + string[319:288] +32'h39d0d4d9;
		temp={temp[27:0],temp[31:28]};
		a=b+temp;

		temp = d + `H(a,b,c) + string[415:384]+ 32'he599dbe6; 
		temp = {temp[20:0],temp[31:21]};
		d = a  + temp;
		
		temp = c + `H(d,a,b) + string[511:480]+ 32'hf87ca21f; 
		temp = {temp[15:0],temp[31:16]};
		c = d + temp;
		
		temp = b + `H(c,d,a) + string[95:64]+ 32'h6556acc4; 
		temp = {temp[8:0],temp[31:9]};
		b = c + temp;
		/////////

		
		
		
		temp= a + `I(b,c,d) + string[31:0] +32'h442229f4;
		temp={temp[25:0],temp[31:26]};
		a=b+temp;

		temp = d + `I(a,b,c) + string[255:224]+ 32'h97ff2a43; 
		temp = {temp[21:0],temp[31:22]};
		d = a  + temp;
		
		temp = c + `I(d,a,b) + string[479:448]+ 32'ha72394ab; 
		temp = {temp[16:0],temp[31:17]};
		c = d + temp;
		
		temp = b + `I(c,d,a) + string[191:160]+ 32'h39a093fc; 
		temp = {temp[10:0],temp[31:11]};
		b = c + temp;
		//
		temp= a + `I(b,c,d) + string[415:384] +32'hc3595b65;
		temp={temp[25:0],temp[31:26]};
		a=b+temp;

		temp = d + `I(a,b,c) + string[127:96]+ 32'h92cc0c8f; 
		temp = {temp[21:0],temp[31:22]};
		d = a  + temp;
		
		temp = c + `I(d,a,b) + string[351:320]+ 32'h7df4efff; 
		temp = {temp[16:0],temp[31:17]};
		c = d + temp;
		
		temp = b + `I(c,d,a) + string[63:32]+ 32'hd15d8485; 
		temp = {temp[10:0],temp[31:11]};
		b = c + temp;
		//
		temp= a + `I(b,c,d) + string[287:256] +32'h4f7ea86f;
		temp={temp[25:0],temp[31:26]};
		a=b+temp;

		temp = d + `I(a,b,c) + string[511:480]+ 32'he0e62cfe; 
		temp = {temp[21:0],temp[31:22]};
		d = a  + temp;
		
		temp = c + `I(d,a,b) + string[223:192]+ 32'h144301a3; 
		temp = {temp[16:0],temp[31:17]};
		c = d + temp;
		
		temp = b + `I(c,d,a) + string[447:416]+ 32'ha111084e; 
		temp = {temp[10:0],temp[31:11]};
		b = c + temp;
		//
		temp= a + `I(b,c,d) + string[159:128] +32'h827e53f7;
		temp={temp[25:0],temp[31:26]};
		a=b+temp;

		temp = d + `I(a,b,c) + string[383:352]+ 32'h35f23abd; 
		temp = {temp[21:0],temp[31:22]};
		d = a  + temp;
		
		temp = c + `I(d,a,b) + string[95:64]+ 32'hbbd2d72a; 
		temp = {temp[16:0],temp[31:17]};
		c = d + temp;
		
		temp = b + `I(c,d,a) + string[319:288]+ 32'h91d386eb; 
		temp = {temp[10:0],temp[31:11]};
		b = c + temp;
		
		count = count + 1;
		complete=~complete;
	end
	
endmodule
