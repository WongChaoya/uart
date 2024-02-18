//--------------------------------------------------------------------------------------------
//
// Create Date: 2020/04/19
// Design Name: 
// Module Name: Uart_Rx_byte
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
// 2024-02-01   |   ChaoyaWang  |     0.2       |   针对威思沃接口进行移植,满足3.125Mbps,修复
//                                              |   大于921600bps后误码率高的bug
//--------------------------------------------------------------------------------------------
module Uart_Rx_byte #(
   parameter    BAUD_RATE   =   2000000,//串口波特率
   parameter    SYS_FREQ    =   50_000_000//系统主频
)(
    input               Clk,
    input               Rst,
    input   [9:0]       iBaudrate_DIV,
    input               iRxBit,
    input               iCheck_odd,//奇校验
    input               iCheck_even,//偶校验
    output              oRx_Val,
    output              oRx_err,
    output  [7:0]       oRx_Data
);
   
   
// localparam          BAUD_RATE_3125M  = ((SYS_FREQ == 50_000_000) && (BAUD_RATE == 3_125_000)) ? 1:0;
localparam                          CTRL_WORD_WIDTH  = 24;//控制字位宽
localparam  [50:0]                  BAUD_CTRL_WORD   = (BAUD_RATE * (1<<(CTRL_WORD_WIDTH + 4))) / (SYS_FREQ);//16x baud rate控制字
reg         [CTRL_WORD_WIDTH-1:0]   rCtrlWordCnt;//控制字计数器

//状态
localparam  St_Idle     = 0,//空闲
            St_Start    = 1,//起始位检查
            St_Rxd      = 2,//数据接收
            St_Stop     = 3,//停止位
            St_Finish   = 4;//结束  

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
reg         rBitFlag;
reg         rBaudClk;
reg         rUartRxd1,rUartRxd2;
reg [3:0]   rCurState;//当前状态寄存器

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
//起始位检测
always @(posedge Clk ) begin
	if(Rst)begin
	  rUartRxd1 <=0;
	  rUartRxd2 <=0;
	end
	else begin
	  rUartRxd1 <= iRxBit;
	  rUartRxd2 <= rUartRxd1;
	end
end

wire  wBaudCntStart =   (rUartRxd2) & (~rUartRxd1);

//uart baud cnt
always@(posedge Clk ) begin
	if(Rst) begin
		rBaudCnt <= 0;
	end
	else if(wBaudClkPos) begin
        if(rCurState    == St_Idle) begin
            rBaudCnt <= 0;
        end
        else begin
            rBaudCnt <= rBaudCnt + 1;
        end
    end
end
//状态转换
always @(posedge Clk) begin
    if (Rst) begin
        rCurState   <=  St_Idle;
    end
    else begin
        case (rCurState)
            St_Idle :   begin
                if (wBaudCntStart) begin//检测到真实的起始位
                    rCurState   <=  St_Start;
                end
            end
            St_Start:   begin
                if (rBaudCnt <= 4 && iRxBit) begin//不是真正的起始位
                    rCurState   <=  St_Idle;
                end
                else if (rBaudCnt >= 16) begin
                    rCurState   <=  St_Rxd;
                end
            end
            St_Rxd  :   begin
                if (rBaudCnt >= 144) begin//接收完8bit数据
                    rCurState   <=  St_Stop;
                end
            end
            St_Stop :   begin
                if (rBaudCnt == 150) begin
                    rCurState   <=  St_Finish;
                end
            end
            St_Finish:  begin
                rCurState   <=  St_Idle;
            end   
            default: rCurState   <=  St_Idle;
        endcase
    end
end
//uart bit flag
always@(posedge Clk ) begin
	if(Rst) begin
		rBitFlag <= 0;
	end
	else if (wBaudClkPos) begin
		case(rBaudCnt)
            8'd22:  rBitFlag  <= 1;
            8'd38:  rBitFlag  <= 1;
            8'd54:  rBitFlag  <= 1;
            8'd70:  rBitFlag  <= 1;
            8'd86:  rBitFlag  <= 1;
            8'd102: rBitFlag  <= 1;
            8'd118: rBitFlag  <= 1;
            8'd134: rBitFlag  <= 1;
            default:rBitFlag  <= 0;
		endcase
	end 
end
reg [7:0]rDataDeserial;
//串转并
always@(posedge Clk ) begin
	if(Rst) begin
		rDataDeserial <= 0;
	end
	else if (wBaudClkPos) begin
		if(rCurState    == St_Rxd) begin
            if (rBitFlag) begin
			    rDataDeserial <= {iRxBit,rDataDeserial[7:1]};
            end
		end
		else begin
			rDataDeserial <= 0;
		end
    end
end

reg [7:0]   rDataRxd;
reg         rDataValid;
wire wDataValid =    (rCurState == St_Rxd) && (rBaudCnt ==137)  ? 1:0;
//wDataValid多延迟一拍，与数据对齐
always @(posedge Clk) begin
    if (Rst) begin
        rDataValid  <=  0;
    end
    else begin
        rDataValid  <=  wDataValid;
    end
end
always @(posedge Clk ) begin
	if(Rst) begin
		rDataRxd      <= 0;
	end
	else if(rCurState  == St_Rxd && rBaudCnt ==137) begin
		rDataRxd <= rDataDeserial;
	end
	else begin
		rDataRxd <= rDataRxd;
	end
end

assign oRx_Data = rDataRxd;
assign oRx_Val  = rDataValid;
endmodule