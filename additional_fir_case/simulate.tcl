set case_dir [file normalize [file dirname [info script]]]
set tag [expr {$argc > 0 ? [lindex $argv 0] : "simulation"}]
set out [file join $case_dir $tag]
if {[file exists $out]} {error "Preserve existing simulation directory: $out"}
file mkdir $out
create_project fir48_sim $out -part xc7a35tfgg484-2
add_files [glob [file join $case_dir rtl fir48_*.v]]
add_files -fileset sim_1 [file join $case_dir rtl tb_fir48.sv]
foreach f [glob [file join $case_dir rtl *.hex]] {
    add_files -fileset sim_1 $f
    set_property file_type {Memory Initialization Files} [get_files $f]
}
set_property top tb_fir48 [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]
launch_simulation
close_sim
close_project
