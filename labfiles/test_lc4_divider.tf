`timescale 1ns / 1ps

module testbench_v;

   integer     errors, linenum;

   // Inputs
   reg [15:0] dividend_in;
   reg [15:0] divisor_in;
   
   // Outputs
   wire [15:0] remainder_out;
   wire [15:0] quotient_out;
   
   // Instantiate the Unit Under Test (UUT)
   
   lc4_divider div (dividend_in, 
                    divisor_in, 
                    remainder_out, 
                    quotient_out);

   reg [15:0] expected_remainder_out;
   reg [15:0] expected_quotient_out;
   
   initial begin
      
      // Initialize Inputs
      dividend_in = 0;
      divisor_in = 0;
      
      errors = 0;
      linenum = 0;
      
      // Wait for global reset to finish
      #100;
      
      #2;

      while (linenum < 10000) begin

         dividend_in = $random;
         divisor_in = $random;

         #8;
         
         linenum = linenum + 1;

         expected_quotient_out = (dividend_in / divisor_in);
         expected_remainder_out = (dividend_in % divisor_in);
                
         if (expected_quotient_out !== quotient_out) begin
            $display("Error at line %d: dividend_in = %b, divisor_in = %b, quotient_out should have been %b, but was %b instead", 
                     linenum, dividend_in, divisor_in, expected_quotient_out, quotient_out);
            errors = errors + 1;
         end

         if (expected_remainder_out !== remainder_out) begin
            $display("Error at line %d: dividend_in = %b, divisor_in = %b, remainder_out should have been %b, but was %b instead", 
                     linenum, dividend_in, divisor_in, expected_remainder_out, remainder_out);
            errors = errors + 1;
         end
         
         #2;

      end // end while
      
      $display("Simulation finished: %d test cases %d errors", linenum, errors);
      $finish;
   end
   
endmodule
