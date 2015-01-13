`timescale 1ns / 1ps

module lc4_divider(dividend_in, divisor_in, remainder_out, quotient_out);
   
   input [15:0] dividend_in, divisor_in;
   output [15:0] remainder_out, quotient_out;

   /*** YOUR CODE HERE ***/
   // initialize
   parameter [15:0] r_0 = 16'b0;
   parameter [15:0] q_0 = 16'b0;
	 
   wire [15:0] remainder;
   wire [15:0] quotient;
 
   wire [15:0] r_1, r_2, r_3, r_4, r_5, r_6, r_7, r_8, r_9, r_10, r_11, r_12, r_13, r_14, r_15;
   wire [15:0] q_1, q_2, q_3, q_4, q_5, q_6, q_7, q_8, q_9, q_10, q_11, q_12, q_13, q_14, q_15;
   wire [15:0] d_1, d_2, d_3, d_4, d_5, d_6, d_7, d_8, d_9, d_10, d_11, d_12, d_13, d_14, d_15, d_16;

   lc4_divider_one_iter div_1 (dividend_in, divisor_in, r_0, q_0, d_1, r_1, q_1);
   lc4_divider_one_iter div_2 (d_1, divisor_in, r_1, q_1, d_2, r_2, q_2);
   lc4_divider_one_iter div_3 (d_2, divisor_in, r_2, q_2, d_3, r_3, q_3);
   lc4_divider_one_iter div_4 (d_3, divisor_in, r_3, q_3, d_4, r_4, q_4);
   lc4_divider_one_iter div_5 (d_4, divisor_in, r_4, q_4, d_5, r_5, q_5);
   lc4_divider_one_iter div_6 (d_5, divisor_in, r_5, q_5, d_6, r_6, q_6);
   lc4_divider_one_iter div_7 (d_6, divisor_in, r_6, q_6, d_7, r_7, q_7);
   lc4_divider_one_iter div_8 (d_7, divisor_in, r_7, q_7, d_8, r_8, q_8);
   lc4_divider_one_iter div_9 (d_8, divisor_in, r_8, q_8, d_9, r_9, q_9);
   lc4_divider_one_iter div_10 (d_9, divisor_in, r_9, q_9, d_10, r_10, q_10);
   lc4_divider_one_iter div_11 (d_10, divisor_in, r_10, q_10, d_11, r_11, q_11);
   lc4_divider_one_iter div_12 (d_11, divisor_in, r_11, q_11, d_12, r_12, q_12);
   lc4_divider_one_iter div_13 (d_12, divisor_in, r_12, q_12, d_13, r_13, q_13);
   lc4_divider_one_iter div_14 (d_13, divisor_in, r_13, q_13, d_14, r_14, q_14);
   lc4_divider_one_iter div_15 (d_14, divisor_in, r_14, q_14, d_15, r_15, q_15);
   lc4_divider_one_iter div_16 (d_15, divisor_in, r_15, q_15, d_16, remainder, quotient);
	 
   assign remainder_out = (divisor_in == 16'd0) ? (16'd0) : (remainder);
   assign quotient_out = (divisor_in == 16'd0) ? (16'd0) : (quotient);

endmodule


