//--------------------------------------------------------------------------------------------
//
// Create Date: 2020/04/19
// Design Name: 
// Module Name: Uart_Tx_byte
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
// Modification History:
//   Date       |   Author      |   Version     |   Change Description
//============================================================================================
// 2020-04-19   |   ChaoyaWang  |     0.1       |   beta Version
// 2024-02-01   |   ChaoyaWang  |     0.2       |   针对威思沃接口进行移植,满足3.125Mbps
//--------------------------------------------------------------------------------------------



module Uart_Tx_byte#(
    parameter   SYS_FREQ    =   50_000_000,
    parameter   BAUD_RATE   =   2000000
)(
   input                Clk,
   input                Rst,
   input        [9:0]   iBaudrate_DIV,
   input                iTx_Val,
   input        [7:0]   iData,
   input                iCheck_odd,
   input                iCheck_even,
   output               oTx_done,
   output               oBit,
   output               oRdy
);
   
   

// localparam          BAUD_RATE_3125M  = ((SYS_FREQ == 50_000_000) && (BAUD_RATE == 3_125_000)) ? 1:0;
localparam          CTRL_WORD_WIDTH  = 24;//控制字位宽
localparam [50:0]   BAUD_CTRL_WORD   = (BAUD_RATE * (1<<(CTRL_WORD_WIDTH + 4))) / (SYS_FREQ) ;//16x baud rate控制字
reg [CTRL_WORD_WIDTH-1:0] rCtrlWordCnt;//控制字计数器
reg rTxdDone;
reg rTxdTransfer;
reg [3:0] rBitCnt;
//产生16倍波特率时钟
always @(posedge    Clk) begin
    if (Rst) begin
        rCtrlWordCnt <=  0;
    end
    else begin
        rCtrlWordCnt <=  rCtrlWordCnt +   BAUD_CTRL_WORD;
    end
end

wire    wBaudClk  =   rCtrlWordCnt[CTRL_WORD_WIDTH-1];//产生16x baud rate时钟


reg [7:0]   rBaudCnt;
reg  rBaudClk;
//捕捉16x baud rate时钟上升沿
always @(posedge Clk ) begin
    if(Rst) begin
        rBaudClk    <= 0;
    end
    else begin
        rBaudClk <=  wBaudClk;
    end
end
wire wBaudClkPos =   ~rBaudClk & wBaudClk;
//baud cnt
always@(posedge Clk ) begin
	if(Rst) begin
		rBaudCnt <= 8'd0;
	end
	else if (rTxdTransfer) begin
		if(wBaudClkPos)begin
			if(rBaudCnt >=157)begin
				rBaudCnt <= 8'd0;
			end
			else begin
				rBaudCnt <= rBaudCnt + 1;
			end
		end
		else rBaudCnt <= rBaudCnt;
	end
	else rBaudCnt <=0;
end

//txd start flag
reg rTxdVal;
always @(posedge Clk) begin
    if (Rst) begin
        rTxdVal <=  0;
    end
    else begin
        rTxdVal <=  iTx_Val;
    end
end
wire    wTxdValPos  =   ~rTxdVal    &   iTx_Val;
//rTxdTransfer：数据正在传输中标志
always@(posedge Clk ) begin
	if(Rst) begin
		rTxdTransfer <= 0;
		rTxdDone <=0;
	end
	else if(wTxdValPos) begin
		rTxdTransfer <= 1;
		rTxdDone <=0;
	end
	else if(rBaudCnt >=157)begin
		rTxdTransfer <=0;
		rTxdDone <=1;
	end
	else begin
		rTxdDone <=0;
		rTxdTransfer <= rTxdTransfer;
	end
end

//bit cnt
always@(posedge Clk ) begin
	if(Rst) begin
		rBitCnt <= 0;
	end
	else if(rTxdTransfer) begin
		if (wBaudClkPos) begin
			case(rBaudCnt)
                8'd0:   rBitCnt <= 0;
                8'd15:  rBitCnt <= rBitCnt +1;
                8'd31:  rBitCnt <= rBitCnt +1;
                8'd47:  rBitCnt <= rBitCnt +1;
                8'd63:  rBitCnt <= rBitCnt +1;
                8'd79:  rBitCnt <= rBitCnt +1;
                8'd95:  rBitCnt <= rBitCnt +1;
                8'd111: rBitCnt <= rBitCnt +1;
                8'd127: rBitCnt <= rBitCnt +1;
                8'd143: rBitCnt <= rBitCnt +1;
                default:rBitCnt <= rBitCnt;
			endcase
		end
	end
	else begin
		 rBitCnt <=0;
	end
end

reg [7:0]rDatain;

always@(posedge Clk ) begin
	if(Rst) begin
		rDatain <=0;
	end
	else if(wTxdValPos)begin
		rDatain <= iData;
	end
	else begin
		rDatain <= rDatain;
	end
end
reg rTxd;
//uart txd
always@(posedge Clk ) begin
	if(Rst) begin
		rTxd <= 1;
	end
	else if (rTxdTransfer) begin
		case(rBitCnt)
            4'd0:rTxd <=0; 
            4'd1:rTxd <= rDatain[0];
            4'd2:rTxd <= rDatain[1];
            4'd3:rTxd <= rDatain[2];
            4'd4:rTxd <= rDatain[3];	
            4'd5:rTxd <= rDatain[4];
            4'd6:rTxd <= rDatain[5];		
            4'd7:rTxd <= rDatain[6];
            4'd8:rTxd <= rDatain[7];
            4'd9:rTxd<=1;
            default:rTxd <= 1;
		endcase		
	end
	else rTxd <=1;	
end
//添加rTxRdy信号
reg rTxRdy;

always @(posedge Clk) begin
    if (Rst) begin
        rTxRdy  <=  1;
    end
    else begin
        rTxRdy  <=  ~rTxdTransfer;
    end
end
assign  oRdy        =   rTxRdy;
assign  oBit        =   rTxd;   
assign  oTx_done    =   rTxdDone;
endmodule
