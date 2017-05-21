create_clock -period 3.333 -name rxi_lclk_p -waveform {0.000 1.667} [get_ports rxi_lclk_p]

# Set false path
set_false_path -from [get_clocks tx_lclk* ] -to [get_clocks clk_fpga_0]
set_false_path -from [get_clocks rx_lclk* ] -to [get_clocks clk_fpga_0]
set_false_path -from [get_clocks clk_fpga_0] -to [get_clocks tx_lclk*]
set_false_path -from [get_clocks clk_fpga_0] -to [get_clocks rx_lclk*]
set_false_path -from [get_clocks rx_lclk* ] -to [get_clocks tx_lclk*]
set_false_path -from [get_clocks tx_lclk* ] -to [get_clocks rx_lclk*]


