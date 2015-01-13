`timescale 1ns / 1ps

module lc4_load0_stage(insn,
                       pc,
                       r1data,
                       r2data,
                       exec_out,
                       is_load,
                       rd,
                       regfile_we);

   input [15:0]    insn;
   input [15:0]    pc;
   input [15:0]    r1data;
   input [15:0]    r2data;
   output [15:0]   exec_out;
   output          is_load;
   output [2:0]    rd;
   output          regfile_we;

   wire [15:0]     alu_out;
   wire select_pc_plus_one;
   wire [15:0] pc_plus_one;

   assign pc_plus_one = pc + 16'd1;

   lc4_decoder decoder(.insn(insn), .select_pc_plus_one(select_pc_plus_one), .is_load(is_load), .wsel(rd), .regfile_we(regfile_we));
   lc4_alu alu (.insn(insn), .pc(pc), .r1data(r1data), .r2data(r2data), .out(alu_out));
   assign exec_out = (select_pc_plus_one) ? (pc_plus_one) : (alu_out);

endmodule
