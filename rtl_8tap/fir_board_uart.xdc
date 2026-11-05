# ACX750 XC7A35T-2FGG484 board test. Pin assignments cross-checked against
# the ACX750 user manual and the supplied board pin-constraint file.
set_property PACKAGE_PIN W19 [get_ports FPGA_CLK]
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_CLK]
create_clock -name board_clk -period 20.000 [get_ports FPGA_CLK]

set_property PACKAGE_PIN D21 [get_ports S0_N]
set_property IOSTANDARD LVCMOS33 [get_ports S0_N]

set_property PACKAGE_PIN L21 [get_ports UART_RXD]
set_property IOSTANDARD LVCMOS33 [get_ports UART_RXD]
set_property PACKAGE_PIN M21 [get_ports UART_TXD]
set_property IOSTANDARD LVCMOS33 [get_ports UART_TXD]

set_property PACKAGE_PIN U22 [get_ports {LED[0]}]
set_property PACKAGE_PIN V22 [get_ports {LED[1]}]
set_property PACKAGE_PIN W21 [get_ports {LED[2]}]
set_property PACKAGE_PIN W22 [get_ports {LED[3]}]
set_property PACKAGE_PIN Y21 [get_ports {LED[4]}]
set_property PACKAGE_PIN Y22 [get_ports {LED[5]}]
set_property PACKAGE_PIN N13 [get_ports {LED[6]}]
set_property PACKAGE_PIN N17 [get_ports {LED[7]}]
set_property PACKAGE_PIN P17 [get_ports {LED[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[*]}]

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]

set_false_path -from [get_ports UART_RXD] -to [get_pins {receiver/rx_meta_reg/D}]
set_false_path -from [get_ports S0_N]
