//--------------------------------------------------------------------------------------------
//
// Create Date: 2023/12/16
// Design Name: 
// Module Name: Uart_Interface
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


module Uart_Interface#(
    parameter    C_Tx_en = 1'b1,
    parameter    C_Rx_en = 1'b1,
    parameter    BAUD_RATE   =   3125000,//串口波特率
    parameter    SYS_FREQ    =   50_000_000//系统主频
)(
    input                   Clk,
    input                   Rst,

    input       [9:0]       iTx_Clk_Div,
    input                   iTx_Val,
    input       [7:0]       iTx_Data,
    input                   iTx_Check_odd,//奇校验
    input                   iTx_Check_even,//偶校验
    input       [9:0]       iRx_Clk_Div,
    input                   iRx_Bit,
    input                   iRx_Check_odd,//奇校验
    input                   iRx_Check_even,//偶校验

    output                  oTx_done,
    output                  oTx_Bit,
    output                  oTx_Rdy,
    output                  oRx_Val,
    output                  oRx_err,
    output      [7:0]       oRx_Data
);

  
   
   
reg          tx_rst;
reg          rx_rst;
reg [7:0]    cnt_tx_rst;
reg [7:0]    cnt_rx_rst;
reg [9:0]    Tx_Clk_Div;
reg [9:0]    Rx_Clk_Div;


always @(posedge Clk) begin
    Tx_Clk_Div <= iTx_Clk_Div;
    Rx_Clk_Div <= iRx_Clk_Div;
    
    if (Rst == 1'b1) begin
        tx_rst <= 1'b1;
        rx_rst <= 1'b1;
        cnt_tx_rst <= {8{1'b0}};
        cnt_rx_rst <= {8{1'b0}};
    end
    else begin
        if (iTx_Clk_Div != Tx_Clk_Div) begin
            cnt_tx_rst <= 8'h01;
        end
        else if (cnt_tx_rst[7] == 1'b1) begin
            cnt_tx_rst <= {8{1'b0}};
        end
        else if (cnt_tx_rst != 0) begin
            cnt_tx_rst <= cnt_tx_rst + 1;
        end
        else begin
            cnt_tx_rst <= {8{1'b0}};
        end
        
        if (iRx_Clk_Div != Rx_Clk_Div) begin
            cnt_rx_rst <= 8'h01;
        end
        else if (cnt_tx_rst[7] == 1'b1) begin
            cnt_rx_rst <= {8{1'b0}};
        end
        else if (cnt_tx_rst != 0) begin
            cnt_rx_rst <= cnt_rx_rst + 1;
        end
        else begin
            cnt_rx_rst <= {8{1'b0}};
        end
        
        if (cnt_tx_rst != 0) begin
            tx_rst <= 1'b1;
        end
        else begin
            tx_rst <= 1'b0;
        end
        
        if (cnt_rx_rst != 0) begin
            rx_rst <= 1'b1;
        end
        else begin
            rx_rst <= 1'b0;
        end
    end
end

// generate
//     if (C_Tx_en == 1'b1) begin 
        Uart_Tx_byte #(
            .BAUD_RATE(BAUD_RATE),//串口波特率
            .SYS_FREQ(SYS_FREQ)//系统主频
        )u0(
            .Clk(Clk), 
            .Rst(tx_rst), 
            .iBaudrate_DIV(iTx_Clk_Div), 
            .iTx_Val(iTx_Val), 
            .iData(iTx_Data), 
            .iCheck_odd(iTx_Check_odd), 
            .iCheck_even(iTx_Check_even), 
            .oTx_done(oTx_done), 
            .oBit(oTx_Bit), 
            .oRdy(oTx_Rdy)
        );
//     end
// endgenerate

// generate
//     if (C_Rx_en == 1'b1) begin 
        Uart_Rx_byte #(
            .BAUD_RATE(BAUD_RATE),//串口波特率
            .SYS_FREQ(SYS_FREQ)//系统主频
        )u1(
            .Clk(Clk), 
            .Rst(rx_rst), 
            .iBaudrate_DIV(iRx_Clk_Div), 
            .iRxBit(iRx_Bit), 
            .iCheck_odd(iRx_Check_odd), 
            .iCheck_even(iRx_Check_even), 
            .oRx_Val(oRx_Val), 
            .oRx_err(oRx_err), 
            .oRx_Data(oRx_Data)
        );
//     end
// endgenerate
   
endmodule
