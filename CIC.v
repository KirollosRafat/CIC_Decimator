module CIC #(
    parameter INPUTWIDTH = 8,
    parameter N = 4,
    parameter MAX_D = 16,
    parameter REGWIDTH = INPUTWIDTH + (N * $clog2(MAX_D)) 
)(
    input  wire                      clk,
    input  wire                      rst,
    input  wire signed [INPUTWIDTH-1:0] d_in,
    input  wire [$clog2(MAX_D):0]                D,        
    output reg  signed [INPUTWIDTH-1:0] d_out,
    output reg                       d_clk
);

    // Internal registers
    reg signed [REGWIDTH-1:0] d_tmp, d_d_tmp;

    // Integrator stages
    reg signed [REGWIDTH-1:0] d1, d2, d3, d4;

    // Comb stages
    reg signed [REGWIDTH-1:0] d5, d_d5;
    reg signed [REGWIDTH-1:0] d6, d_d6;
    reg signed [REGWIDTH-1:0] d7, d_d7;
    reg signed [REGWIDTH-1:0] d8;

    // Counter for decimation
    reg [$clog2(MAX_D)-1:0] count;

    // Control signals
    reg v_comb;
    reg d_clk_tmp;

    // Integrator + Decimation
    always @(posedge clk) begin
        if (rst) begin
            d1 <= 0; d2 <= 0; d3 <= 0; d4 <= 0;
            count <= 0;
            v_comb <= 0;
        end else begin
            // Cascaded integrators
            d1 <= d_in + d1;
            d2 <= d1 + d2;
            d3 <= d2 + d3;
            d4 <= d3 + d4;

            // Downsampling control
            if (count == (D - 1)) begin
                count <= 0;
                d_tmp <= d4;
                d_clk_tmp <= 1'b1;
                v_comb <= 1'b1;
            end else begin
                count <= count + 1;
                d_clk_tmp <= 1'b0;
                v_comb <= 1'b0;
            end
        end
    end

    // Comb section
    always @(posedge clk) begin
        d_clk <= d_clk_tmp;
        if (rst) begin
            d5 <= 0; d_d5 <= 0;
            d6 <= 0; d_d6 <= 0;
            d7 <= 0; d_d7 <= 0;
            d8 <= 0;
            d_d_tmp <= 0;
            d_out <= 0;
        end else if (v_comb) begin
            d_d_tmp <= d_tmp;

            d5 <= d_tmp - d_d_tmp;
            d_d5 <= d5;

            d6 <= d5 - d_d5;
            d_d6 <= d6;

            d7 <= d6 - d_d6;
            d_d7 <= d7;

            d8 <= d7 - d_d7;

            d_out <= d8 >>> (N * $clog2(D));
        end
    end

endmodule
