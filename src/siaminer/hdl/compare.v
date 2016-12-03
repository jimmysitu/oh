// vim:ft=verilog ts=4

module compare(/*AUTOARG*/
   // Outputs
   done, found,
   // Inputs
   clk, rst, v0, v8, target
   );
    input   clk;
    input   rst;

    input   [63:0]    v0;
    input   [63:0]    v8;
    input   [31:0]    target;   // hash target
    
    output            done;     // hash is done
    output            found;    // found hash < target

    wire [63:0] h0;
    wire [63:0] swap;

    assign h0[63:0]   = 64'h6a09e667f2bdc928 ^ v0 ^ v8;
    assign swap[63:0] = {h0[7:0], h0[15:8], h0[23:16], h0[31:24], h0[39:32], h0[47:40], h0[55:48], h0[63:56]};
    
    assign found = (swap < target);
endmodule
