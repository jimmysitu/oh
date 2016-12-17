// vim: ft=verilog ts=4
//
// Test bench for siacore verification
//

`timescale 1ns/1ns
module tb_siacore();

    /*AUTOWIRE*/
    /*AUTOREG*/
`ifdef VCD
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_siacore);
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
    always @(posedge clk) begin
        if(rst == 1'b1) begin
            work    <= 640'h0;
            target  <= 32'h0;
            golden  <= 32'h0;
            valid   <= 1'b0;
            addr    <= 0;
        end else if(busy) begin
            // Wait when siacore is doing its job
            work    <= workData[addr];
            target  <= targetData[addr];
            golden  <= goldenData[addr];
            valid   <= 1'b0;
            addr    <= addr;
        end else if(found) begin
            // Getting new work if nonce is found
            work    <= workData[addr];
            target  <= targetData[addr];
            golden  <= goldenData[addr];
            valid   <= 1'b1;
            addr    <= addr + 1;
        end else begin
            // No busy and found, keep send the same data
            work    <= workData[addr];
            target  <= targetData[addr];
            golden  <= goldenData[addr];
            valid   <= 1'b1;
            addr    <= addr;
        end
    end

    // Force initial nonce just a little smaller than golen
    always @(/*AUTOSENSE*/) begin
        if(valid == 1'b1) begin
            //force tb_siacore.DUT.uLoad.m04 = golden - $random % 10;
            force tb_siacore.DUT.uLoad.m04 = {golden[7:0], golden[15:8], golden[23:16], golden[31:24]} - ($random % 10);
        end else begin
            release tb_siacore.DUT.uLoad.m04;
        end
    end

    siacore DUT(/*AUTOINST*/);

    // Overtime of verification
    initial begin
        #1000 $finish;
    end
    // Check nonce if found
    always @(negedge clk) begin
        if(found) begin
            $display("Found nonce: 0x%08X, golden: 0x%08X", nonce, golden);
            if(nonce != golden) begin
                $display("Nonce: 0x%08X != Golden: 0x%08X, fail!", nonce, golden);
                #5 $finish;
            end
        end else begin
            if(addr >= `VECTORS) begin
                $display("All nonces are found, pass!");
                #5 $finish;
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
