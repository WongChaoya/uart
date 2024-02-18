module Uart_Interface_top (
	input Clk,
	input Rst,
	input iRx_Bit,
	output oTx_Bit
);

wire    wUartClk;

syspll syspll_u0(
	.inclk0(Clk),
	.c0(wUartClk)
);


wire                  iTx_Val;
wire      [7:0]       wTx_Data;


wire                 oTx_done;
wire                 oTx_Rdy;
wire                 oRx_Val;
wire                 oRx_err;
wire      [7:0]      oRx_Data;

// localparam   TX_BAUD_RATE=   50_000_000/460800;
// localparam   RX_BAUD_RATE=   50_000_000/460800/16;
localparam   BAUD_RATE   = 3_000_000;
localparam   SYS_FREQ    = 100_000_000;

Uart_Interface#(
    .C_Tx_en(1),
    .C_Rx_en(1),
    .BAUD_RATE(BAUD_RATE),//串口波特率
    .SYS_FREQ(SYS_FREQ)//系统主频
)u0(
    .Clk(wUartClk),
    .Rst(wRst),

    .iTx_Clk_Div(),
    .iTx_Val(oRx_Val),
    .iTx_Data(oRx_Data),
    .iTx_Check_odd(0),//奇校验
    .iTx_Check_even(0),//偶校验
    .iRx_Clk_Div(),
    .iRx_Bit(iRx_Bit),
    .iRx_Check_odd(0),//奇校验
    .iRx_Check_even(0),//偶校验

    .oTx_done(oTx_done),
    .oTx_Bit(oTx_Bit),
    .oTx_Rdy(oTx_Rdy),
    .oRx_Val(oRx_Val),
    .oRx_err(oRx_err),
    .oRx_Data(oRx_Data)
);

reg [9:0] rCnt =0;

(* keep *) wire wRst = ~rCnt[9];
always@(posedge Clk) begin
	if(rCnt[9]) begin
		rCnt	<= rCnt;
	end
	else begin
		rCnt <= rCnt	+	1;
	end
end


endmodule //Uart_Interface_tb