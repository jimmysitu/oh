//---------------------------------------------------------------------------------------
// uart to internal bus top module 
//
//---------------------------------------------------------------------------------------

module uart2core(/*AUTOARG*/);

input clk;
input rst;
/*AUTOINPUT*/
/*AUTOOUTPUT*/

// baud rate configuration, see baud_gen.v for more details.
`ifdef FAST_SIM
    // baud rate generator parameters for 115200 baud on 10MHz clock 
    `define D_BAUD_FREQ         12'h240
    `define D_BAUD_LIMIT        16'h09F5
`elsif CLK20M
    // baud rate generator parameters for 115200 baud on 20MHz clock 
    `define D_BAUD_FREQ         12'h120
    `define D_BAUD_LIMIT        16'hB15
`elsif CLK25M
    // baud rate generator parameters for 115200 baud on 25MHz clock 
    `define D_BAUD_FREQ         12'h480
    `define D_BAUD_LIMIT        16'h3889
`elsif CLK30M
    // baud rate generator parameters for 115200 baud on 30MHz clock 
    `define D_BAUD_FREQ         12'hC0
    `define D_BAUD_LIMIT        16'hB75
`elsif CLK33M
    // baud rate generator parameters for 115200 baud on 33MHz clock 
    `define D_BAUD_FREQ         12'h180
    `define D_BAUD_LIMIT        16'h195B
`elsif CLK35M
    // baud rate generator parameters for 115200 baud on 35MHz clock 
    `define D_BAUD_FREQ         12'h480
    `define D_BAUD_LIMIT        16'h50F3
`elsif CLK40M
    // baud rate generator parameters for 115200 baud on 40MHz clock 
    `define D_BAUD_FREQ         12'h90
    `define D_BAUD_LIMIT        16'hBA5
`elsif CLK50M
    // baud rate generator parameters for 115200 baud on 50MHz clock 
    `define D_BAUD_FREQ         12'h240
    `define D_BAUD_LIMIT        16'h3AC9
`elsif CLK100M
    // baud rate generator parameters for 115200 baud on 100MHz clock 
    `define D_BAUD_FREQ         12'h120
    `define D_BAUD_LIMIT        16'h3BE9
`else
    // baud rate generator parameters for 115200 baud on 20MHz clock 
    `define D_BAUD_FREQ         12'h120
    `define D_BAUD_LIMIT        16'hB15
`endif

// internal wires 
wire    [7:0]   tx_data;        // data byte to transmit 
wire            new_tx_data;    // asserted to indicate that there is a new data byte for transmission 
wire            tx_busy;        // signs that transmitter is busy 
wire    [7:0]   rx_data;        // data byte received 
wire            new_rx_data;    // signs that a new byte was received 
wire    [11:0]  baud_freq;
wire    [15:0]  baud_limit;
wire            baud_clk;

/*AUTOWIRE*/
/*AUTOREG*/

// assign baud rate default values
assign baud_freq = `D_BAUD_FREQ;
assign baud_limit = `D_BAUD_LIMIT;

//---------------------------------------------------------------------------------------
// module implementation
// uart top module instance
uart_top uUart(
    .clock(clk),
    .reset(rst),
    /*AUTOINST*/);

// uart parser instance
uart_parser uParser(
    .clock(clk),
    .reset(rst),
    /*AUTOINST*/);

endmodule

