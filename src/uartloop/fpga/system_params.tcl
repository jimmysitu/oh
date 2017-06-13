set_property verilog_define CLK20M [current_fileset]
# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
  create_run -name synth_1 -part xc7z020clg400-1 -flow {Vivado Synthesis 2015} -strategy "Flow_PerfOptimized_High" -constrset constrs_1
} else {
  set_property strategy "Flow_PerfOptimized_High" [get_runs synth_1]
  set_property flow "Vivado Synthesis 2015" [get_runs synth_1]
}
set obj [get_runs synth_1]
set_property "steps.synth_design.args.flatten_hierarchy" "none" $obj
set_property "steps.synth_design.args.fanout_limit" "400" $obj
set_property "steps.synth_design.args.fsm_extraction" "one_hot" $obj
set_property "steps.synth_design.args.keep_equivalent_registers" "1" $obj
set_property "steps.synth_design.args.resource_sharing" "off" $obj
set_property "steps.synth_design.args.no_lc" "1" $obj
set_property "steps.synth_design.args.shreg_min_size" "5" $obj

# set the current synth run
current_run -synthesis [get_runs synth_1]

# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
  create_run -name impl_1 -part xc7z020clg400-1 -flow {Vivado Implementation 2015} -strategy "Performance_ExplorePostRoutePhysOpt" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Performance_ExplorePostRoutePhysOpt" [get_runs impl_1]
  set_property flow "Vivado Implementation 2015" [get_runs impl_1]
}
set obj [get_runs impl_1]
set_property "steps.opt_design.args.directive" "Explore" $obj

set_property "steps.place_design.args.directive" "Explore" $obj
set_property "steps.place_design.tcl.pre" "$projdir/add_overconstrain.tcl" $obj

set_property "steps.phys_opt_design.is_enabled" "1" $obj
set_property "steps.phys_opt_design.args.directive" "Explore" $obj

set_property "steps.route_design.args.directive" "Explore" $obj
set_property "steps.route_design.tcl.pre" "$projdir/remove_overconstrain.tcl" $obj
set_property -name {steps.route_design.args.more options} -value {-tns_cleanup} -objects $obj

set_property "steps.post_route_phys_opt_design.is_enabled" "1" $obj
set_property "steps.post_route_phys_opt_design.args.directive" "Explore" $obj
set_property "steps.write_bitstream.args.readback_file" "0" $obj
set_property "steps.write_bitstream.args.verbose" "0" $obj

# set the current impl run
current_run -implementation [get_runs impl_1]

