`timescale 1ns / 1ps

`define EOF 32'hFFFF_FFFF
`define NEWLINE 10
`define NULL 0

`ifndef INPUT
`define INPUT "test_lc4_rob.input"
`endif

`define OUTPUT "test_lc4_rob.output"

module testbench_v;

   integer     input_file, output_file, errors, linenum;

   // Inputs
   reg flush;
   reg rst;
   reg clk;
   reg gwe;
   
   reg [2:0] commit_in;
   reg [15:0] data_in;
   reg rob_enq;
   reg rob_deq;
   reg rob_commit;

   // Outputs
   wire [15:0] data;
   wire       commit;
   wire       valid;
   wire [2:0] xxx;
   wire       full;
   
   // Instantiate the Unit Under Test (UUT)
   
   lc4_reorder_buffer rob  (.clk(clk),
                        .gwe(gwe),
                        .rst(rst),
                        .flush(flush),
                        .data_in(data_in),
                        .rob_enq(rob_enq),
                        .rob_deq(rob_deq),
                        .rob_commit(rob_commit),
                        .commit_in(commit_in),
                        .data_out(data), 
                        .valid_out(valid),
                        .commit_out(commit),
                        .xxx_out(xxx),
                        .full_out(full));
   
   reg [15:0]  expectedValue1;
   reg expectedValue2;
   reg expectedValue3;
   reg expectedValue4;
   
   always #5 clk <= ~clk;
   
   initial begin
      
      // Initialize Inputs
      data_in = 0;
      rob_enq = 0;
      rob_deq = 0;
      rob_commit = 0;
      commit_in = 0;
      flush = 0;
      rst = 1;
      clk = 0;
      gwe = 1;

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
      
      #5 rst = 0;
      
      #2;         

      while (10 == $fscanf(input_file, "%h %b %d %b %b %b %h %b %b %b", data_in, rob_enq, commit_in, rob_commit, rob_deq, flush, expectedValue1, expectedValue2, expectedValue3, expectedValue4)) begin
         
         #8;
              
         linenum = linenum + 1;
         
         if (output_file) begin
            $fdisplay(output_file, "%h %b %d %b %b %b %h %b %b %b %d", data_in, rob_enq, commit_in, rob_commit, rob_deq, flush, data, valid, commit, full, xxx);
         end

         if (data !== expectedValue1) begin
            $display("Error at line %d: Value of data should have been %h, but was %b instead", linenum, expectedValue1, data);
            errors = errors + 1;
            $finish;
         end
         
         if (valid !== expectedValue2) begin
            $display("Error at line %d: Value of valid should have been %b, but was %b instead", linenum, expectedValue2, valid);
            errors = errors + 1;
            $finish;
         end
         
         if (commit !== expectedValue3) begin
            $display("Error at line %d: Value of commit should have been %b, but was %b instead", linenum, expectedValue3, commit);
            errors = errors + 1;
            $finish;
         end

         if (full !== expectedValue4) begin
            $display("Error at line %d: Value of full should have been %b, but was %b instead", linenum, expectedValue3, full);
            errors = errors + 1;
            $finish;
         end

         #2;         
         
      end // end while
      
      if (input_file) $fclose(input_file); 
      if (output_file) $fclose(output_file);
      $display("Simulation finished: %d test cases %d errors [%s]", linenum, errors, `INPUT);
      $finish;
   end
   
endmodule
