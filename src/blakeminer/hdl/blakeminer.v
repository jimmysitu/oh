/* blakeminer.v copyright kramble 2013
 * Based on https://github.com/teknohog/Open-Source-FPGA-Bitcoin-Miner/tree/master/projects/Xilinx_cluster_cgminer
 * Hub code for a cluster of miners using async links
 * by teknohog
 */

module blakeminer (/*AUTOARG*/);

function integer clog2;         // Courtesy of razorfishsl, replaces $clog2()
    input integer value;
    begin
        value = value-1;
        for (clog2=0; value>0; clog2=clog2+1)
            value = value>>1;
    end
endfunction


`ifdef SERIAL_CLK
    parameter comm_clk_frequency = `SERIAL_CLK;
`else
    parameter comm_clk_frequency = 12_500_000;              // 100MHz divide 8
`endif

`ifdef BAUD_RATE
    parameter BAUD_RATE = `BAUD_RATE;
`else
    parameter BAUD_RATE = 115_200;
`endif

// kramble - nonce distribution is crude using top 3 bits of nonce so max LOCAL_MINERS = 4
// teknohog's was more sophisticated, but requires modification of hashcore.v

// Miners on the same FPGA with this hub
`ifdef LOCAL_MINERS
    parameter LOCAL_MINERS = `LOCAL_MINERS;
`else
    parameter LOCAL_MINERS = 1;                                             // One to four cores
`endif

// kramble - nonce distribution only works for a single external port 
`ifdef EXT_PORTS
    parameter EXT_PORTS = `EXT_PORTS;
`else
    parameter EXT_PORTS = 1;
`endif

    localparam SLAVES = LOCAL_MINERS + EXT_PORTS;

    input hash_clk;
    input uart_clk;
    input nreset;

    input   RxD;
    output  TxD;
    output  led;
        
    output [EXT_PORTS-1:0] extminer_txd;
    input [EXT_PORTS-1:0]  extminer_rxd;

    wire nonce_chip;
    assign nonce_chip = 1'b0;             // Distinguishes between the two Icarus FPGA's

    // Results from the input buffers (in serial_hub.v) of each slave
    wire [SLAVES*32-1:0]    slave_nonces;
    wire [SLAVES-1:0]       new_nonces;

    // Using the same transmission code as individual miners from serial.v
    wire            serial_send;
    wire            serial_busy;
    wire [31:0]     golden_nonce;

    serial_transmit #(
        .comm_clk_frequency(comm_clk_frequency), 
        .baud_rate(BAUD_RATE)
    ) sertx (
        .clk(uart_clk), 
        .TxD(TxD), 
        .send(serial_send), 
        .busy(serial_busy), 
        .word(golden_nonce)
    );

    hub_core #(
        .SLAVES(SLAVES)
    ) hc (
        .uart_clk(uart_clk), 
        .new_nonces(new_nonces), 
        .golden_nonce(golden_nonce), 
        .serial_send(serial_send), 
        .serial_busy(serial_busy), 
        .slave_nonces(slave_nonces)
    );

    // Common workdata input for local miners
    wire [255:0]    data1;                  // midstate
    wire [127:0]    data2;
    wire [31:0]     target;
    reg  [31:0]     targetreg = 32'h000007ff;   // NB Target is only use to set clock speed in BLAKE
    wire            rx_done;                    // Signals hashcore to reset the nonce
    // NB in my implementation, it loads the nonce from data2 which should be fine as
    // this should be zero, but also supports testing using non-zero nonces.

    // Synchronise across clock domains from uart_clk to hash_clk
    // This probably looks amateurish (mea maxima culpa, novice verilogger at work), but should be OK
    reg rx_done_toggle = 1'b0;              // uart_clk domain
    always @ (posedge uart_clk)
        rx_done_toggle <= rx_done_toggle ^ rx_done;

    reg rx_done_toggle_d1 = 1'b0;   // hash_clk domain
    reg rx_done_toggle_d2 = 1'b0;
    reg rx_done_toggle_d3 = 1'b0;

    wire loadnonce;
    assign loadnonce = rx_done_toggle_d3 ^ rx_done_toggle_d2;

    always @ (posedge hash_clk)
    begin
        rx_done_toggle_d1 <= rx_done_toggle;
        rx_done_toggle_d2 <= rx_done_toggle_d1;
        rx_done_toggle_d3 <= rx_done_toggle_d2;
        if (loadnonce)
            targetreg <= target;
    end
    // End of clock domain sync

        
    serial_receive #(
        .comm_clk_frequency(comm_clk_frequency),
        .baud_rate(BAUD_RATE)
    ) serrx (
        .clk(uart_clk),
        .RxD(RxD),
        .data1(data1),
        .data2(data2),
        .target(target), 
        .rx_done(rx_done)
    );

    reg [255:0]     data1sr;                   // midstate
    reg [127:0]     data2sr;
    wire din = data1sr[255];
    reg shift = 0;
    reg [11:0] shift_count = 0;
    reg [15:0] allones;                        // Fudge to ensure ISE does NOT optimise the shift registers re-creating the huge global
                                               // buses that are unroutable. Its probably not needed, but I just want to be sure
    
                                               
    always @ (posedge hash_clk)
    begin
        shift <= (shift_count != 0);
        if (shift_count != 0)
            shift_count <= shift_count + 1;
        if (loadnonce)
        begin
            data1sr <= data1;
            data2sr <= data2;
            shift_count <= shift_count + 1;
        end
        else if (shift)
        begin
            data1sr <= { data1sr[254:0], data2sr[127] };
            data2sr <= { data2sr[126:0], 1'b0 };
        end
        if (shift_count == 384)
            shift_count <= 0;
        allones <= { allones[14:0], targetreg[31] | ~targetreg[30] | targetreg[23] | ~targetreg[22] };  // Fudge
    end
        
    // Local miners now directly connected
    generate
        genvar i;
        for (i = 0; i < LOCAL_MINERS; i = i + 1)
        begin: miners
            wire [31:0] nonce_out;  // Not used
            wire [1:0] nonce_core = i;
            wire gn_match;

`ifdef SIM
            hashcore M (hash_clk, din & allones[i], shift, 3'd7, nonce_out,         // Fixed 111 prefix in SIM to match genesis block
                        slave_nonces[i*32+31:i*32], gn_match, loadnonce);
`else                                                   
            hashcore M (hash_clk, din & allones[i], shift, {nonce_chip, nonce_core}, nonce_out,
                        slave_nonces[i*32+31:i*32], gn_match, loadnonce);
`endif                          
            // Synchronise across clock domains from hash_clk to uart_clk for: assign new_nonces[i] = gn_match;
            reg gn_match_toggle = 1'b0;             // hash_clk domain
            always @ (posedge hash_clk)
                gn_match_toggle <= gn_match_toggle ^ gn_match;

            reg gn_match_toggle_d1 = 1'b0;  // uart_clk domain
            reg gn_match_toggle_d2 = 1'b0;
            reg gn_match_toggle_d3 = 1'b0;

            assign new_nonces[i] = gn_match_toggle_d3 ^ gn_match_toggle_d2;

            always @ (posedge uart_clk)
            begin
                gn_match_toggle_d1 <= gn_match_toggle;
                gn_match_toggle_d2 <= gn_match_toggle_d1;
                gn_match_toggle_d3 <= gn_match_toggle_d2;
            end
            // End of clock domain sync
        end // for
    endgenerate

    
    assign extminer_txd = {EXT_PORTS{RxD}};
    generate
        genvar j;
        for (j = LOCAL_MINERS; j < SLAVES; j = j + 1)
        begin: ports
            slave_receive #(
                .comm_clk_frequency(comm_clk_frequency), .baud_rate(BAUD_RATE)
            ) slrx (
                .clk(uart_clk), .RxD(extminer_rxd[j-LOCAL_MINERS]), .nonce(slave_nonces[j*32+31:j*32]), .new_nonce(new_nonces[j])
            );
        end
    endgenerate

    // Light up only from locally found nonces, not ext_port results
    pwm_fade pf (.clk(uart_clk), .trigger(|new_nonces[LOCAL_MINERS-1:0]), .drive(led));
   
endmodule
