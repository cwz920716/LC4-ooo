`timescale 1ns / 1ps

`define EOF 32'hFFFF_FFFF
`define NEWLINE 10
`define NULL 0

`ifndef INPUT
`define INPUT "test_lc4_insn_cache_inputs/7_1_2.input"
`endif

//`ifndef OUTPUT
//`define OUTPUT "cache_tests/cache_test.output"
//`endif

module testbench_v;

	integer     input_file, output_file, errors, linenum;

	reg clk;
	reg rst;
	
	wire [15:0] mem_idata;	// from delayer to cache
	wire [15:0] mem_iaddr;	// out (to bram)
	wire [15:0] req_addr;	// from cache to delayer
	reg  [15:0] delayer_data;
	reg  [15:0] addr;			// read address
	wire        valid;		// out
	wire [15:0] data;			// out
   
	wire        i1re, i2re, dre, gwe;
	lc4_we_gen we_gen(.clk(clk),
			.i1re(i1re),
			.i2re(i2re),
			.dre(dre),
			.gwe(gwe));

	// Instantiate the Unit Under Test (UUT)
	lc4_insn_cache uut (
		.clk(clk),
		.gwe(gwe),
		.rst(rst),
		.mem_idata(mem_idata),
		.mem_iaddr(req_addr),
		.addr(addr),
		.valid(valid),
		.data(data)
	);
	
   // Instantiate the delayer 
   delay_eight_cycles #(16) delayer (.clk(clk),
		                     .gwe(gwe),
		                     .rst(rst),
		                     .in_value(delayer_data),
		                     .out_value(mem_idata));

	reg expected_valid;
	reg [15:0] expected_data;
	
	// Set clk cycle
	always #5 clk <= ~clk;
   
	initial begin
      
		// Initialize Inputs
		clk = 0;
		rst = 1;
		delayer_data = 0;
		addr = 0;
      
		errors = 0;
		linenum = 0;
		
		// open the test input file
		input_file = $fopen(`INPUT, "r");
		if (input_file == `NULL) begin
			$display("Error opening file: ", `INPUT);
			$finish;
		end
		
		// Wait for global reset to finish
		#80;
		
		rst = 0;
      
		#2;
		
		$display("Starting test...");

		while (2 == $fscanf(input_file, "%h %d", addr, expected_valid)) begin
			
			#10;
			linenum = linenum + 1;
			
			// Assign delayer_data according to delayer_addr
			delayer_data = req_addr ^ (16'b1010_1010_1010_1010);
			
			if (valid !== expected_valid) begin
				$display("Error at line %d: Value of valid should have been %d, but was %d instead", linenum, expected_valid, valid);
				errors = errors + 1;
				$finish;
			end

			if (valid === 1) begin
				expected_data = addr ^ (16'b1010_1010_1010_1010);
				if (data !== expected_data) begin
					$display("Error at line %d: Value of data should have been %h, but was %h instead", linenum, expected_data, data);
					errors = errors + 1;
					$finish;
				end
			end
		
		#30;
			
			
		end // end while
      
		if (input_file) $fclose(input_file);
		if (output_file) $fclose(output_file);
		
      $display("Simulation finished: %d test cases %d errors", linenum, errors);
      $finish;
   end
   
endmodule
