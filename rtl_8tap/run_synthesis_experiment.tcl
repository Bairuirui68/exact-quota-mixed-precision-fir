# Six independent synthesis and implementation runs for FIR precision mapping.
set script_dir [file normalize [file dirname [info script]]]
cd $script_dir
set output_root [file join $script_dir outputs fir_synthesis_experiment]
file mkdir $output_root

set rtl_files [list \
    [file join $script_dir fir_multiplier.v] \
    [file join $script_dir fir_direct_pipeline.v] \
    [file join $script_dir fir_synth_tops.v]]
set xdc_file [file join $script_dir fir_mapping_timing.xdc]
set part xc7a35tfgg484-2
set summary_path [file join $output_root summary.csv]
set summary [open $summary_path w]
puts $summary "run,config,mapping,DSP48E1_synth,LUT_primitive_cells_synth,FF_primitive_cells_synth,DSP48E1_route,LUT_primitive_cells_route,FF_primitive_cells_route"

proc primitive_counts {} {
    set counts [dict create dsp 0 lut 0 ff 0]
    foreach cell [get_cells -hier -filter {IS_PRIMITIVE == 1}] {
        set ref [get_property REF_NAME $cell]
        if {$ref eq "DSP48E1"} {
            dict incr counts dsp
        } elseif {[regexp {^LUT[1-6]$} $ref]} {
            dict incr counts lut
        } elseif {[regexp {^FD[A-Z0-9]+$} $ref]} {
            dict incr counts ff
        }
    }
    return $counts
}

proc write_counts {path counts} {
    set f [open $path w]
    puts $f "DSP48E1 [dict get $counts dsp]"
    puts $f "LUT_logic [dict get $counts lut]"
    puts $f "FF [dict get $counts ff]"
    close $f
}

proc run_case {script_dir output_root rtl_files xdc_file part summary run config mapping top force_dsp} {
    puts "\n===== $run: config=$config mapping=$mapping ====="
    set run_dir [file join $output_root $run]
    file mkdir $run_dir
    create_project -force "fir_mapping_$run" $run_dir -part $part
    add_files -fileset sources_1 {*}$rtl_files
    set_property include_dirs [list $script_dir] [get_filesets sources_1]
    if {$force_dsp} {
        set_property verilog_define {FORCE_DSP} [get_filesets sources_1]
    }
    add_files -fileset constrs_1 $xdc_file
    update_compile_order -fileset sources_1
    synth_design -top $top -part $part -flatten_hierarchy rebuilt

    report_utilization -file [file join $run_dir post_synth_utilization.rpt]
    report_timing_summary -delay_type max -file [file join $run_dir post_synth_timing.rpt]
    write_checkpoint -force [file join $run_dir post_synth.dcp]
    set synth_counts [primitive_counts]
    write_counts [file join $run_dir post_synth_primitive_counts.txt] $synth_counts

    opt_design
    place_design
    phys_opt_design
    route_design
    report_utilization -file [file join $run_dir post_route_utilization.rpt]
    report_timing_summary -delay_type max -file [file join $run_dir post_route_timing.rpt]
    report_timing -delay_type max -max_paths 5 -file [file join $run_dir post_route_critical_paths.rpt]
    write_checkpoint -force [file join $run_dir post_route.dcp]
    set route_counts [primitive_counts]
    write_counts [file join $run_dir post_route_primitive_counts.txt] $route_counts

    puts $summary "$run,$config,$mapping,[dict get $synth_counts dsp],[dict get $synth_counts lut],[dict get $synth_counts ff],[dict get $route_counts dsp],[dict get $route_counts lut],[dict get $route_counts ff]"
    flush $summary
    close_project
}

foreach config {A B C} {
    set top "fir_synth_$config"
    foreach mapping {forced auto} {
        set run_number [expr {$mapping eq "forced" ? 1 : 2}]
        set run "${config}${run_number}"
        set force_dsp [expr {$mapping eq "forced"}]
        run_case $script_dir $output_root $rtl_files $xdc_file $part $summary $run $config $mapping $top $force_dsp
    }
}

close $summary
puts "\nCompleted six runs. Summary: $summary_path"
quit
