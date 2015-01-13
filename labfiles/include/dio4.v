`timescale 1ns / 1ps

// This module controls devices  on the dio4 extension board.

module di04(seven_segment_data, led_data, COUT, AOUT, LDOUT, SEV_SEG_CLK);

   /* 
    * lights_data is the input data to be written to the LEDs or seven-segment display
    * COUT are the 7 outputs to the cathodes of the seven-segment display
    * AOUT are the 4 outputs to the anodes of the seven-segment display
    * LDOUT are the 8 outputs to the expansion board LEDs
    * SEV_SEG_CLK is a 32 MHz clock, used to alternate the cathodes and anodes of the 7-seg display.
    */
   
   input [15:0] seven_segment_data;
   input  [7:0] led_data;
   input        SEV_SEG_CLK; 
   output [6:0] COUT;
   output [3:0] AOUT;
   output [7:0] LDOUT;
   
   // The led_data can be sent unmodified to the LEDs.
   assign        LDOUT = led_data;

   /* Since the 7-segment display shares the 7 cathodes for all 4 digits (anodes), to create 
    * an output with multiple digits, we must rapdily alternate between the 4 digits,
    * changing the cathodes to the appropriate value for that digit.  This alternation must
    * be faster than 60 Hz, so that we cannot see the alternation, but it must also be sufficiently
    * slow.  If the alternation is too fast, then all active cathodes from all 4 digits will appear 
    * to be lit at all times. slow_clk is a obtained by slowing down the input clock to a
    * reasonable speed for the seven-segment display.
    */
   
   wire         slow_clk;
   clkdiv #(65535) sclock( .CIN(SEV_SEG_CLK), .COUT(slow_clk) );
   
   // select is used to choose the active 7-seg anode and its corresponding data.
   // Since there are 4 anodes, this is done with a counter based on the slow_clk
   wire [1:0]   select;
   
   counter count(.C(slow_clk), 
                 .Q(select));
   
   nand(AOUT[3], ~select[1], ~select[0]);
   nand(AOUT[2], ~select[1], select[0]);
   nand(AOUT[1], select[1], ~select[0]);
   nand(AOUT[0], select[1], select[0]);
      
   // Each digit represents the proper cathode settings for 4-bits of the seven-segment data
   wire [6:0]    first_digit, second_digit, third_digit, fourth_digit;

   decode4 high4 (seven_segment_data[15:12], fourth_digit);
   decode4 third4 (seven_segment_data[11:8], third_digit);
   decode4 second4 (seven_segment_data[7:4], second_digit);
   decode4 low4 (seven_segment_data[3:0], first_digit);
   
   mux_Nbit_4to1 #(7) cathode_mux(.a(first_digit), 
                                  .b(second_digit), 
                                  .c(third_digit), 
                                  .d(fourth_digit), 
                                  .sel(select), 
                                  .out(COUT));
   
      
endmodule // di04



// This module decodes a single hexadecimal digit into a pattern for the 7-segment cathodes.
module decode4(HEX_IN, DISP_OUT);
   input [3:0] HEX_IN;
   output [6:0] DISP_OUT;
   reg [6:0]    DISP_OUT;
   
   always @(HEX_IN) begin
      case (HEX_IN)
        //The cathodes are active low, with the most significant bit of DISP_OUT representing
        //cathode g and the least significant bit representing cathode a.
        0:  DISP_OUT = 7'b1000000;  
        1:  DISP_OUT = 7'b1111001;
        2:  DISP_OUT = 7'b0100100;
        3:  DISP_OUT = 7'b0110000;
        4:  DISP_OUT = 7'b0011001;
        5:  DISP_OUT = 7'b0010010;
        6:  DISP_OUT = 7'b0000010;
        7:  DISP_OUT = 7'b1111000;
        8:  DISP_OUT = 7'b0000000;
        9:  DISP_OUT = 7'b0011000;
        10:  DISP_OUT = 7'b0001000;
        11:  DISP_OUT = 7'b0000011;
        12:  DISP_OUT = 7'b0100111;
        13:  DISP_OUT = 7'b0100001;
        14:  DISP_OUT = 7'b0000110;
        15:  DISP_OUT = 7'b0001110;
        default:  DISP_OUT = 7'b1111111;  //We will never reach the default case
      endcase
   end
   
endmodule

// This module is a simple 4-bit counter, used to select the active
// anode of the 7-segment display and it's corresponding decoded digit.

module counter (C, Q);
   input C;             //Clock input
   output [1:0] Q;      
   reg [1:0]    Q;
   
   initial begin
      Q = 0;            //Initialize the output reg to 0, so that incrementing Q is well defined.
   end
   
   always @(posedge C) begin      
      if (Q >= 3 || Q < 0)  //Explicitly handle all edge/error cases by reseting the counter to 0.      
        Q = 0;      
      else                  //On each positive clock edge, the counter is incremented.
        Q = Q + 1;      
   end  
   
endmodule

// This module is a parameterized, counter-based clock-divider.
module clkdiv (CIN, COUT);
   parameter n = 65535;  // The 7-segment display uses a very slow clock, so the default parameter is large.
   input     CIN;        // Clock input
   output    COUT;       // Output is the input clock divided by n.
   reg       COUT;
   reg [31:0] Q;         // Internal reg to maintain the state of the counter.

   initial begin
      Q = 0;
      COUT = 0;
   end

   always @(posedge CIN) begin
      if (Q >= n - 1 || Q < 0)  // We have incremented the counter n times 
        begin                   // so we have had n positive edges of the input clock
           Q = 0;               // Reset the counter
           COUT = ~COUT;        // Toggle the output clock.
        end      
      else        
        Q = Q + 1;              // We have not yet had n input clock pos. edges, so keep counting.
   end  
endmodule
