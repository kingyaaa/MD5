module md5update(clk,string,input_len,en);
	input clk;
	input [8:0] input_len;//64bit的数，表示信息的字节数
	input [511:0]string;//字节 * 8bit
	input en;
	reg [511:0]update_str;//字节 * 8bit
	reg [8:0]update_str_length;//字节数
	//reg [57:0] div_group;	//切割，每组512bit 
	reg [9:0] remain_byte;	//余下的bit数，需要进行相应的填充
	reg [5:0] padding;//填充的字符？
	reg [4:0] A;
	reg [4:0] B;
	reg [4:0] C;
	reg [4:0] D;
	reg [4:0] a;
	reg [4:0] b;
	reg [4:0] c;
	reg [4:0] d;
	always @ (posedge en)
	begin
		remain_byte = (input_len << 3) % 512;
		if(remain_byte == 9'd448)//补充512个bit和64bit
		begin
			update_str = {string,{8'h01}};
		end
		//if(remain_byte < 9'd448)//补充到448个bit，再加64个字节
		//begin
		//	update_str = {string,8'd1,(447-remain_byte){1'd0},input_len};
		//end
		//if(remain_byte > 9'd448)//补充 960-remain_byte 个bit，再加64个字节
		//begin
		//	update_str = {string,8'd1,(959-remain_byte){1'd0},input_len};
		//end
	end
	
endmodule
