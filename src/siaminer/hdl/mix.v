// vim:ft=verilog ts=4

module mix(/*AUTOARG*/);
    input   clk;
    input   rst;

    input   [63:0]  aIn;
    input   [63:0]  bIn;
    input   [63:0]  cIn;
    input   [63:0]  dIn;

    input   [63:0]  xIn;
    input   [63:0]  yIn;

    output  [63:0]  aOut;
    output  [63:0]  bOut;
    output  [63:0]  cOut;
    output  [63:0]  dOut;

    /*AUTOWIRE*/
    /*AUTOREG*/
    
    reg [63:0] a0, a4;
    reg [63:0] b2, b3, b6, b7;
    reg [63:0] c2, c6;
    reg [63:0] d0, d1, d4, d5;

    always @(/*AUTOSENSE*/) begin
        // Step0: Va = Va + Vb + x
        a0[63:0] = aIn[63:0] + bIn[63:0] + xIn[63:0];

        // Step1: Vd = (Vd xor Va) ror 32
        d0[63:0] = dIn[63:0] ^ a0[63:0];
        d1[63:0] = {d0[31:0], d0[63:32]};

        // Step2: Vc = Vc + Vd
        c2[63:0] = cIn[63:0] + d1[63:0];

        // Step3: Vb = (Vb xor Vc) ror 24
        b2[63:0] = bIn[63:0] ^ c2[63:0];
        b3[63:0] = {b2[23:0], b2[63:24]};

        // Step4: Va = Va + Vb + y
        a4[63:0] = a0[63:0] + b3[63:0] + yIn[63:0];

        // Step5: Vd = (Vd xor Va) ror 16
        d4[63:0] = d1[63:0] ^ a4[63:0];
        d5[63:0] = {d4[15:0], d4[63:16]};

        // Step6: Vc = Vc + Vd
        c6[63:0] = c2[63:0] + d5[63:0];

        // Step7: Vb = (Vb xor Vc) ror 63
        b6[63:0] = b3[63:0] ^ c6[63:0];
        b7[63:0] = {b6[62:0], b6[63]};
    end

    assign aOut[63:0] = a4[63:0];
    assign bOut[63:0] = b7[63:0];
    assign cOut[63:0] = c6[63:0];
    assign dOut[63:0] = d5[63:0];

endmodule

