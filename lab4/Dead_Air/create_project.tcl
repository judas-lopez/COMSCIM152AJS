# Run from the Vivado Tcl console: source {/absolute/path/to/Dead_Air/create_project.tcl}
set source_root [file dirname [file normalize [info script]]]
set project_dir [file join $source_root build]
set project_file [file join $project_dir dead_air.xpr]
if {[file exists $project_file]} {
    open_project $project_file
} else {
    create_project dead_air $project_dir -part xc7a35tcpg236-1
    add_files -fileset sources_1 [lsort [glob [file join $source_root rtl *.v]]]
    add_files -fileset constrs_1 [file join $source_root constraints basys3.xdc]
    add_files -fileset sim_1 [lsort [glob [file join $source_root sim *.sv]]]
    set_property top dead_air_top [get_filesets sources_1]
    set_property top tb_dead_air [get_filesets sim_1]
    set_property xsim.simulate.runtime all [get_filesets sim_1]
    update_compile_order -fileset sources_1
    update_compile_order -fileset sim_1
}
puts "Dead Air project: $project_file"
