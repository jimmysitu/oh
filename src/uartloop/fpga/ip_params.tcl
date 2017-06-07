# NOTE: See UG1118 for more information

set design uartloop
set projdir ./
set root "../.."
set partname "xc7z020clg400-1"

set hdl_files [list \
                $root/uartloop/fpga/build \
              ]

set ip_files   []

set constraints_files []

