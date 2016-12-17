// vim: ft=verilog ts=4
//
// Test bench for siaminer verification
//

`timescale 1ns/1ns
module tb_siaminer();
//---------------------------------------------------------------------------------------
// include uart tasks 
`include "uart_tasks.vh" 

/*AUTOWIRE*/
/*AUTOREG*/
`ifdef VCD
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_siaminer);
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
    // 100MHz clk
    initial begin
        clk = 1'b1;
        forever #50 clk = ~clk;
    end
`else
    // 100MHz clk
    initial begin
        clk = 1'b1;
        forever #5 clk = ~clk;
    end
`endif

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


    // Overtime of verification
    initial begin
        #1000000000 $finish;
    end

    initial begin 
        // defualt value of serial output 
        serial_out = 1;
        // wait for rst to de-assert 
        while (rst) @ (posedge clk);
        // wait for another 100 clk cycles before starting simulation 
        repeat (100) @ (posedge clk);

        // binary mode simulation 
        $display("Starting simulation");

        // loop test
        $display("Sending test command");
        tx_cmd = 8'h1;
        tx_len = 8'h1;
        // transmit command, header, cmd, len, data
        send_serial(8'hAA, `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0);
        send_serial(tx_cmd, `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0);
        send_serial(tx_len, `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0);
        tx_byte = {$random};
        send_serial(tx_byte, `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0);
        $display("Sent test command" );

        // work test
        $display("Sending work command");
        tx_cmd = 8'h0;
        tx_len = 8'h1;
        tx_len = 8'd84;
        tx_data = {target, work};

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


        // regression test
        while(addr < `VECTORS) begin
            tx_cmd = {$random} % 2;
            if(tx_cmd == 8'h0) begin
                $display("Sending work command" );
                tx_len = 8'd84;
                tx_data = {target, work};
                tx_data[287:256] = {golden[7:0], golden[15:8], golden[23:16], golden[31:24]} - ({$random} % 10);
            end else if(tx_cmd == 8'h1) begin
                $display("Sending loop test command" );
                tx_len = 8'h1;
            end else begin
                $display("Unknown command: %d", tx_cmd);
            end

            // transmit command, header, cmd, len, data
            send_serial(8'hAA, `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0);
            send_serial(tx_cmd, `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0);
            send_serial(tx_len, `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0);
            while (tx_len > 0) begin
                if(tx_cmd == 8'h1) begin
                    tx_byte = {$random};
                    send_serial(tx_byte, `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0);
                    $display("loop_test: Loop Data: 0x%02X", tx_byte);
                end else if(tx_cmd == 8'h0) begin
                    tx_byte = tx_data[7:0];
                    tx_data = tx_data >> 8;
                    send_serial(tx_byte, `BAUD_115200, `PARITY_EVEN, `PARITY_OFF, `NSTOPS_1, `NBITS_8, 0); 
                end
                tx_len = tx_len - 1'b1;
            end
            $display("Sent command");

            // wait nonce found if work cmd is sent
            if(tx_cmd == 8'h0) begin
                while(~found);
            end
        end

        // delay and finish 
        $display("All nonces are found, pass!");
        #500 $finish;
    end

    always @(/*AUTOSENSE*/) begin
        if(tb_siaminer.DUT.uSiacore.uLoad.valid) begin
            force tb_siaminer.DUT.uSiacore.uLoad.m04 = {golden[7:0], golden[15:8], golden[23:16], golden[31:24]} - ({$random} % 10);
        end else begin
            release tb_siaminer.DUT.uSiacore.uLoad.m04;
        end
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
                        $display("loop_test: Loop Ack: 0x%02X", get_serial_data);
                    end
                    rx_len = rx_len - 8'h1;
                end

                // check nonce
                if(rx_cmd == 8'h00)begin
                    if(nonce == golden)
                        $display("Found nonce: 0x%08X, golden: 0x%08X", nonce, golden);
                    else begin
                        $display("Nonce: 0x%08X != Golden: 0x%08X, fail!", nonce, golden);
                        #10 $finish;
                    end
                    // Next vector
                    @(posedge clk) found <= 1'b1;
                    @(posedge clk) found <= 1'b0;
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
    siaminer DUT(/*AUTOINST*/);

    // internal status monitors
    always @(negedge clk) begin
        if(tb_siaminer.DUT.uSiacore.uLoad.valid) begin
            $display("Siacore get new work:");
            $display("0x%016X", tb_siaminer.DUT.uSiacore.uLoad.work[  63:    0]);
            $display("0x%016X", tb_siaminer.DUT.uSiacore.uLoad.work[ 127:   64]);
            $display("0x%016X", tb_siaminer.DUT.uSiacore.uLoad.work[ 191:  128]);
            $display("0x%016X", tb_siaminer.DUT.uSiacore.uLoad.work[ 255:  192]);
            $display("0x%016X", tb_siaminer.DUT.uSiacore.uLoad.work[ 319:  256]);
            $display("0x%016X", tb_siaminer.DUT.uSiacore.uLoad.work[ 383:  320]);
            $display("0x%016X", tb_siaminer.DUT.uSiacore.uLoad.work[ 447:  384]);
            $display("0x%016X", tb_siaminer.DUT.uSiacore.uLoad.work[ 511:  448]);
            $display("0x%016X", tb_siaminer.DUT.uSiacore.uLoad.work[ 575:  512]);
            $display("0x%016X", tb_siaminer.DUT.uSiacore.uLoad.work[ 639:  576]);
            $display("Siacore get new target:");
            $display("0x%08X", tb_siaminer.DUT.uSiacore.uCompare.target);
        end
    end
    
    always @(negedge clk) begin
        if(tb_siaminer.DUT.uUart2core.new_rx_data) begin
            $display("DUT got new byte");
        end
        if(tb_siaminer.DUT.uUart2core.new_tx_data) begin
            $display("DUT sent new byte");
        end
        if(tb_siaminer.DUT.uUart2core.uParser.rx_last_byte 
            && tb_siaminer.DUT.uUart2core.uParser.new_rx_data) begin
            $display("DUT got a new command");
        end
        if(tb_siaminer.DUT.uUart2core.uParser.tx_last_byte
            && tb_siaminer.DUT.uUart2core.uParser.new_tx_data) begin
            $display("DUT sent new command");
        end
    end

endmodule
//---------------------------------------------------------------------------------------
//                      Th.. Th.. Th.. Thats all folks !!!
//---------------------------------------------------------------------------------------
