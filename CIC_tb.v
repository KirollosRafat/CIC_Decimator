
`timescale 1ns/1ps

module CIC_tb;

    // Parameters
    parameter INPUTWIDTH = 8;
    parameter D = 4;
    parameter N = 4;
    parameter CLK_FREQ = 6_000_000;   // 6 MHz
    parameter SINE_FREQ = 100_000;    // 100 kHz
    parameter NUM_SAMPLES = 2000;     // total simulation samples

    // Derived parameters
    real CLK_PERIOD = 1e9 / CLK_FREQ;  // ns per clock

    // DUT signals
    reg clk;
    reg rst;
    reg signed [INPUTWIDTH-1:0] d_in;
    wire signed [INPUTWIDTH-1:0] d_out;
    wire d_clk;

    // File handles
    integer xin, xout;

    // DUT instance
    CIC #(.INPUTWIDTH(INPUTWIDTH), .D(D), .N(N)) uut (
        .clk(clk),
        .rst(rst),
        .d_in(d_in),
        .d_out(d_out),
        .d_clk(d_clk)
    );

    // Clock generation (6 MHz)
    always #(CLK_PERIOD/2.0) clk = ~clk;

    // Generate sine wave input
    real t;
    real sine_val;
    real TWO_PI = 6.283185307;
    integer n;

    initial begin
        clk = 0;
        rst = 1;
        d_in = 0;
        t = 0.0;
        #1000;      // wait for 1 us reset
        rst = 0;

        // Open files for writing
        xin  = $fopen("input.txt", "w");
        xout = $fopen("output.txt", "w");
        if (!xin || !xout) begin
            $display("Error opening files!");
            $finish;
        end

        // Generate NUM_SAMPLES samples
        for (n = 0; n < NUM_SAMPLES; n = n + 1) begin
            sine_val = $sin(TWO_PI * SINE_FREQ * t);
            // Scale to signed 8-bit range (-128 to +127)
            d_in = $rtoi(sine_val * 127);
            $fwrite(xin, "%d\n", d_in);

            @(posedge clk);
            t = t + (1.0 / CLK_FREQ);

            // Write decimated output when valid
            if (d_clk)
                $fwrite(xout, "%d\n", d_out);
        end

        $fclose(xin);
        $fclose(xout);
        $display("Simulation completed, data saved to input.txt and output.txt");
        $stop;
    end
endmodule
