`timescale 1ns/1ps

module tb_CIC;

    // === Parameters ===
    parameter INPUTWIDTH = 8;
    parameter N = 4;
    parameter MAX_D = 16;
    parameter CLK_PERIOD = 10;   // 100 MHz clock
    parameter REGWIDTH = INPUTWIDTH + (N * $clog2(MAX_D));

    // === DUT signals ===
    reg clk;
    reg rst;
    reg signed [INPUTWIDTH-1:0] d_in;
    reg [$clog2(MAX_D):0] D;
    wire signed [INPUTWIDTH-1:0] d_out;
    wire d_clk;

    // === Instantiate the DUT ===
    CIC #(
        .INPUTWIDTH(INPUTWIDTH),
        .N(N),
        .MAX_D(MAX_D),
        .REGWIDTH(REGWIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .d_in(d_in),
        .D(D),
        .d_out(d_out),
        .d_clk(d_clk)
    );

    // === Clock generation (100 MHz) ===
    always #(CLK_PERIOD/2) clk = ~clk;

    // === File I/O ===
    integer infile, outfile;
    integer scan_status;
    integer sample_count;

    // === Main Test Process ===
    initial begin
        clk = 0;
        rst = 1;
        d_in = 0;
        D = 8;                  
        sample_count = 0;

        // --- Open files ---
        infile = $fopen("input.txt", "r");
        if (infile == 0) begin
            $display("ERROR: Cannot open input.txt");
            $finish;
        end
        outfile = $fopen("output.txt", "w");
        if (outfile == 0) begin
            $display("ERROR: Cannot open output.txt");
            $finish;
        end

        // --- Apply reset ---
        $display("Applying reset...");
        #(10*CLK_PERIOD);
        rst = 0;
        $display("Starting CIC simulation with D = %0d ...", D);

        // --- Feed input samples ---
        while (!$feof(infile)) begin
            scan_status = $fscanf(infile, "%d\n", d_in);
            #(CLK_PERIOD);
            sample_count = sample_count + 1;

            // --- Log valid decimated outputs ---
            if (d_clk) begin
                $fwrite(outfile, "%d\n", d_out);
            end
        end

        // --- Wrap up ---
        $display("Simulation complete: %0d samples processed.", sample_count);
        $fclose(infile);
        $fclose(outfile);
        #(20*CLK_PERIOD);
        $finish;
    end

endmodule

