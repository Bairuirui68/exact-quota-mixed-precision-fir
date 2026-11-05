# run_sim.tcl - Vivado simulation script for FIR testbench

# Create a saved project because Vivado Simulator requires an open project.
set script_dir [file normalize [file dirname [info script]]]
set project_dir [file join $script_dir work fir_sim_project]
create_project -force fir_sim_project $project_dir -part xc7a35tfgg484-2

# Add RTL and testbench to the simulation fileset.
add_files -fileset sim_1 [list \
    [file join $script_dir fir_multiplier.v] \
    [file join $script_dir fir_direct_pipeline.v] \
    [file join $script_dir tb_fir.v]]
set_property include_dirs [list $script_dir] [get_filesets sim_1]

# Set top module
set_property top tb_fir [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1

# $readmemh resolves relative paths from the simulator run directory.
set sim_data_dir [file join $project_dir fir_sim_project.sim sim_1 behav xsim]
file mkdir $sim_data_dir
foreach vector_file [glob -directory $script_dir *.hex] {
    file copy -force $vector_file $sim_data_dir
}

# Launch only after the vectors are in place; Vivado starts the sim immediately.
launch_simulation -simset sim_1 -mode behavioral

# Run until finish
run -all

# Exit
quit
