module kbd(clk,clrn,ps2_clk,ps2_data,outdata,en);
	input clk,clrn,ps2_clk,ps2_data;
	
	output reg en;
	output [7:0] outdata;
	
	reg [7:0] mycount;
	reg [7:0] kdata;		//传入查找表寻找ascii码的有效键码
	reg [10:0]count_clk;
	reg shift,up,caps,kbdclk,nextdata_n,bf;	//shift键标志位、大小写标志位、键码处理模块时钟、上一个键码为断码的标志位bf
	
	wire overflow,ready;
	wire [7:0] data;		//ps2_keyboard模块传入本模块的未经处理的键码
	wire [7:0] asciil;	//键码对应小写ascii码
	wire [7:0] asciih;	//键码对应大写ascii码
	wire [7:0] asciis;	//键码对应shift键按下时特殊字符ascii码

initial
begin
	nextdata_n = 1;
	bf = 0;
	mycount = 8'b00000000;
	kdata = 8'b00000000;
	up = 0;
	shift = 0;
	caps = 0;
end

ps2_keyboard kbd1(
	.clk(clk),
	.clrn(clrn),
	.ps2_clk(ps2_clk),
	.ps2_data(ps2_data),
	.data(data),
	.ready(ready),
	.nextdata_n(nextdata_n),
	.overflow(overflow)
);

k2al myk2al(
	.address(kdata),
	.clock(clk),
	.q(asciil)
);

k2ah myk2ah(
	.address(kdata),
	.clock(clk),
	.q(asciih)
);

k2as myk2as(
	.address(kdata),
	.clock(clk),
	.q(asciis)
);

//由shift键标志信息及大写标志信息up决定本模块最终输出的ascii码
assign outdata = ((asciis != asciih)&&(asciis != asciil) && shift == 1)? asciis : ((up == 1)? asciih : asciil);
//时钟分频
always @ (posedge clk)begin
	if(count_clk==1000)begin
		count_clk <= 0;
		kbdclk <= ~kbdclk;
	end
	else
		count_clk<=count_clk + 1;
end

always @ (posedge kbdclk) begin
		if(clrn == 0) begin					//清零
			nextdata_n = 1;
			bf = 0;
			mycount = 8'b00000000;
			kdata = 8'b00000000;
			up = 0;
			shift = 0;
			caps = 0;
			en=0;
		end
		
		//else if(Nwren == 1) begin
		//	en = 1;//写入字符
		//end
		
		else if(ready == 1) begin
			nextdata_n=1;
			en=0;
			if(data[7:0] == 8'h58) begin   				//caps键被按下时，翻转大小写标志位up
				if((bf == 0) && (caps == 0)) begin
					up = ~up;
					caps = 1;
				end
				else if(bf == 1)
					caps = 0;
			end
			
			if(data[7:0] == 8'h12 || data[7:0] == 8'h59) begin  
				if(bf == 1) begin									//shift键被松开时，翻转大小写标志位的同时将shift键置为0
					up = ~up;
					shift = 0;
				end
				else if((bf == 0) && (shift == 0)) begin	 //shift键被按下时，翻转大小写标志位的同时将shift标志位置为1
					up = ~up;
					shift = 1;
				end
			end
			
			if((data[7:0] != 8'hf0) && (bf == 0)) begin	//当按下按键时
				bf = 0;
				kdata = data;
				en=1;
			end
			
			else if(data[7:0] == 8'hf0) begin				//松开按键时
				bf = 1;
				mycount = mycount + 1;
				kdata = data;
				en=0;
			end
			
			else if(bf == 1)  begin								//上一个键码为断码
				en=0;
				bf = 0;
			end
			
			nextdata_n = 0;
		end
		
		else begin
			nextdata_n = 1;
			en=0;
		end
	end
	
endmodule
