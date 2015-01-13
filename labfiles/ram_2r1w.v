`timescale 1ns / 1ps

module ram_2r1w(clk, gwe, rst, r1sel, r1data, r2sel, r2data, wsel, wdata, we);
   parameter bit_width = 16;
   parameter addr_width = 3;
   localparam ram_size = 1 << addr_width;
   
   input clk, gwe, rst;
   input [addr_width-1:0] r1sel, r2sel, wsel;
   
   input [bit_width-1:0] wdata;
   input we;
   output [bit_width-1:0] r1data, r2data;
   
   reg [bit_width-1:0] mem_state [ram_size-1:0];

   integer              i;

   assign #(1) r1data = mem_state[r1sel];
   assign #(1) r2data = mem_state[r2sel];

   always @(posedge clk) 
     begin 
       if (gwe & rst) 
         for (i=0; i<ram_size; i=i+1)
           mem_state[i] = 0;
       else if (gwe & we)
         mem_state[wsel] = wdata; 
     end

endmodule

module ram_4r1w(clk, gwe, rst, r1sel, r1data, r2sel, r2data, r3sel, r3data, r4sel, r4data, wsel, wdata, we);
   parameter bit_width = 16;
   parameter addr_width = 2;
   localparam ram_size = 1 << addr_width;
   
   input clk, gwe, rst;
   input [addr_width-1:0] r1sel, r2sel, r3sel, r4sel, wsel;
   
   input [bit_width-1:0] wdata;
   input we;
   output [bit_width-1:0] r1data, r2data, r3data, r4data;
   
   reg [bit_width-1:0] mem_state [ram_size-1:0];

   integer              i;

   assign #(1) r1data = mem_state[r1sel];
   assign #(1) r2data = mem_state[r2sel];
   assign #(1) r3data = mem_state[r3sel];
   assign #(1) r4data = mem_state[r4sel];

   always @(posedge clk) 
     begin 
       if (gwe & rst) 
         for (i=0; i<ram_size; i=i+1)
           mem_state[i] = 0;
       else if (gwe & we)
         mem_state[wsel] = wdata; 
     end

endmodule


