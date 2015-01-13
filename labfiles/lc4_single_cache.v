`timescale 1ns / 1ps

module lc4_processor(clk,
                     rst,
                     gwe,
                     imem_addr,
                     imem_out,
                     dmem_addr,
                     dmem_out,
                     dmem_we,
                     dmem_in,
                     test_stall,
                     test_pc,
                     test_insn,
                     test_regfile_we,
                     test_regfile_reg,
                     test_regfile_in,
                     test_nzp_we,
                     test_nzp_in,
                     test_dmem_we,
                     test_dmem_addr,
                     test_dmem_value,
                     switch_data,
                     seven_segment_data,
                     led_data
                     ); 
   
   input         clk;         // main clock
   input         rst;         // global reset
   input         gwe;         // global we for single-step clock
   
   output [15:0] imem_addr;   // Address to read from instruction memory
   input  [15:0] imem_out;    // Output of instruction memory
   output [15:0] dmem_addr;   // Address to read/write from/to data memory
   input  [15:0] dmem_out;    // Output of data memory
   output        dmem_we;     // Data memory write enable
   output [15:0] dmem_in;     // Value to write to data memory
   
   output [1:0]  test_stall;       // Testbench: is this is stall cycle? (don't compare the test values)
   output [15:0] test_pc;          // Testbench: program counter
   output [15:0] test_insn;        // Testbench: instruction bits
   output        test_regfile_we;  // Testbench: register file write enable
   output [2:0]  test_regfile_reg; // Testbench: which register to write in the register file 
   output [15:0] test_regfile_in;  // Testbench: value to write into the register file
   output        test_nzp_we;      // Testbench: NZP condition codes write enable
   output [2:0]  test_nzp_in;      // Testbench: value to write to NZP bits
   output        test_dmem_we;     // Testbench: data memory write enable
   output [15:0] test_dmem_addr;   // Testbench: address to read/write memory
   output [15:0] test_dmem_value;  // Testbench: value read/writen from/to memory
   
   input [7:0]   switch_data;
   output [15:0] seven_segment_data;
   output [7:0]  led_data;
 
 
   // PC
   wire [15:0]   pc;
   wire [15:0]   next_pc;

   Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   
   // Stall
   wire          insn_valid;		// Stall if valid == 0
   wire [15:0]   insn_cache_out;
   
   // Instantiate insn cache
   lc4_insn_cache insn_cache (.clk(clk), .gwe(gwe), .rst(rst),
		              .mem_idata(imem_out), .mem_iaddr(imem_addr),
		              .addr(pc), .valid(insn_valid), .data(insn_cache_out));

   /*** YOUR CODE HERE ***/

   assign test_stall = (insn_valid == 1) ? 2'd0 : 2'd1; 

   // For in-simulator debugging, you can use code such as the code
   // below to display the value of signals at each clock cycle.

//`define DEBUG
`ifdef DEBUG
   always @(posedge gwe) begin
      $display("%d %h %h %h %d", $time, pc, imem_addr, imem_out, insn_valid);
   end
`endif

   // For on-board debugging, the LEDs and segment-segment display can
   // be configured to display useful information.  The below code
   // assigns the four hex digits of the seven-segment display to either
   // the PC or instruction, based on how the switches are set.
   
   assign seven_segment_data = (switch_data[6:0] == 7'd0) ? pc :
                               (switch_data[6:0] == 7'd1) ? imem_out :
                               (switch_data[6:0] == 7'd2) ? dmem_addr :
                               (switch_data[6:0] == 7'd3) ? dmem_out :
                               (switch_data[6:0] == 7'd4) ? dmem_in :
                               /*else*/ 16'hDEAD;
   assign led_data = switch_data;
   
endmodule

