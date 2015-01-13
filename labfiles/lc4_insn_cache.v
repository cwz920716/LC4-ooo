`timescale 1ns / 1ps

module lc4_insn_cache (
    // global wires
    input         clk, 
    input         gwe,
    input         rst,
    // wires to access instruction memory
    input [15:0]  mem_idata, 
    output [15:0] mem_iaddr,
    // interface for lc4_processor
    input [15:0]  addr,
    output        valid,
    output [15:0] data
    );
     
   /*** YOUR CODE HERE ***/

endmodule

