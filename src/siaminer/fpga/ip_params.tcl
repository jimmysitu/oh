# NOTE: See UG1118 for more information

set design siaminer
set projdir ./
set root "../.."
set partname "xc7z020clg400-1"

set hdl_files [list \
                $root/siaminer/fpga/build \
              ]

set ip_files   []

set constraints_files []

set_property value ACTIVE_HIGH [ipx::get_bus_parameters POLARITY -of_objects [ipx::get_bus_interfaces rst -of_objects [ipx::current_core]]]
