
set_location_assignment PIN_E1 -to clk
set_location_assignment PIN_E15 -to rst_n
set_location_assignment PIN_B5 -to uart_rxd
set_location_assignment PIN_A6 -to uart_txd

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to clk
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to rst_n
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to uart_txd
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to uart_rxd

