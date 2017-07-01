// vim: ft=verilog ts=4
//
// Test bench for siacore verification
//

`timescale 1ns/1ns
module tb_siacore();

    /*AUTOWIRE*/
    /*AUTOREG*/
integer wfon;
`ifdef WF
    initial begin
        $dumpfile("waveform.fst");
        $dumpvars(0, tb_siacore);
        if(!$value$plusargs("wfon=%d", wfon)) begin
            wfon = 0;
        end else
            $display($time, " Dump waveform at %d", wfon);
        
        #wfon $dumpon;
        $display($time, " Start to dumping waveform");
    end
`endif

	reg clk;
    initial begin
        clk = 1'b1;
        forever #5 clk = ~clk;
    end

    reg rst;
    initial begin
        rst = 1'b1;
        #30 rst = 1'b0;
    end

    reg [639:0] workData   [0:`VECTORS -1];
    reg [63:0]  targetData [0:`VECTORS -1];
    reg [31:0]  goldenData [0:`VECTORS -1];

    initial begin
        $readmemh("tests/work.dat",     workData);
        $readmemh("tests/target.dat",   targetData);
        $readmemh("tests/nonce.dat",    goldenData);
    end

    // Load data, and set valid
    reg [639:0] work   ;
    reg [63:0]  target ;
    reg [31:0]  golden ;
    reg         valid  ;
    integer addr;
    // Getting data and valid
    initial begin
        // wait for rst to de-assert 
        work    = 640'h0;
        target  = 64'h0;
        golden  = 32'h0;
        valid   = 1'b0;
        addr    = 0;

        while(rst) @(posedge clk);
        // wait for another 100 clk cycles before starting simulation 
        repeat(100) @(posedge clk);

        work    = workData[addr];
        target  = targetData[addr];
        golden  = goldenData[addr];
        valid   = 1'b0;

        @(posedge clk);
        while(addr < `VECTORS) begin
            // Getting new work if nonce is found
            @(posedge clk);
            work    = workData[addr];
            target  = targetData[addr];
            golden  = goldenData[addr];
            work[287:256] = {golden[7:0], golden[15:8], golden[23:16], golden[31:24]} - ({$random} % 10);
            valid   = 1'b1;
            addr    = addr + 1;

            @(posedge clk);
            valid   = 1'b0;

            while(~found)
                @(posedge clk);
        end

        $display("All nonces are found, pass!");
        repeat (10) @(posedge clk);
        $finish;
    end

//    // Force initial nonce just a little smaller than golen
//    always @(/*AUTOSENSE*/) begin
//        if(valid == 1'b1) begin
//            //force tb_siacore.DUT.uLoad.m04 = golden - $random % 10;
//            force tb_siacore.DUT.uLoad.m04 = {golden[7:0], golden[15:8], golden[23:16], golden[31:24]} - ($random % 10);
//        end else begin
//            release tb_siacore.DUT.uLoad.m04;
//        end
//    end

    siacore DUT(/*AUTOINST*/);

    // Overtime of verification
    initial begin
        #3000;
        $display("Simulation Overtime!");
        $finish;
    end
    // Check nonce if found
    always @(negedge clk) begin
        if(found) begin
            if(nonce != golden) begin
                $display("Found nonce: 0x%08X, Golden: 0x%08X ========================= fail!", nonce, golden);
                #50 $finish;
            end else begin
                $display("Found nonce: 0x%08X, golden: 0x%08X ========================= pass!", nonce, golden);
            end
        end
    end

    integer hashcnt;
    initial begin
        hashcnt = 0;
    end
    always @(negedge clk) begin
        if(busy) begin
            $display("Siacore has done %d hash!", hashcnt);
            hashcnt <= hashcnt + 1;
        end
    end

endmodule
