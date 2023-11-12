////////////////////////////////////////////////////
//
// Project: uart_top
// Author : CharlesWong
// Date	 : 2020/04/19
// Module : uart_top
// Version: 1.0
//
//	Notes	 : baud rate 115200bps
//
//
//
///////////////////////////////////////////////////
`timescale 1ns/1ps
module uart_top(
input clk,//50Mhz
input rst_n,
input uart_rxd,

output uart_txd,
output txd_done
);
wire [7:0]data_w;
wire rxd_done_w;

rxd_module u_rxd_module(
.clk(clk),//16x baud freq
.rst_n(rst_n),//async reset active-low
.uart_rxd(uart_rxd),//uart receive

.rxd_done(rxd_done_w),
.data_rxd(data_w)
);

txd_module u_txd_module(
.clk(clk),
.rst_n(rst_n),
.data_in(data_w),
.tx_start(rxd_done_w),

.txd_done(txd_done),
.uart_txd(uart_txd)
);



endmodule