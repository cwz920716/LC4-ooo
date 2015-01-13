`timescale 1ns / 1ps

`define EOF 32'hFFFF_FFFF
`define NEWLINE 10
`define NULL 0

`ifndef INPUT
`define INPUT "test_lc4_alu.input"
`endif

`define OUTPUT "test_lc4_alu.output"

module testbench_v;

   integer     input_file, output_file, errors, linenum;

   // Inputs
   reg [15:0] insn;
   reg [15:0] pc;
   reg [15:0] r1data;
   reg [15:0] r2data;
   
   // Outputs
   wire [15:0] out;
   
   // Instantiate the Unit Under Test (UUT)
   
   lc4_alu alu (insn,
                pc,
                r1data,
                r2data,
                out);
   
   reg [15:0] expected_out;
   
   initial begin
      
      // Initialize Inputs
      insn = 0;
      r1data = 0;
      r2data = 0;

      errors = 0;
      linenum = 0;
      output_file = 0;
      
      // open the test inputs
      input_file = $fopen(`INPUT, "r");
      if (input_file == `NULL) begin
         $display("Error opening file: ", `INPUT);
         $finish;
      end

      // open the output file
`ifdef OUTPUT
      output_file = $fopen(`OUTPUT, "w");
      if (output_file == `NULL) begin
         $display("Error opening file: ", `OUTPUT);
         $finish;
      end
`endif

      // Wait for global reset to finish
      #100;
      
      #2;

      while (5 == $fscanf(input_file, "%b %b %b %b %b", insn, pc, r1data, r2data, expected_out)) begin

         #8;
         
         linenum = linenum + 1;
                
         if (output_file) begin
            $fdisplay(output_file, "%b %b %b %b %b", insn, pc, r1data, r2data, out);
         end
         
         if (out !== expected_out) begin
            $display("Error at line %d: insn = %b, pc = %b, r1data = %b, r2data = %b, output value should have been %b, but was %b instead", linenum, insn, pc, r1data, r2data, expected_out, out);
            errors = errors + 1;
         end
         
         #2;

      end // end while
      
      if (input_file) $fclose(input_file); 
      if (output_file) $fclose(output_file);
      $display("Simulation finished: %d test cases %d errors [%s]", linenum, errors, `INPUT);
      $finish;
   end
   
endmodule
