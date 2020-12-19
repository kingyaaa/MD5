module asc2str(
	input clk,
	input vga_clk,
	input en,
	input reset,
	input [7:0]ascii,
	output reg [8:0] str_length,
	output reg [63:0] total_length,
	output reg [7:0]oDATA,
	output reg  Nwren
);
//reg [63:0] total_length;	//总长度
//reg [8:0] str_length;
reg [5:0]number;
reg [127:0]RES;
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
wire a,b,c,d;
reg Finish,Last;
reg crem;
initial
begin
	str_length = 0;
	other = 0;
	Finish=0;
	Last=0;
	//complete = 0;
	A = 32'h01234567;
	B = 32'h89ABCDEF;
	C = 32'hFEDCBA98;
	D = 32'h76543210;
	number=1;
	crem=0;
	calculate=0;
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
	.D(D),
	.a(a),
	.b(b),
	.c(c),
	.d(d)
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
		Finish=0;
		total_length = total_length + 1;
		str_length = str_length + 1;
		string[(str_length*8-1)-:8] = ascii;
		if(str_length == 64)
		begin
			str_length = 0;//重新归0
			calculate = 1;
		end
		else
			calculate = 0;
	end
	
	if(write)begin							//写入字符
		write<=0;
		input_end <= 0;
	end
	
	else if(del)begin						//实现退格键，到达行首再删除时光标回到上一行行尾
		wr_asc<=8'h00;
		del<=0;
		input_end <= 0;
	end
	
	else if(enter)begin					//实现回车键
		write<=0;
		del<=0;
		enter<=0;
		input_end <= 1;
		if((str_length<<3)<9'd448)
		begin
			string[str_length*8]= 1'b1;	//写入0000 0001
			string[511:448]=total_length[63:0];//64Bit
			Finish=1;
		end
		else if((str_length<<3)==9'd448)
		begin
			string[511:448]=total_length[63:0];
			Finish=1;
		end
		else 
		begin
			other=1;
			string[str_length*8]= 1'b1;
		end
		calculate = 1;
		str_length =0;
   end
	else if(other==1)//再补全一组
	begin
		string[447:0]={448{1'b0}};
		string[511:448]=total_length[63:0];
		calculate = 1;
		other=0;
		Finish=1;
		str_length=0;
	end
	if(Finish==1&&other==0&&complete==1)
	begin
		Last=1;
	end
	
	if(complete!=crem)//完成一组的计算
	begin
		calculate =0;
		string[511:0]={512{1'b0}};
		A=A+a;
		B=B+b;
		C=C+c;
		D=D+d;
		crem=~crem;
	end
	RES[127:0]={A[31:0],B[31:0],C[31:0],D[31:0]};

	if(Last)
	begin
		Nwren=1;
		if(number<=16)
		begin
		case(RES[number*4-:4])
		4'h0:oDATA=8'h30;
		4'h1:oDATA=8'h31;
		4'h2:oDATA=8'h32;
		4'h3:oDATA=8'h33;
		4'h4:oDATA=8'h34;
		4'h5:oDATA=8'h35;
		4'h6:oDATA=8'h36;
		4'h7:oDATA=8'h37;
		4'h8:oDATA=8'h38;
		4'h9:oDATA=8'h39;
		4'ha:oDATA=8'h61;
		4'hb:oDATA=8'h62;
		4'hc:oDATA=8'h63;
		4'hd:oDATA=8'h64;
		4'he:oDATA=8'h65;
		4'hf:oDATA=8'h66;
		endcase
		number=number+1;
		end
		else
		begin
			number=0;
			oDATA=8'h0d;
			Last=0;
		end
	end
	else
	begin
		Nwren=0;
	end
end
endmodule
