module pipe(/*AUTOARG*/);
    input clk;
    input rst;
    input found;

    input vldIn;
    input   [63:0]    m04In;

    output vldOut;
    output  [63:0]    m04Out;

    /*AUTOWIRE*/
    /*AUTOREG*/
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            vldOut <= 1'b0;
            m04Out <= 64'b0;
        end else if(found) begin
            // clean pipeline when nonce found
            vldOut <= 1'b0;
            m04Out <= 64'b0;
        end else begin
            vldOut <= vldIn;
            m04Out <= m04In;
        end
    end

endmodule

