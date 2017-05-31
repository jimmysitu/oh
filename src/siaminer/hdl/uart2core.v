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
`else
    // baud rate generator parameters for 115200 baud on 50MHz clock 
    `define D_BAUD_FREQ         12'h240
    `define D_BAUD_LIMIT        16'h3AC9
`endif
// baud rate generator parameters for 115200 baud on 100MHz clock 
//`define D_BAUD_FREQ         12'h120
//`define D_BAUD_LIMIT        16'h3BE9
// baud rate generator parameters for 115200 baud on 40MHz clock 
//`define D_BAUD_FREQ         12'h90
//`define D_BAUD_LIMIT        16'h0BA5
// baud rate generator parameters for 115200 baud on 44MHz clock 
// `define D_BAUD_FREQ          12'd23
// `define D_BAUD_LIMIT     16'd527
// baud rate generator parameters for 9600 baud on 66MHz clock 
//`define D_BAUD_FREQ       12'h10
//`define D_BAUD_LIMIT      16'h1ACB

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

