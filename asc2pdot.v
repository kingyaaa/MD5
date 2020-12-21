module asc2pdot(
	input clk,
	input vga_clk,
	input en,
	input reset,
	input blank_n,
	input [7:0]ascii,
	input [9:0]v_addr,
	input Nwren,
	input [7:0]oDATA,
	output reg[23:0]vga_data
);
	
reg wren;					//显存及ntp的写使能信号
reg kbdclk;					//键盘时钟
reg enter,write;  	//删除键标志位、回车键标志位及写入标志位
reg [6:0]  count_clk;	
reg [11:0] waddr;			//写入显存时的写入地址，同时也是光标所在位置，低五位记录行坐标，高七位记录列坐标
reg [7:0]  wr_asc;		//写入显存的	ascii码数据
reg [3:0]  count_v;		//块内列计数变量
reg [6:0]  count_h;		//行计数变量

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
	   if(en&&ascii==8'h0d)begin		//回车键
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

	else
		wren<=0;
   
	if(write)begin							//写入字符
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

	else if(enter)begin					//实现回车键
		waddr[11:5]<=7'd0;
		waddr[4:0]<=waddr[4:0]+5'd1;
		write<=0;
		wren<=0;
		enter<=0;
    end

end

endmodule
