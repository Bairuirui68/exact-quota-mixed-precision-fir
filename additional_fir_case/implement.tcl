# Isolated FIR-only routed comparison. Never programs the board.
set case_dir [file normalize [file dirname [info script]]]
set tag [expr {$argc > 0 ? [lindex $argv 0] : "implementation"}]
set out [file join $case_dir $tag]
if {[file exists $out]} {error "Preserve previous evidence: $out"}
file mkdir $out
set summary [open [file join $out summary.csv] w]
puts $summary "top,DSP48E1,LUT_logic_primitive,FF_primitive,overall_WNS_ns,reg_to_reg_slack_ns"
foreach top {fir48_dp_folded fir48_greedy_folded fir48_dp_direct fir48_greedy_direct} {
    set run_dir [file join $out $top]
    file mkdir $run_dir
    create_project $top $run_dir -part xc7a35tfgg484-2
    add_files [file join $case_dir rtl "$top.v"]
    synth_design -top $top -part xc7a35tfgg484-2 -flatten_hierarchy rebuilt
    create_clock -name fir_clk -period 10.000 [get_ports clk]
    set_input_delay -clock fir_clk 2.000 [get_ports {data_in[*] en rst}]
    set_output_delay -clock fir_clk 2.000 [get_ports {data_out[*] valid_out}]
    report_utilization -file [file join $run_dir post_synth_utilization.rpt]
    opt_design
    place_design
    phys_opt_design
    route_design
    report_utilization -file [file join $run_dir post_route_utilization.rpt]
    report_timing_summary -file [file join $run_dir post_route_timing.rpt]
    report_drc -file [file join $run_dir post_route_drc.rpt]
    report_timing -from [all_registers -clock_pins] -to [all_registers -data_pins] -max_paths 10 -file [file join $run_dir reg_to_reg_timing.rpt]
    write_checkpoint [file join $run_dir post_route.dcp]
    set dsp 0
    set lut 0
    set ff 0
    foreach c [get_cells -hier -filter {IS_PRIMITIVE == 1}] {
        set ref [get_property REF_NAME $c]
        if {$ref eq "DSP48E1"} {incr dsp}
        if {[regexp {^LUT[1-6]$} $ref]} {incr lut}
        if {[regexp {^FD[A-Z0-9]+$} $ref]} {incr ff}
    }
    set worst [get_timing_paths -max_paths 1]
    set core [get_timing_paths -from [all_registers -clock_pins] -to [all_registers -data_pins] -max_paths 1]
    puts $summary "$top,$dsp,$lut,$ff,[get_property SLACK $worst],[get_property SLACK $core]"
    flush $summary
    close_project
}
close $summary
puts "FIR48 IMPLEMENTATION COMPLETED"
