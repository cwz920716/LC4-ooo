`timescale 1ns / 1ps

module lc4_divider_one_iter(dividend_in, divisor_in, remainder_in, quotient_in, 
                            dividend_out, remainder_out, quotient_out);
   
   input [15:0] dividend_in, divisor_in, remainder_in, quotient_in;
   output [15:0] dividend_out, remainder_out, quotient_out;
   
   /*** YOUR CODE HERE ***/
   wire [15:0] remainder;
   // 1 cycle of operations for the division algorithm
   assign remainder = (remainder_in << 1) | ((dividend_in >> 15) & 16'b1);
   // Assigning quotient_out depending on comparative value of divisor
   assign quotient_out = (remainder < divisor_in) ? ((quotient_in << 1) | 16'b0) : ((quotient_in << 1) | 16'b1);
   // Assigning remainder_out depending on comparative value to divisor
   assign remainder_out = (remainder < divisor_in) ? remainder : (remainder - divisor_in);
   // Shifting divisor left
   assign dividend_out = dividend_in << 1;
   
endmodule



