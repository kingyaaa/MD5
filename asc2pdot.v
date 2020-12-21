module asc2pdot(
	input clk,
	input vga_clk,
	input en,
	input reset,
	input blank_n,
	input [7:0]ascii,
	input [9:0]v_addr,
	output reg[23:0]vga_data,
	output reg [31:0] A
);
	
reg wren;					//显存及ntp的写使能信号
reg kbdclk;					//键盘时钟
reg del,enter,write;  	//删除键标志位、回车键标志位及写入标志位
reg [6:0]  count_clk;	
reg [11:0] waddr;			//写入显存时的写入地址，同时也是光标所在位置，低五位记录行坐标，高七位记录列坐标
reg [7:0]  wr_asc;		//写入显存的	ascii码数据
reg [3:0]  count_v;		//块内列计数变量
reg [6:0]  count_h;		//行计数变量
reg Nwren;
reg [7:0]oDATA;
wire gb;						//光标时钟，频率为2hz，直接以其作为光标是否显示的标志位
wire [6:0]  last_end;	//上一行的末尾所在位置
wire [7:0]  pascii;		//vga模块扫描到的位置在显存中所存的ascii码
wire [11:0] raddr;		//vga扫描到的像素点所在位置
wire [11:0] paddr;		//到a2p查找表中查找点行的地址，由pascii及列坐标的低四位组合而成
wire [11:0] pdot;			//点行信息

a2p mypdot(
	.address(paddr),
	.clock(clk),
	.q(pdot)
);

vm ASC_RAM( 
	.data(wr_asc),
	.rdaddress(raddr),
	.rdclock(vga_clk),
	.wraddress(waddr),
	.wrclock(kbdclk),
	.wren(wren),
	.q(pascii)
);	

ntp myntp( 
	.clock(kbdclk),
	.data(waddr[11:5]),
	.rdaddress(waddr[4:0]-1),	//读取地址永远为光标所在行的上一行
	.wraddress(waddr[4:0]),		//写入地址永远为光标所在行
	.wren(1'b1),					//在每个时钟都记录当前光标所在位置信息
	.q(last_end)
);

clkgen #(2) guangbiao_clk (	//光标时钟
	.clkin(clk),
	.rst(reset),
	.clken(1'b1),
	.clkout(gb)
);

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
///
reg calculate,other;
wire complete;
//reg [31:0]A;
reg [31:0]B;
reg [31:0]C;
reg [31:0]D;
wire[31:0]a;
wire[31:0]b;
wire[31:0]c;
wire[31:0]d;
reg Finish,Last;
reg [5:0]number;
reg [127:0]RES;
reg input_end;
reg [511:0] string;	
reg crem;
reg [63:0] total_length;	//总长度
reg [8:0] str_length;
initial
begin
	str_length = 0;
	other = 0;
	Finish=0;
	Last=0;
	//complete = 0;
	A = 32'h67452301;
	B = 32'hefcdab89;
	C = 32'h98badcfe;
	D = 32'h10325476;
	number=1;
	crem=0;
	calculate=0;
end
/////
always @(posedge clk)begin		//键盘时钟
	if(count_clk==100)begin
		kbdclk<=~kbdclk;
		count_clk<=7'd0;
	end
	else
		count_clk<=count_clk+7'd1;
end

assign paddr={pascii,v_addr[3:0]};		//pascii及vga模块传入的行坐标v_addr的低四位决定a2p查找地址paddr

assign raddr={count_h,v_addr[8:4]};		//行计数变量及v_addr高五位决定显存读取地址raddr

always @(posedge vga_clk)begin			//根据vga时钟及vga消隐信号确定输出并进行计数
	if(blank_n)begin
		if(raddr==waddr)
			vga_data<={24{gb}};
		else 
			vga_data<={24{pdot[count_v]}};
			
		if(count_v==4'd8)begin
			count_v<=4'd0;
			if(count_h==7'd71)
				count_h<=7'b0;
			else
			count_h<=count_h+7'b1;
		end
		else
			count_v<=count_v+4'b1;
      end
		
	else begin
		count_v<=4'b0;
		count_h<=4'b0;
	end
end


always @(posedge kbdclk)begin		
	
	if(en&&ascii!=8'h00)begin			//根据kbd模块传入的显存写使能信号进行处理
		if(ascii==8'h08)begin			//退格键
			del<=1;
			write<=0;
			enter<=0;
		end
		else if(ascii==8'h0d)begin		//回车键
			write<=0;
			del<=0;
			wren<=0;
			enter<=1;
		end
		else begin							//写入字符
			wren<=1;
			write<=1;
			del<=0;
			enter<=0;
			wr_asc<=ascii;
		end
	end
	else if(!en&&Nwren)
	begin
		wren<=1;
		write<=1;
		del<=0;
		enter<=0;
		wr_asc<=oDATA;
	end
	else
		wren<=0;
   
	if(write)begin							//写入字符
	//jisuan
		Finish<=0;
		total_length <= total_length + 1;
		str_length <= str_length + 1;
		string[(str_length*8+7)-:8] <= ascii;
		if(str_length == 63)
		begin
			str_length <= 0;//重新归0
			calculate <= 1;
		end
		else
			calculate <= 0;
	//yuanlai		
			
		if(waddr[11:5]==7'd69)begin
			waddr[11:5]<=7'd0;
			if(waddr[4:0]==5'd29)
				waddr[4:0]<=5'd0;
			else waddr[4:0]<=waddr[4:0]+5'd1;
      end
		
		else 
			waddr[11:5]<=waddr[11:5]+7'd1;
		wren<=0;
		write<=0;
	end
	
	else if(del)begin						//实现退格键，到达行首再删除时光标回到上一行行尾
		if(waddr[11:5]==7'd0)begin
			waddr[11:5]<=last_end;
			if(waddr[4:0]!=5'd0)
				waddr[4:0]<=waddr[4:0]-5'd1;
		end
		
		else 
			waddr[11:5]<=waddr[11:5]-7'd1;
		
		wren<=1;
		wr_asc<=8'h00;
		del<=0;
	end
	
	else if(enter)begin					//实现回车键
	//jisuan
		if(((str_length+1)<<3)<9'd448)
		begin
			string[str_length*8+7]<= 1'b1;	//写入0000 0001
			string[511:448]<=total_length[63:0];//64Bit
			Finish<=1;
		end
		else if(((str_length+1)<<3)==9'd448)
		begin
			string[511:448]<=total_length[63:0];
			Finish<=1;
		end
		else 
		begin
			other<=1;
			string[str_length*8+7]<= 1'b1;
		end
		calculate <= 1;
		str_length <=0;
		//yuanlai
		waddr[11:5]<=7'd0;
		waddr[4:0]<=waddr[4:0]+5'd1;
		write<=0;
		del<=0;
		wren<=0;
		enter<=0;
    end
	 else if(other==1)//再补全一组
		begin
		string[447:0]<={448{1'b0}};
		string[511:448]<=total_length[63:0];
		calculate <= 1;
		other<=0;
		Finish<=1;
		str_length<=0;
	end
	if(Finish==1&&other==0&&complete==1)
	begin
		Last<=1;
	end
	if(complete!=crem)//完成一组的计算
	begin
		calculate <=0;
		string[511:0]<={512{1'b0}};
		A<=A+a;
		B<=B+b;
		C<=C+c;
		D<=D+d;
		crem<=~crem;
	end
	RES[127:0]<={A[31:0],B[31:0],C[31:0],D[31:0]};
	if(Last)
	begin
		Nwren<=1;
		if(number<=8)
		begin
		case(A[(number*4-1)-:4])
		4'h0:oDATA<=8'h30;
		4'h1:oDATA<=8'h31;
		4'h2:oDATA<=8'h32;
		4'h3:oDATA<=8'h33;
		4'h4:oDATA<=8'h34;
		4'h5:oDATA<=8'h35;
		4'h6:oDATA<=8'h36;
		4'h7:oDATA<=8'h37;
		4'h8:oDATA<=8'h38;
		4'h9:oDATA<=8'h39;
		4'ha:oDATA<=8'h61;
		4'hb:oDATA<=8'h62; 
		4'hc:oDATA<=8'h63;
		4'hd:oDATA<=8'h64;
		4'he:oDATA<=8'h65;
		4'hf:oDATA<=8'h66;
		endcase
		number<=number+1;
		end
		else
		begin
			number<=1;
			//enter<=1;
			Last<=0;
			Finish<=0;
			total_length<=0;
			string[511:0]<={512{1'b0}};
			str_length<=0;
			Nwren <= 0;
		end
	end
	else
	begin
		Nwren<=0;
	end
end
	

endmodule
