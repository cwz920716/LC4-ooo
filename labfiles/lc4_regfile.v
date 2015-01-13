`timescale 1ns / 1ps

module lc4_regfile(clk, gwe, rst, r1sel, r1data, r2sel, r2data, wsel, wdata, we);
   parameter n = 16;
   
   input clk, gwe, rst;
   input [2:0] r1sel, r2sel, wsel;
   
   input [n-1:0] wdata;
   input we;
   output [n-1:0] r1data, r2data;
   
   wire [n-1:0] r0out, r1out, r2out, r3out, r4out, r5out, r6out, r7out;

   /*** YOUR CODE HERE ***/
   // Instantiating Register Values
   Nbit_reg #(n) r0 (wdata, r0out, clk, (wsel == 3'd0) & we, gwe, rst);
   Nbit_reg #(n) r1 (wdata, r1out, clk, (wsel == 3'd1) & we, gwe, rst);
   Nbit_reg #(n) r2 (wdata, r2out, clk, (wsel == 3'd2) & we, gwe, rst);
   Nbit_reg #(n) r3 (wdata, r3out, clk, (wsel == 3'd3) & we, gwe, rst);
   Nbit_reg #(n) r4 (wdata, r4out, clk, (wsel == 3'd4) & we, gwe, rst);
   Nbit_reg #(n) r5 (wdata, r5out, clk, (wsel == 3'd5) & we, gwe, rst);
   Nbit_reg #(n) r6 (wdata, r6out, clk, (wsel == 3'd6) & we, gwe, rst);
   Nbit_reg #(n) r7 (wdata, r7out, clk, (wsel == 3'd7) & we, gwe, rst);

   // Output values
   mux_Nbit_8to1 #(n) mux1 (r1data, r0out, r1out, r2out, r3out, r4out, r5out, r6out, r7out, r1sel);
   mux_Nbit_8to1 #(n) mux2 (r2data, r0out, r1out, r2out, r3out, r4out, r5out, r6out, r7out, r2sel);

endmodule

module lc4_ooo_regfile(clk, gwe, rst, flush, 
                       r1sel, r1data, r2sel, r2data, nzp_out,
                       prf_wsel, prf_wdata, prf_we, prf_nzp_in, prf_nzp_we, 
                       arf_wsel, arf_wdata, arf_we, arf_nzp_in, arf_nzp_we);

   parameter n = 16;
   parameter w = 4;
   
   input clk, gwe, rst, flush;
   input [w-1:0] r1sel, r2sel, prf_wsel;
   input [2:0] arf_wsel;
   
   input [n-1:0] prf_wdata, arf_wdata;
   input [2:0] prf_nzp_in, arf_nzp_in;
   input prf_nzp_we, arf_nzp_we;
   input prf_we, arf_we;
   
   
   output [n-1:0] r1data, r2data;
   output [2:0] nzp_out;

   wire [n-1:0] arf_r1data, arf_r2data, prf_r1data, prf_r2data;

   // lc4_regfile prf (clk, gwe, rst, r1sel, prf_r1data, r2sel, prf_r2data, prf_wsel, prf_wdata, prf_we);
   ram_2r1w #(16,4) prf (.clk(clk), .gwe(gwe), .rst(rst), .r1sel(r1sel), .r1data(prf_r1data), .r2sel(r2sel), .r2data(prf_r2data), .wsel(prf_wsel), .wdata(prf_wdata), .we(prf_we));
// RFC: For now ARF is only for writing
   lc4_regfile arf (.clk(clk), .gwe(gwe), .rst(rst), .wsel(arf_wsel), .wdata(arf_wdata), .we(arf_we));

// RFC: Add Flush Propagation

   assign r1data = prf_r1data;
   assign r2data = prf_r2data;

// RFC: Add NZP Rename 
   wire [2:0] prf_nzp_out, arf_nzp_out;
   Nbit_reg #(3, 3'd0) prf_nzp (.in(prf_nzp_in), .out(prf_nzp_out), .clk(clk), .we(prf_nzp_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'd0) arf_nzp (.in(arf_nzp_in), .out(arf_nzp_out), .clk(clk), .we(arf_nzp_we), .gwe(gwe), .rst(rst));
   assign nzp_out = prf_nzp_out;

endmodule

