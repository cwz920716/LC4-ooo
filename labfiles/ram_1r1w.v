`timescale 1ns / 1ps

module ram_1r1w(clk, gwe, rst, rsel, rdata, wsel, wdata, we);
   parameter bit_width = 16;
   parameter addr_width = 2;
   localparam ram_size = 1 << addr_width;
   
   input clk, gwe, rst;
   input [addr_width-1:0] rsel, wsel;
   
   input [bit_width-1:0] wdata;
   input we;
   output [bit_width-1:0] rdata;
   
   reg [bit_width-1:0] mem_state [ram_size-1:0];

   integer              i;

   assign #(1) rdata = mem_state[rsel];

   always @(posedge clk) 
     begin 
       if (gwe & rst) 
         for (i=0; i<ram_size; i=i+1)
           mem_state[i] = 0;
       else if (gwe & we)
         mem_state[wsel] = wdata; 
     end

endmodule
