
#STEP1: DEFINE KEY PARAMETERS
source ./system_params.tcl

#STEP2: CREATE PROJECT AND READ IN FILES
source ../../../common/fpga/system_init.tcl

#STEP 3 (OPTIONAL): EDIT system.bd in VIVADO gui, then go to STEP 4.
##...

#STEP 3A PROJECT SETTING
set_property verilog_define [list [get_property verilog_define [current_fileset]] CLK20M] [current_fileset]

# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
  create_run -name synth_1 -part xc7z020clg400-1 -flow {Vivado Synthesis 2015} -strategy "Flow_PerfOptimized_High" -constrset constrs_1
} else {
  set_property strategy "Flow_PerfOptimized_High" [get_runs synth_1]
  set_property flow "Vivado Synthesis 2015" [get_runs synth_1]
}

# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
  create_run -name impl_1 -part xc7z020clg400-1 -flow {Vivado Implementation 2015} -strategy "Performance_ExplorePostRoutePhysOpt" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Performance_ExplorePostRoutePhysOpt" [get_runs impl_1]
  set_property flow "Vivado Implementation 2015" [get_runs impl_1]
}
set obj [get_runs impl_1]
set_property "needs_refresh" "1" $obj
set_property "part" "xc7z020clg400-1" $obj
set_property "steps.opt_design.args.directive" "Explore" $obj
set_property "steps.place_design.args.directive" "Explore" $obj
set_property "steps.phys_opt_design.is_enabled" "1" $obj
set_property "steps.phys_opt_design.args.directive" "Explore" $obj
set_property "steps.route_design.args.directive" "Explore" $obj
set_property -name {steps.route_design.args.more options} -value {-tns_cleanup} -objects $obj
set_property "steps.post_route_phys_opt_design.is_enabled" "1" $obj
set_property "steps.post_route_phys_opt_design.args.directive" "Explore" $obj
set_property "steps.write_bitstream.args.readback_file" "0" $obj
set_property "steps.write_bitstream.args.verbose" "0" $obj

#STEP 4: SYNTEHSIZE AND CREATE BITSTRAM
source ../../../common/fpga/system_build.tcl
