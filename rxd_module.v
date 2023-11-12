////////////////////////////////////////////////////
//
// Project: uart_top
// Author : CharlesWong
// Date	 : 2020/04/19
// Module : rxd_module
// Version: 1.0
//
///////////////////////////////////////////////////
module rxd_module(
input clk,//50Mhz
input rst_n,//async reset active-low
input uart_rxd,//uart receive

output rxd_done,
output [7:0]data_rxd
);

reg [7:0]baud_cnt_r;
reg bit_flag_r;
reg rxd_start_flag_r;
reg  baud_clk_r;
reg uart_rxd_temp1,uart_rxd_temp2;
wire rxd_start;
//产生16x baud时钟(25M/16 = 1652500bps)
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
	  	baud_clk_r <= 0; 
	end
	else begin
		baud_clk_r <= ~baud_clk_r;	
	end
end
//起始位检测
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
	  uart_rxd_temp1 <=0;
	  uart_rxd_temp2 <=0;
	end
	else begin
	  uart_rxd_temp1 <= uart_rxd;
	  uart_rxd_temp2 <= uart_rxd_temp1;
	end
end
assign rxd_start = (uart_rxd_temp2) && (~uart_rxd_temp1);
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		rxd_start_flag_r <=0;
	end
	else if (rxd_start) begin
		rxd_start_flag_r <=1;
	end
	else if (baud_cnt_r >=159) begin
		rxd_start_flag_r <=0;
	end
	else rxd_start_flag_r <= rxd_start_flag_r;
end

//uart baud cnt
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		baud_cnt_r <= 0;
	end
	else if (rxd_start_flag_r) begin
		if(baud_clk_r) begin
			if(baud_cnt_r >= 159) begin
				baud_cnt_r <= 0;
			end
			else begin
				baud_cnt_r <= baud_cnt_r + 1;
			end
		end
	end
	else baud_cnt_r <=0;
end

//uart bit flag
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		bit_flag_r <= 0;
	end
	else if (baud_clk_r) begin
		case(baud_cnt_r)
		// 8'd7:bit_flag_r <= 1;
		8'd23:bit_flag_r <= 1;
		8'd39:bit_flag_r <= 1;
		8'd55:bit_flag_r <= 1;
		8'd71:bit_flag_r <= 1;
		8'd87:bit_flag_r<= 1;
		8'd103:bit_flag_r<= 1;
		8'd119:bit_flag_r<= 1;
		8'd135:bit_flag_r<=1;
		default:bit_flag_r<=0;
		endcase
	end 
end
reg [7:0]data_rxd_temp_r;
//uart bit out
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		data_rxd_temp_r <= 0;
	end
	else if (baud_clk_r) begin
		 if(rxd_start_flag_r && bit_flag_r) begin
			data_rxd_temp_r <= {data_rxd_temp_r[6:0],uart_rxd};
		end
		else begin
			data_rxd_temp_r <= data_rxd_temp_r;
		end
		end
end

reg [7:0]data_rxd_r;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		data_rxd_r <= 0;
	end
	else if(baud_cnt_r==159) begin
		data_rxd_r <= data_rxd_temp_r;
	end
	else begin
		data_rxd_r <= data_rxd_r;
	end
end
reg [3:0]bit_cnt_r;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		bit_cnt_r <= 0;
	end
	else if(bit_flag_r)begin
		if(bit_cnt_r ==7)begin
			bit_cnt_r <=0;
		end
		else bit_cnt_r <= bit_cnt_r +1;
	end
end
assign data_rxd = data_rxd_r;
assign rxd_done = (baud_cnt_r ==159 ) ? 1:0;
endmodule