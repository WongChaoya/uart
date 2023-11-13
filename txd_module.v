////////////////////////////////////////////////////
//
// Project: uart_top
// Author : CharlesWong
// Date	 : 2020/04/20
// Module : txd_module
// Version: 1.0
//
///////////////////////////////////////////////////
module txd_module(
input clk,
input rst_n,
input [7:0]data_in,
input tx_start,

output uart_txd,
output reg txd_done
);

reg txd_start_flag_r;
reg [3:0]bit_cnt_r;
reg [7:0]baud_cnt_r;
reg  baud_clk_r;
//产生16x baud时钟
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
	  	baud_clk_r <= 0; 
	end
	else begin
		baud_clk_r <= ~baud_clk_r;	
	end
end
//baud cnt
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		baud_cnt_r <= 8'd0;
	end
	else if (txd_start_flag_r) begin
		if(baud_clk_r)begin
			if(baud_cnt_r >=159)begin
				baud_cnt_r <= 8'd0;
			end
			else begin
				baud_cnt_r <= baud_cnt_r + 1;
			end
		end
		else baud_cnt_r <= baud_cnt_r;
	end
	else baud_cnt_r <=0;
end

//txd start flag
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		txd_start_flag_r <= 0;
		txd_done <=0;
	end
	else if(tx_start) begin
		txd_start_flag_r <= 1;
		txd_done <=0;
	end
	else if(baud_cnt_r >=159)begin
		txd_start_flag_r <=0;
		txd_done <=1;
	end
	else begin
		txd_done <=0;
		txd_start_flag_r <= txd_start_flag_r;
	end
end

//bit cnt
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		bit_cnt_r <= 0;
	end
	else if(txd_start_flag_r) begin
		if (baud_clk_r) begin
			case(baud_cnt_r)
			8'd0:   bit_cnt_r <= 0;
			8'd15:  bit_cnt_r <= bit_cnt_r +1;
			8'd31:  bit_cnt_r <= bit_cnt_r +1;
			8'd47:  bit_cnt_r <= bit_cnt_r +1;
			8'd63:  bit_cnt_r <= bit_cnt_r +1;
			8'd79:  bit_cnt_r <= bit_cnt_r +1;
			8'd95:  bit_cnt_r <= bit_cnt_r +1;
			8'd111: bit_cnt_r <= bit_cnt_r +1;
			8'd127: bit_cnt_r <= bit_cnt_r +1;
			8'd143: bit_cnt_r <= bit_cnt_r +1;
			default:bit_cnt_r <= bit_cnt_r;
			endcase
		end
	end
	else begin
		 bit_cnt_r <=0;
	end
end

reg [7:0]data_in_r;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		data_in_r <=0;
	end
	else if(tx_start)begin
		data_in_r <= data_in;
	end
	else begin
		data_in_r <= data_in_r;
	end
end
reg uart_txd_r;
reg txd_done_r;
//uart txd
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		uart_txd_r <= 1;
	end
	else if (txd_start_flag_r) begin
		case(bit_cnt_r)
		4'd0:uart_txd_r <=0; 
		4'd1:uart_txd_r <= data_in_r[7];
		4'd2:uart_txd_r <= data_in_r[6];
		4'd3:uart_txd_r <= data_in_r[5];
		4'd4:uart_txd_r <= data_in_r[4];	
		4'd5:uart_txd_r <= data_in_r[3];
		4'd6:uart_txd_r <= data_in_r[2];		
		4'd7:uart_txd_r <= data_in_r[1];
		4'd8:uart_txd_r <= data_in_r[0];
		4'd9:uart_txd_r<=1;
		default:uart_txd_r <= 1;
		endcase		
	end
	else uart_txd_r <=1;	
end
assign uart_txd = uart_txd_r;
endmodule 