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

   /*** YOUR CODE HERE ***/

   // Instruction Wire
   wire [15:0]   insn_reg;

   assign imem_addr = pc;
   assign insn_reg = imem_out;

   // Decode Logic
   wire [2:0]    r1src;
   wire [2:0]    r2src;
   wire          r1re;
   wire          r2re;
   wire [2:0]    rd;    
   wire          regfile_we;
   wire          nzp_we;
   wire          select_pc_plus_one;
   wire          is_load;
   wire          is_store;
   wire          is_branch;
   wire          is_control_insn;

   lc4_decoder decoder (.insn(insn_reg), .r1sel(r1src), .r1re(r1re), .r2sel(r2src), 
	 		 .r2re(r2re), .wsel(rd), .regfile_we(regfile_we), .nzp_we(nzp_we), .select_pc_plus_one(select_pc_plus_one),
	 		 .is_load(is_load), .is_store(is_store), .is_branch(is_branch), .is_control_insn(is_control_insn)); 

   // Register file
   wire [15:0]   r1data;
   wire [15:0]   r2data;
   wire [15:0]   rddata;

   lc4_regfile regfile (.clk(clk), .gwe(gwe), .rst(rst), .r1sel(r1src), .r1data(r1data), .r2sel(r2src), .r2data(r2data), .wsel(rd), .wdata(rddata), .we(regfile_we));
	 
   // Setting up the NZP Register
   wire [2:0]    nzp;
   wire [2:0]    next_nzp;

   Nbit_reg #(3, 3'b000) nzp_reg (.in(next_nzp), .out(nzp), .clk(clk), .we(nzp_we), .gwe(gwe), .rst(rst));

   // Exec Logic
   wire [15:0]   alu_out;
   wire [15:0]   exec_out;

   lc4_alu alu (.insn(insn_reg), .pc(pc), .r1data(r1data), .r2data(r2data), .out(alu_out));

   // PC Branch Logic
   wire [15:0]   pc_plus_one;
   wire          branch_taken;

   assign pc_plus_one = pc + 16'd1;
   
   assign exec_out = (select_pc_plus_one) ? (pc_plus_one) : (alu_out);
   lc4_branch branch (.branch_tgt(alu_out), .pc_plus_one(pc_plus_one), .insn_11_9(insn_reg[11:9]), .nzp(nzp), .is_branch(is_branch), .is_control_insn(is_control_insn), 
                      .next_pc(next_pc), .branch_taken(branch_taken));

   // NZP Logic
   wire [2:0]    nzp_out;
   wire [15:0]   nzp_value;

   assign nzp_value = (is_load) ? dmem_out : exec_out ;
   assign nzp_out = (nzp_value == 16'd0) ? (3'b010) :
                    (nzp_value[15] == 1'b1) ? (3'b100) : (3'b001);
   assign next_nzp = (nzp_we) ? nzp_out : nzp;

   // Mem Logic
   assign dmem_in = r2data;
   assign dmem_we = is_store;
   assign dmem_addr = (is_load | is_store) ? exec_out : 16'h0000;

   // Write-Back Logic
   assign rddata = nzp_value;

   // Always execute one instruction each cycle
   assign test_stall = 2'b0; 

   // For in-simulator debugging, you can use code such as the code
   // below to display the value of signals at each clock cycle.
   assign test_pc = pc;
   assign test_insn = insn_reg; 					// Testbench: instruction bits
   assign test_regfile_we = regfile_we;	// Testbench: register file write enable
   assign test_regfile_reg = rd;		// Testbench: which register to write in the register file 
   assign test_regfile_in = rddata;			// Testbench: value to write into the register file
   assign test_nzp_we = nzp_we;				// Testbench: NZP condition codes write enable
   assign test_nzp_in = next_nzp;      			// Testbench: value to write to NZP bits
   assign test_dmem_we = dmem_we;			// Testbench: data memory write enable
   assign test_dmem_addr = dmem_addr;  	// Testbench: address to read/write memory
   assign test_dmem_value = is_store ? dmem_in : (is_load ? dmem_out : 16'h0000);	// Testbench: value read/writen from/to memory


//`define DEBUG
`ifdef DEBUG
   always @(posedge gwe) begin
      $display("%d %h %b %h", $time, pc, insn, alu_out_pre_mux);
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

