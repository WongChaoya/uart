vlib work

vlog "./*v"

vsim -voptargs=+acc work.Uart_Interface_tb

view wave
view structure
view signals
radix unsigned

add wave -divider {Uart_Interface_tb}
add wave Uart_Interface_tb/*
#add wave -divider {Uart_Interface}
#add wave Uart_Interface_tb/u0/*
add wave -divider {Inst_tx_byte}
add wave Uart_Interface_tb/u0/u0/*
#add wave -divider {Inst_rx_byte}
#add wave Uart_Interface_tb/u0/u1/*

.main clear
run 500ms
