`timescale 1ns / 1ps

module lc4_fetch_stage(pc,
                       imem_out,
                       imem_addr,
                       insn,
                       pc_pred,
                       r1,
                       r2,
                       rd,
                       rob_full,
                       fl_full,
                       stall,
                       mam,
                       fl_alloc,
                       iq0_insn, iq1_insn, iq2_insn, iq3_insn,
                       iq_valid, iq_issue, iq_commit);

   input [15:0]    pc;
   input [15:0]    imem_out;
   input [15:0]    iq0_insn, iq1_insn, iq2_insn, iq3_insn;
   input [3:0]     iq_valid, iq_issue, iq_commit;
   input           rob_full, fl_full;
   output [15:0]   imem_addr;
   output [15:0]   insn;
   output [15:0]   pc_pred;
   output [2:0]    r1, r2, rd;
   output          stall, mam;
   output          fl_alloc;

   assign imem_addr = pc;
   assign insn = imem_out;
   assign pc_pred = pc + 16'd1;

   wire rdre, waw, war;
   wire is_load, is_store;
   wire wax_stall, full_stall;

   lc4_decoder decoder(.insn(insn), .wsel(rd), .regfile_we(rdre), .is_load(is_load), .is_store(is_store), .r1sel(r1), .r2sel(r2));
   lc4_scoreboard fe_sb(.iq0_insn(iq0_insn), .iq1_insn(iq1_insn), .iq2_insn(iq2_insn), .iq3_insn(iq3_insn),
                        .iq_valid(iq_valid), .iq_issue(iq_issue), .iq_commit(iq_commit),
                        .fe_is_load(is_load), .fe_is_store(is_store), .fe_waw(waw));

   assign wax_stall = (waw) & (is_load | is_store);
   assign full_stall = rob_full | (fl_full & rdre);
   assign stall = wax_stall | full_stall;
   assign fl_alloc = ~stall & rdre;
   assign mam = wax_stall;

endmodule
