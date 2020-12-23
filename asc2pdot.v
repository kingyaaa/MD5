module asc2pdot(
	input clk,
	input vga_clk,
	input en,
	input reset,
	input blank_n,
	input [7:0]ascii,
	input [9:0]v_addr,
	output reg[23:0]vga_data,
	output reg [63:0] total_length
	//output reg [7:0] count_wren
	);
reg [7:0] count_wren;	
reg wren;					//显存及ntp的写使能信号
reg kbdclk;					//键盘时钟
reg enter,write;  	//删除键标志位、回车键标志位及写入标志位
reg [10:0]  count_clk;	
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

///
reg calculate,other;
reg [31:0]A;
reg [31:0]B;
reg [31:0]C;
reg [31:0]D;
reg[31:0]a;
reg[31:0]b;
reg[31:0]c;
reg[31:0]d;
reg Finish,Last;
reg [5:0]number;
reg [127:0]RES;
reg input_end;
reg [511:0] string;	
//reg [63:0] total_length;	//总长度
reg [8:0] str_length;
reg [31:0] temp;
	
	`define F(x,y,z) ((x&y) | ((~x)&z))
	`define G(x,y,z) ((x&z) | (y&(~z)))
	`define H(x,y,z) (x ^ y ^ z)
	`define I(x,y,z) (y ^ (x | (~z)))
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
	calculate=0;
	count_wren = 0;
end
/////
always @(posedge clk)begin		//键盘时钟
	if(count_clk==1000)begin
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
			write<=0;
			enter<=0;
		end
		else if(ascii==8'h0d)begin		//回车键
			write<=0;
			wren<=0;
			enter<=1;
		end
		else begin							//写入字符
			wren<=1;
			write<=1;
			enter<=0;
			wr_asc<=ascii;
		end
	end
	else if(!en&&Nwren)	//写入显存的输出结果
	begin
		wren<=1;
		write<=1;
		enter<=0;
		wr_asc<=oDATA;
	end
	else
		wren<=0;
   
	if(write)begin							//写入字符
	//jisuan  
		if(!Nwren)
		begin
			count_wren = count_wren + 1;
			Finish=0;
			total_length = total_length + 8;
		//1
			str_length = str_length + 1;
			string[(str_length*8-1)-:8] = wr_asc;
			if(str_length == 64)
			begin
			str_length = 0;//重新归0
			calculate = 1;
			end
			else
			calculate = 0;
		end
	//yuanlai		
			
		if(waddr[11:5]==7'd69)begin
			waddr[11:5]<=7'd0;
			if(waddr[4:0]==5'd29)
				waddr[4:0]<=5'd0;
			else waddr[4:0]<=waddr[4:0]+5'd1;
      end
		
		else 
			waddr[11:5]<=waddr[11:5]+7'd1;
		
		if(en == 1 || Last == 0)
		begin
			write<=0;
			wren<=0;
		end
	end
	
	
	else if(enter)begin					//实现回车键
	//jisuan
		if(((str_length)<<3)<9'd448)
		begin
			string[(str_length*8+7)-:8]= 8'h80;	//写入1000 0000
			string[511:448]=total_length[63:0];//64Bit
			Finish=1;
		end
		else if(((str_length)<<3)==9'd448)
		begin
			string[511:448]=total_length[63:0];
			Finish=1;
		end
		else 
		begin
			other=1;
			string[(str_length*8+7)-:8]= 8'h80;
		end
		calculate = 1;
		str_length =0;
		//yua	
		waddr[11:5]<=7'd0;
		waddr[4:0]<=waddr[4:0]+5'd1;
		write<=0;
		wren<=0;
		enter<=0;
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
	
	
	//计算
	if(calculate==1)
	begin
		a = A;
		b = B;
		c = C;
		d = D;
		////todo
		
		temp = a + `F(b,c,d) + string[31:0]   + 32'hd76aa478;
		temp = {temp[24:0],temp[31:25]};
		a = b + temp;

		temp = d + `F(a,b,c) + string[63:32]  + 32'he8c7b756;//e8c7b756
		temp = {temp[19:0],temp[31:20]};
		d = a + temp;
		
		temp = c + `F(d,a,b) + string[95:64]  + 32'h242070db;
		temp = {temp[14:0],temp[31:15]};
		c = d + temp;
		 
		temp = b + `F(c,d,a) + string[127:96] + 32'hc1bdceee; 
		temp = {temp[9:0],temp[31:10]};
		b = c + temp;
		
		
		temp = a + `F(b,c,d) + string[159:128]+ 32'hf57c0faf; 
		temp = {temp[24:0],temp[31:25]};
		a = b + temp;
		
		temp = d + `F(a,b,c) + string[191:160]+ 32'h4787c62a; 
		temp = {temp[19:0],temp[31:20]};
		d = a + temp;
		
		temp = c + `F(d,a,b) + string[223:192]+ 32'ha8304613; 
		temp = {temp[14:0],temp[31:15]};
		c = d + temp;
		
		temp = b + `F(c,d,a) + string[255:224]+ 32'hfd469501; 
		temp = {temp[9:0],temp[31:10]};
		b = c + temp;
		
		temp = a + `F(b,c,d) + string[287:256]+ 32'h698098d8; 
		temp = {temp[24:0],temp[31:25]};
		a = b + temp;
		
		temp = d + `F(a,b,c) + string[319:288]+ 32'h8b44f7af; 
		temp = {temp[19:0],temp[31:20]};
		d = a + temp;
		
		temp = c + `F(d,a,b) + string[351:320]+ 32'hffff5bb1; 
		temp = {temp[14:0],temp[31:15]};
		c = d + temp;
		
		temp = b + `F(c,d,a) + string[383:352]+ 32'h895cd7be; 
		temp = {temp[9:0],temp[31:10]};
		b = c + temp;
		
		temp = a + `F(b,c,d) + string[415:384]+ 32'h6b901122; 
		temp = {temp[24:0],temp[31:25]};
		a = b + temp;
		
		temp = d + `F(a,b,c) + string[447:416]+ 32'hfd987193; 
		temp = {temp[19:0],temp[31:20]};
		d = a + temp;
		
		temp = c + `F(d,a,b) + string[479:448]+ 32'ha679438e; 
		temp = {temp[14:0],temp[31:15]};
		c = d + temp;
		
		temp = b + `F(c,d,a) + string[511:480]+ 32'h49b40821; 
		temp = {temp[9:0],temp[31:10]};
		b = c + temp;
		
		//GG
		
		temp = a + `G(b,c,d) + string[63:32] +  32'hf61e2562; 
		temp = {temp[26:0],temp[31:27]};
		a = b + temp;
		
		temp = d + `G(a,b,c) + string[223:192]+ 32'hc040b340; 
		temp = {temp[22:0],temp[31:23]};
		d = a + temp;
		
		temp = c + `G(d,a,b) + string[383:352]+ 32'h265e5a51; 
		temp = {temp[17:0],temp[31:18]};
		c = d + temp;
		
		temp = b + `G(c,d,a) + string[31:0]+ 	 32'he9b6c7aa; 
		temp = {temp[11:0],temp[31:12]};
		b = c + temp;
		
		//
		temp = a + `G(b,c,d) + string[191:160]+ 32'hd62f105d; 
		temp = {temp[26:0],temp[31:27]};
		a = b + temp;
		
		temp = d + `G(a,b,c) + string[351:320]+ 32'h2441453; 
		temp = {temp[22:0],temp[31:23]};
		d = a + temp;
		
		temp = c + `G(d,a,b) + string[511:480]+ 32'hd8a1e681; 
		temp = {temp[17:0],temp[31:18]};
		c = d + temp;
		
		temp = b + `G(c,d,a) + string[159:128]+ 32'he7d3fbc8; 
		temp = {temp[11:0],temp[31:12]};
		b = c + temp;
		
		//
		temp = a + `G(b,c,d) + string[319:288]+ 32'h21e1cde6; 
		temp = {temp[26:0],temp[31:27]};
		a = b + temp;
		
		temp = d + `G(a,b,c) + string[479:448]+ 32'hc33707d6; 
		temp = {temp[22:0],temp[31:23]};
		d = a + temp;
		
		temp = c + `G(d,a,b) + string[127:96]+  32'hf4d50d87; 
		temp = {temp[17:0],temp[31:18]};
		c = d + temp;
		
		temp = b + `G(c,d,a) + string[287:256]+ 32'h455a14ed; 
		temp = {temp[11:0],temp[31:12]};
		b = c + temp;
		
		//
		temp = a + `G(b,c,d) + string[447:416]+ 32'ha9e3e905; 
		temp = {temp[26:0],temp[31:27]};
		a = b + temp;
		
		temp = d + `G(a,b,c) + string[95:64]+ 	 32'hfcefa3f8; 
		temp = {temp[22:0],temp[31:23]};
		d = a + temp;
		
		temp = c + `G(d,a,b) + string[255:224]+ 32'h676f02d9; 
		temp = {temp[17:0],temp[31:18]};
		c = d + temp;
		
		temp = b + `G(c,d,a) + string[415:384]+ 32'h8d2a4c8a; 
		temp = {temp[11:0],temp[31:12]};
		b = c + temp;
		
		//HH	
		
		temp= a + `H(b,c,d) + string[191:160] + 32'hfffa3942;
		temp={temp[27:0],temp[31:28]};
		a=b+temp;
	
		temp = d + `H(a,b,c) + string[287:256]+ 32'h8771f681; 
		temp = {temp[20:0],temp[31:21]};
		d = a  + temp;
	
		temp = c + `H(d,a,b) + string[383:352]+ 32'h6d9d6122; 
		temp = {temp[15:0],temp[31:16]};
		c = d + temp;
	
		temp = b + `H(c,d,a) + string[479:448]+ 32'hfde5380c; 
		temp = {temp[8:0],temp[31:9]};
		b = c + temp;
		//
		temp= a + `H(b,c,d) + string[63:32] +   32'ha4beea44;
		temp={temp[27:0],temp[31:28]};
		a=b+temp;

		temp = d + `H(a,b,c) + string[159:128]+ 32'h4bdecfa9; 
		temp = {temp[20:0],temp[31:21]};
		d = a  + temp;
		
		temp = c + `H(d,a,b) + string[255:224]+ 32'hf6bb4b60; 
		temp = {temp[15:0],temp[31:16]};
		c = d + temp;
		
		temp = b + `H(c,d,a) + string[351:320]+ 32'hbebfbc70; 
		temp = {temp[8:0],temp[31:9]};
		b = c + temp;
		//
		temp= a + `H(b,c,d) + string[447:416] + 32'h289b7ec6;
		temp={temp[27:0],temp[31:28]};
		a=b+temp;

		temp = d + `H(a,b,c) + string[31:0]+    32'heaa127fa; 
		temp = {temp[20:0],temp[31:21]};
		d = a  + temp;
		
		temp = c + `H(d,a,b) + string[127:96]+  32'hd4ef3085; 
		temp = {temp[15:0],temp[31:16]};
		c = d + temp;
		
		temp = b + `H(c,d,a) + string[223:192]+ 32'h4881d05; 
		temp = {temp[8:0],temp[31:9]};
		b = c + temp;
		//
		temp= a + `H(b,c,d) + string[319:288] + 32'hd9d4d039;
		temp={temp[27:0],temp[31:28]};
		a=b+temp;

		temp = d + `H(a,b,c) + string[415:384]+ 32'he6db99e5; 
		temp = {temp[20:0],temp[31:21]};
		d = a  + temp;
		
		temp = c + `H(d,a,b) + string[511:480]+ 32'h1fa27cf8; 
		temp = {temp[15:0],temp[31:16]};
		c = d + temp;
		
		temp = b + `H(c,d,a) + string[95:64]+   32'hc4ac5665; 
		temp = {temp[8:0],temp[31:9]};
		b = c + temp;
		/////////

		
		
		
		temp= a + `I(b,c,d) + string[31:0] +    32'hf4292244;
		temp={temp[25:0],temp[31:26]};
		a=b+temp;

		temp = d + `I(a,b,c) + string[255:224]+ 32'h432aff97; 
		temp = {temp[21:0],temp[31:22]};
		d = a  + temp;
		
		temp = c + `I(d,a,b) + string[479:448]+ 32'hab9423a7; 
		temp = {temp[16:0],temp[31:17]};
		c = d + temp;
		
		temp = b + `I(c,d,a) + string[191:160]+ 32'hfc93a039; 
		temp = {temp[10:0],temp[31:11]};
		b = c + temp;
		//
		temp= a + `I(b,c,d) + string[415:384] + 32'h655b59c3;
		temp={temp[25:0],temp[31:26]};
		a=b+temp;

		temp = d + `I(a,b,c) + string[127:96]+  32'h8f0ccc92; 
		temp = {temp[21:0],temp[31:22]};
		d = a  + temp;
		
		temp = c + `I(d,a,b) + string[351:320]+ 32'hffeff47d;
		temp = {temp[16:0],temp[31:17]};
		c = d + temp;
		
		temp = b + `I(c,d,a) + string[63:32]+   32'h85845dd1; 
		temp = {temp[10:0],temp[31:11]};
		b = c + temp;
		//
		temp= a + `I(b,c,d) + string[287:256] + 32'h6fa87e4f;
		temp={temp[25:0],temp[31:26]};
		a=b+temp;

		temp = d + `I(a,b,c) + string[511:480]+ 32'hfe2ce6e0; 
		temp = {temp[21:0],temp[31:22]};
		d = a  + temp;
		
		temp = c + `I(d,a,b) + string[223:192]+ 32'ha3014314; 
		temp = {temp[16:0],temp[31:17]};
		c = d + temp;
		
		temp = b + `I(c,d,a) + string[447:416]+ 32'h4e0811a1; 
		temp = {temp[10:0],temp[31:11]};
		b = c + temp;
		//
		temp= a + `I(b,c,d) + string[159:128] + 32'hf7537e82;
		temp={temp[25:0],temp[31:26]};
		a=b+temp;

		temp = d + `I(a,b,c) + string[383:352]+ 32'hbd3af235; 
		temp = {temp[21:0],temp[31:22]};
		d = a  + temp;
		
		temp = c + `I(d,a,b) + string[95:64]+ 	 32'h2ad7d2bb; 
		temp = {temp[16:0],temp[31:17]};
		c = d + temp;
		
		temp = b + `I(c,d,a) + string[319:288]+ 32'heb86d391; 
		temp = {temp[10:0],temp[31:11]};
		b = c + temp;
		
		////
		calculate =0;
		string[511:0]={512{1'b0}};
		A=A+a;
		B=B+b;
		C=C+c;
		D=D+d;
	end
	
	
	if(Finish==1&&other==0&&calculate==0)
	begin
		Last=1;
	end
	
	RES[127:0]={D[27:24],D[31:28],D[19:16],D[23:20],D[11:8],D[15:12],D[3:0],D[7:4],C[27:24],C[31:28],C[19:16],C[23:20],C[11:8],C[15:12],C[3:0],C[7:4],B[27:24],B[31:28],B[19:16],B[23:20],B[11:8],B[15:12],B[3:0],B[7:4],A[27:24],A[31:28],A[19:16],A[23:20],A[11:8],A[15:12],A[3:0],A[7:4]};
	
	if(Last)
	begin
		Nwren=1;
		if(number<=33)
		begin
		case(RES[(number*4-1)-:4])
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
			number=1;
			Last=0;
			Finish=0;
			total_length=0;
			string[511:0]={512{1'b0}};
			str_length=0;
			Nwren = 0;
			waddr[11:5]<=7'd0;
			waddr[4:0]<=waddr[4:0]+5'd1;
			write<=0;
			wren<=0;
			enter<=0;
			A = 32'h67452301;
			B = 32'hefcdab89;
			C = 32'h98badcfe;
			D = 32'h10325476;
			a=0;b=0;c=0;d=0;
		end
	end
	
	else
	begin
		Nwren=0;
	end
end
	

endmodule
