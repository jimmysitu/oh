// vim: ft=verilog ts=4
//
// Test bench for uartloop verification
//

`timescale 1ns/1ns
module tb_uartloop();
//---------------------------------------------------------------------------------------
// include uart tasks 
`include "uart_tasks.vh" 

/*AUTOWIRE*/
/*AUTOREG*/

integer wfon;
`ifdef WF
    initial begin
        $dumpfile("waveform.fst");
        $dumpvars(0, tb_uartloop);
        if(!$value$plusargs("wfon=%d", wfon)) begin
            wfon = 0;
        end else
            $display($time, " Dump waveform at %d", wfon);
        
        #wfon $dumpon;
        $display($time, " Start to dumping waveform");
    end
`endif

    // internal signal  
    reg clk;        // global clock 
    reg rst;        // global reset 

    reg [639:0] workData   [0:`VECTORS -1];
    reg [63:0]  targetData [0:`VECTORS -1];
    reg [31:0]  goldenData [0:`VECTORS -1];

    reg found;
    reg [31:0] nonce;

    initial begin
        $readmemh("tests/work.dat",     workData);
        $readmemh("tests/target.dat",   targetData);
        $readmemh("tests/nonce.dat",    goldenData);
    end

    // test bench implementation 
    initial begin
        rst = 1;
        #200 rst = 0;
    end 

`ifdef FAST_SIM
    // 10MHz clk
    initial begin
        clk = 1'b1;
        forever #50 clk = ~clk;
    end
`elsif CLK20M
    initial begin
        clk = 1'b1;
        forever #25 clk = ~clk;
    end
`elsif CLK30M
    initial begin
        clk = 1'b1;
        forever #16 clk = ~clk;
    end
`elsif CLK33M
    initial begin
        clk = 1'b1;
        forever #15 clk = ~clk;
    end
`elsif CLK35M
    initial begin
        clk = 1'b1;
        forever #14.25 clk = ~clk;
    end
`elsif CLK40M
    initial begin
        clk = 1'b1;
        forever #12.5 clk = ~clk;
    end
`elsif CLK50M
    initial begin
        clk = 1'b1;
        forever #10 clk = ~clk;
    end
`elsif CLK100M
    initial begin
        clk = 1'b1;
        forever #5 clk = ~clk;
    end
`else
    initial begin
        clk = 1'b1;
        forever #5 clk = ~clk;
    end
`endif

    // Overtime of verification
    initial begin
        #50000000 $display($time, " Overtime!");
        $finish;
    end

    // Load data, and set valid
    reg [639:0] work   ;
    reg [63:0]  target ;
    reg [31:0]  golden ;
    integer addr;
    // Getting data and valid
    always @(posedge clk) begin
        if(rst == 1'b1) begin
            work    <= 640'h0;
            target  <= 32'h0;
            golden  <= 32'h0;
            addr    <= 0;
        end else if(found) begin
            // Getting new work if nonce is found
            work    <= workData[addr];
            target  <= targetData[addr];
            golden  <= goldenData[addr];
            addr    <= addr + 1;
        end else begin
            // No busy and found, keep send the same data
            work    <= workData[addr];
            target  <= targetData[addr];
            golden  <= goldenData[addr];
            addr    <= addr;
        end
    end

    // test bench transmitter and receiver 
    // uart transmit
    reg [7:0] tx_cmd;
    reg [7:0] tx_len;
    reg [671:0] tx_data;
    reg [7:0] tx_byte;

    reg [7:0] rx_cmd;
    reg [7:0] rx_len;
    reg [31:0] rx_data;



    initial begin 
        // defualt value of serial output 
        serial_out = 1;
        // wait for rst to de-assert 
        while (rst) @ (posedge clk);
        // wait for another 100 clk cycles before starting simulation 
        repeat (100) @ (posedge clk);

        // binary mode simulation 
        $display($time, " Starting simulation");

        // ============== loop test ================
        $display($time, " Sending test command");
        tx_cmd = 8'h1;
        tx_len = 8'h1;
        // transmit command, header, cmd, len, data
        send_serial(8'hAA, `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0);
        send_serial(tx_cmd, `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0);
        send_serial(tx_len, `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0);
        tx_byte = {$random};
        send_serial(tx_byte, `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0);
        $display($time, " Sent test command" );

        // ================ work test ================
        @(posedge clk);
        $display($time, " Sending work command");
        $display($time, " Sending work in address 0x%d", addr);
        tx_cmd = 8'h0;
        tx_len = 8'h1;
        tx_len = 8'd84;
        tx_data = {target, work};
        tx_data[287:256] = {golden[7:0], golden[15:8], golden[23:16], golden[31:24]} - ({$random} % 10);
        $display($time, " Adjust nonce to 0x%08x", tx_data[287:256]);

        // transmit command, header, cmd, len, data
        send_serial(8'hAA, `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0);
        send_serial(tx_cmd, `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0);
        send_serial(tx_len, `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0);
        while (tx_len > 0) begin
            if(tx_cmd == 8'h0) begin
                tx_byte = tx_data[7:0];
                tx_data = tx_data >> 8;
                send_serial(tx_byte, `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0);
            end
            tx_len = tx_len - 1'b1;
        end
        $display("Sent work command" );

        if(tx_cmd == 8'h0) begin
            while(~found)
                @(posedge clk);
        end

        // delay and finish 
        $display($time, " All nonces are found, pass!");
        #500 $finish;
    end

    // uart receive 
    initial begin 
        // default value for serial receiver and serial input 
        serial_in = 1;
        get_serial_data = 0;        // data received from get_serial task 
        get_serial_status = 0;      // status of get_serial task  
        found = 1'b0;
    end 

    // serial sniffer loop
    always begin
        // call serial sniffer
        get_serial(`BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8);

        // check serial receiver status
        if (get_serial_status & `RECEIVE_RESULT_OK) begin
            if (get_serial_data == 8'h55) begin
                // get cmd
                get_serial(`BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8);
                rx_cmd = get_serial_data;

                // get len
                get_serial(`BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8);
                rx_len = get_serial_data;

                // get data
                while(rx_len > 0) begin
                    get_serial(`BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8);
                    if(rx_cmd == 8'h00)
                        nonce = {get_serial_data, nonce[31:8]};
                    if(rx_cmd == 8'h01) begin
                        $display($time, " Loop_test: Loop Ack: 0x%02X", get_serial_data);
                    end
                    rx_len = rx_len - 8'h1;
                end

                // check if nonce == target, which means loop test ack
                if(rx_cmd == 8'h00) begin
                    if(nonce == target) begin
                        $display($time, " Found nonce: 0x%08X, golden: 0x%08X", nonce, golden);
                        // Next vector
                        @(posedge clk) found <= 1'b1;
                        @(posedge clk) found <= 1'b0;
                    end else begin
                        $display($time, " Nonce: 0x%08X != Golden: 0x%08X, fail!", nonce, golden);
                        #100 $finish;
                    end
                end
            end
        end
    end

    always @(*) begin
        // false start error
        if (get_serial_status & `RECEIVE_RESULT_FALSESTART)
            $display("Error (get_char): false start condition at %t", $realtime);

        // bad parity error
        if (get_serial_status & `RECEIVE_RESULT_BADPARITY)
            $display("Error (get_char): bad parity condition at %t", $realtime);

        // bad stop bits sequence
        if (get_serial_status & `RECEIVE_RESULT_BADSTOP)
            $display("Error (get_char): bad stop bits sequence at %t", $realtime);
    end

    // serial interface to test bench 
    assign ser_in = serial_out;
    always @(posedge clk) serial_in = ser_out;

    // DUT instance 
    uartloop DUT(
        .work(),
        /*AUTOINST*/);

    // internal status monitors
    always @(negedge clk) begin
        if(tb_uartloop.DUT.uUart2core.new_rx_data) begin
            $display($time, " DUT got new byte");
        end
        if(tb_uartloop.DUT.uUart2core.new_tx_data) begin
            $display($time, " DUT sent new byte");
        end
        if(tb_uartloop.DUT.uUart2core.uParser.rx_last_byte 
            && tb_uartloop.DUT.uUart2core.uParser.new_rx_data) begin
            $display($time, " DUT got a new command");
        end
        if(tb_uartloop.DUT.uUart2core.uParser.tx_last_byte
            && tb_uartloop.DUT.uUart2core.uParser.new_tx_data) begin
            $display($time, " DUT sent new command");
        end
    end

endmodule
//---------------------------------------------------------------------------------------
//                      Th.. Th.. Th.. Thats all folks !!!
//---------------------------------------------------------------------------------------
