create_clock -name fir_clk -period 10.000 [get_ports clk]
set_input_delay -clock fir_clk 2.000 [get_ports {data_in[*] en rst}]
set_output_delay -clock fir_clk 2.000 [get_ports {data_out[*] valid_out}]
