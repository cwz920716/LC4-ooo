`timescale 1ns / 1ps


module lc4_branch(
	input [15:0] branch_tgt,
	input [15:0] pc_plus_one,
	input [2:0] insn_11_9,
	input [2:0]	nzp,
	input		is_branch,
	input		is_control_insn,
	output [15:0] next_pc,
	output		branch_taken
    );
	 
   wire branch_logic_inter;

   assign branch_logic_inter = ((nzp & insn_11_9) != 3'b000) ? (1'b1) : (1'b0);
   assign branch_taken = (is_branch == 1'b1) ? (branch_logic_inter) :
								 (is_control_insn) ? (1'b1) : (1'b0);								 
   assign next_pc = (branch_taken) ? (branch_tgt) : pc_plus_one;

endmodule
