module asc2str(
	input clk,
	input vga_clk,
	input en,
	input reset,
	input [7:0]ascii,
	output reg [8:0] str_length,
	output reg [63:0] total_length
);
//reg [63:0] total_length;	//总长度
//reg [8:0] str_length;
reg input_end;
reg [511:0] string;		//半个屏幕的长度，1000个char | byte * 8
reg wren;					//显存及ntp的写使能信号
reg kbdclk;					//键盘时钟
reg del,enter,write;  	//删除键标志位、回车键标志位及写入标志位
reg [6:0]  count_clk;	
reg [11:0] waddr;			//写入显存时的写入地址，同时也是光标所在位置，低五位记录行坐标，高七位记录列坐标
reg [7:0]  wr_asc;		//写入显存的	ascii码数据
reg calculate,other;
wire complete;
reg [31:0]A;
reg [31:0]B;
reg [31:0]C;
reg [31:0]D;

initial
begin
	str_length = 0;
	other = 0;
	//complete = 0;
end

md5update Update(
	.clk(kbdclk),
	.string(string),
	.en(calculate),
	.input_len(str_length),
	.complete(complete),
	.A(A),
	.B(B),
	.C(C),
	.D(D)
);


always @ (posedge clk) begin		//键盘时钟
	if(count_clk == 100) begin
		kbdclk <= ~kbdclk;
		count_clk <= 7'd0;
	end
	else
		count_clk <= count_clk + 7'd1;
end

always @ (posedge kbdclk) begin			
	if(en && ascii != 8'h00) begin			//根据kbd模块传入的显存写使能信号进行处理
		if(ascii == 8'h08) begin			//退格键
			del <= 1;
			write <= 0;
			enter <= 0;
		end
		else if(ascii == 8'h0d)begin		//回车键
			write <= 0;
			del <= 0;
			wren <= 0;
			enter <= 1;
		end
		else begin							//写入字符
			wren <= 1;
			write <= 1;
			del <= 0;
			enter <= 0;
			wr_asc <= ascii;
		end
	end

	else
		wren <= 0;
   
	if(write)begin
		total_length = total_length + 1;
		str_length = str_length + 1;
		string[(str_length*8-1)-:8] = ascii;
		if(str_length == 64)
		begin
			str_length = 0;//重新归0
			calculate = 1;
		end
	end
	
	if(write)begin							//写入字符
		/*
		if(waddr[11:5]==7'd69)begin
			waddr[11:5]<=7'd0;
			if(waddr[4:0]==5'd29)
				waddr[4:0]<=5'd0;
			else waddr[4:0]<=waddr[4:0]+5'd1;
      end
		
		else 
			waddr[11:5]<=waddr[11:5]+7'd1;
		wren<=0;
		*/
		write<=0;
		input_end <= 0;
	end
	
	else if(del)begin						//实现退格键，到达行首再删除时光标回到上一行行尾
		/*
		if(waddr[11:5]==7'd0)begin
			waddr[11:5]<=last_end;
			if(waddr[4:0]!=5'd0)
				waddr[4:0]<=waddr[4:0]-5'd1;
		end
		
		else 
			waddr[11:5]<=waddr[11:5]-7'd1;
		
		wren<=1;
		*/
		wr_asc<=8'h00;
		del<=0;
		input_end <= 0;
	end
	
	else if(enter)begin					//实现回车键
		/*
		waddr[11:5]<=7'd0;
		waddr[4:0]<=waddr[4:0]+5'd1;
		wren<=0;
		*/
		write<=0;
		del<=0;
		enter<=0;
		input_end <= 1;
		if((str_length<<3)<9'd448)
		begin
			string[str_length*8]= 1'b1;	//写入0000 0001
			string[511:448]=total_length[63:0];//64Bit
		end
		else if((str_length<<3)==9'd448)
			string[511:448]=total_length[63:0];
		else 
		begin
			other=1;
			string[str_length*8]= 1'b1;
		end
		calculate = 1;
		str_length =0;
		
		//todo:填充
		//if(str_length << 3 == 9'd448)//补充448bit和64bit
		//begin
		//	string <= {string,{1'b1,511{1'b0}},};
		//end
		//if(remain_byte < 9'd448)//补充到448个bit，再加64个字节
		//begin
		//	update_str = {string,8'd1,(447-remain_byte){1'd0},input_len};
		//end
		//if(remain_byte > 9'd448)//补充 960-remain_byte 个bit，再加64个字节
		//begin
		//	update_str = {string,8'd1,(959-remain_byte){1'd0},input_len};
		//end
		
   end
	else if(other==1)//再补全一组
	begin
		string[447:0]={448{1'b0}};
		string[511:448]=total_length[63:0];
		calculate = 1;
		other=0;
		str_length=0;
	end
	
	if(calculate == 1)
	begin
		A = 32'h01234567;
		B = 32'h89ABCDEF;
		C = 32'hFEDCBA98;
		D = 32'h76543210;
	end
	
	if(complete==1)//完成一组的计算
	begin
		calculate =0;
		string[511:0]={512{1'b0}};
	end
	
end
endmodule
