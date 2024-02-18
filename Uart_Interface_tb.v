//--------------------------------------------------------------------------------------------
//
// Create Date: 2024/01/27
// Design Name: 
// Module Name: Uart_Interface_tb
// Engineer:ChaoyaWang
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//--------------------------------------------------------------------------------------------
`timescale  1ns/1ns
module Uart_Interface_tb ();

reg                  Clk;
reg                  Rst;
reg      [9:0]       iTx_Clk_Div;
reg                  iTx_Val;
reg      [7:0]       iTx_Data;
reg                  iTx_Check_odd;//奇校验
reg                  iTx_Check_even;//偶校验
reg      [9:0]       iRx_Clk_Div;
// reg                  iRx_Bit;
reg                  iRx_Check_odd;//奇校验
reg                  iRx_Check_even;//偶校验

wire                 oTx_done;
wire                 oTx_Bit;
wire                 oTx_Rdy;
wire                 oRx_Val;
wire                 oRx_err;
wire      [7:0]      oRx_Data;

localparam   CLK_PERIOD  =   20;
localparam   TX_BAUD_RATE=   50_000_000/115200;
always #(CLK_PERIOD /2) Clk =   ~Clk;

initial begin
                        Rst =   1;
                        Clk =   0;
                        iTx_Clk_Div     =   TX_BAUD_RATE;//发送端使用对应波特率
                        iRx_Clk_Div     =   TX_BAUD_RATE/16;//接收端使用16倍波特率
                        iTx_Check_odd   =   0;
                        iTx_Check_even  =   0;
                        iRx_Check_odd   =   0;
                        iRx_Check_even  =   0;
    #(CLK_PERIOD * 3)   Rst =   0;
                        iTx_Val         =   1;
                        iTx_Data        =   0;
    #(CLK_PERIOD * 2)   iTx_Val         =   0;
end

Uart_Interface#(
    .C_Tx_en(1),
    .C_Rx_en(1)
)u0(
    .Clk(Clk),
    .Rst(Rst),

    .iTx_Clk_Div(iTx_Clk_Div),
    .iTx_Val(iTx_Val),
    .iTx_Data(iTx_Data),
    .iTx_Check_odd(iTx_Check_odd),//奇校验
    .iTx_Check_even(iTx_Check_even),//偶校验
    .iRx_Clk_Div(iRx_Clk_Div),
    .iRx_Bit(oTx_Bit),
    .iRx_Check_odd(iRx_Check_odd),//奇校验
    .iRx_Check_even(iRx_Check_even),//偶校验

    .oTx_done(oTx_done),
    .oTx_Bit(oTx_Bit),
    .oTx_Rdy(oTx_Rdy),
    .oRx_Val(oRx_Val),
    .oRx_err(oRx_err),
    .oRx_Data(oRx_Data)
);

initial begin
    repeat(200) begin
        @(posedge oTx_done) begin
            iTx_Data    =  iTx_Data + 1;
            iTx_Val     =   1;
             #(CLK_PERIOD * 2)   iTx_Val         =   0;
        end
    end
    iTx_Val =   0;
    #(CLK_PERIOD * 2000);
    $stop;
end
    
endmodule //Uart_Interface_tb
