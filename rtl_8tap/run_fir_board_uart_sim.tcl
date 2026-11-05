set script_dir [file normalize [file dirname [info script]]]
set project_dir [file join $script_dir work fir_board_uart_sim]
create_project -force fir_board_uart_sim $project_dir -part xc7a35tfgg484-2
add_files -fileset sim_1 [list \
    [file join $script_dir fir_board_uart.v] \
    [file join $script_dir fir_direct_pipeline.v] \
    [file join $script_dir fir_multiplier.v] \
    [file join $script_dir tb_fir_board_uart.v]]
set_property include_dirs [list $script_dir] [get_filesets sim_1]
set_property top tb_fir_board_uart [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1
file mkdir [file join $project_dir fir_board_uart_sim.sim sim_1 behav xsim]
file copy -force [file join $script_dir input_seq.hex] [file join $project_dir fir_board_uart_sim.sim sim_1 behav xsim input_seq.hex]
launch_simulation -simset sim_1 -mode behavioral
run -all
quit
