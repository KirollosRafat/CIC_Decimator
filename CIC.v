
module CIC #(parameter INPUTWIDTH = 8,parameter D = 4, parameter N = 4)
(input wire               clk,
 input wire               rst,
 input wire signed [INPUTWIDTH-1:0]  d_in,
 output reg signed [INPUTWIDTH-1:0]  d_out,
 output reg 		  d_clk
);

localparam REGWIDTH =  INPUTWIDTH + (N * $clog2(D));


reg signed [REGWIDTH-1:0] d_tmp, d_d_tmp;

// Four Stage Cascaded Integrators Registers

reg signed [REGWIDTH-1:0] d1;
reg signed [REGWIDTH-1:0] d2;
reg signed [REGWIDTH-1:0] d3;
reg signed [REGWIDTH-1:0] d4;


// Four Comb Stage Registers

reg signed [REGWIDTH-1:0] d5, d_d5;
reg signed [REGWIDTH-1:0] d6, d_d6;
reg signed [REGWIDTH-1:0] d7, d_d7;
reg signed [REGWIDTH-1:0] d8;

// Internal counter to count till decimation (downsampling) is over
reg [$clog2(D)-1:0] count;

// Valid signal for comb section running at output rate
reg v_comb;  

// Temporary register to hold the output rate status 
reg d_clk_tmp;

 
	always @(posedge clk)
	begin
		if (rst)
		begin
			d1 <= 0;
			d2 <= 0;
			d3 <= 0;
			d4 <= 0;
			count <= 0;
		end else
		begin
			// Integrator section
			d1 <= d_in + d1;
			
			d2 <= d1 + d2;
			
			d3 <= d2 + d3;
			
			d4 <= d3 + d4;
				
			// Decimation (Downsampling D?)
			
			if (count == D - 1)
			begin
				count <= {($clog2(D)){1'b0}};
				d_tmp <= d4;
				d_clk_tmp <= 1'b1;
				v_comb <= 1'b1;
			end else 
			begin
				d_clk_tmp <= 1'b0;
				count <= count + 1'b1;
				v_comb <= 1'b0;
			end 
		end
	end
	
	// Comb section running at output rate
	always @(posedge clk)  
	begin
		d_clk <= d_clk_tmp;
		if (rst)
		begin
			d5 <= 0;
			d6 <= 0;
			d7 <= 0;
			d8 <= 0;
			d_d5 <= 0;
			d_d6 <= 0;
			d_d7 <= 0;
			d_d_tmp <= 0;
			d_out <= 0;
		end else
		begin
			if (v_comb)
			begin
				// d_d_tmp stores the previous decimated sample.	
				d_d_tmp <= d_tmp;
				
				// The subtraction (d_tmp - d_d_tmp) implements the first comb stage (x[n] - x[n-1]).
				d5 <= d_tmp - d_d_tmp;
				d_d5 <= d5;

				d6 <= d5 - d_d5;
				d_d6 <= d6;

				d7 <= d6 - d_d6;
				d_d7 <= d7;

				d8 <= d7 - d_d7;
					
				d_out <= d8 >>> (REGWIDTH - INPUTWIDTH);
			end
		end
	end								
endmodule