// vim:ft=verilog ts=4

module compare(/*AUTOARG*/);
    input   clk;
    input   rst;
    input   valid;

    input   [63:0]    m04;      // varible of message
    input   [63:0]    v0;
    input   [63:0]    v8;
    input   [63:0]    target;   // hash target

    output            found;    // found hash < target
    output            busy;     // busy with hashing
    output  [31:0]    nonce;    // nonce meets target

    wire [63:0] h0;
    wire [63:0] swap8;

    assign h0[63:0]   = 64'h6a09e667f2bdc928 ^ v0 ^ v8;
    assign swap8[63:0] = {h0[7:0], h0[15:8], h0[23:16], h0[31:24], h0[39:32], h0[47:40], h0[55:48], h0[63:56]};

    reg found;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            found <= 1'b0;
        end else if(valid & (swap8 < target)) begin
            found <= 1'b1;
        end else begin
            found <= 1'b0;
        end
    end

    reg [31:0] nonce;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            nonce <= 32'b0;
        end else begin
            nonce <= {m04[7:0], m04[15:8], m04[23:16], m04[31:24]};
        end
    end

    reg busy;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            busy <= 1'b0;
        end else begin
            busy <= valid;
        end
    end

endmodule
