`timescale 1ns / 1ps

module ps4 (req, gnt);

   input [3:0] req;
   output [1:0] gnt;
   
   wire iq_round;
   assign iq_round = req[3];

   wire [1:0] low;
   assign low = (req[0]) ? 2'd0 :
                (req[1]) ? 2'd1 :
                (req[2]) ? 2'd2 :
                (req[3]) ? 2'd3 : 2'd0;

   wire [1:0] high;
   assign high = (~req[3]) ? 2'd3 :
                 (~req[2]) ? 2'd2 :
                 (~req[1]) ? 2'd1 :
                 (~req[0]) ? 2'd0 : 2'd3;

   assign gnt = (iq_round) ? (high + 2'd1) : low;

endmodule

module lc4_memory_queue(iq0_insn, iq1_insn, iq2_insn, iq3_insn,
                        iq_valid, iq_issue, iq_commit, iq_rd,
                        iq_mem, iq_mem_index);

   input [15:0]    iq0_insn, iq1_insn, iq2_insn, iq3_insn;
   input [3:0]     iq_valid, iq_issue, iq_commit;
   input [1:0]     iq_rd;

   output [3:0]    iq_mem;
   output [1:0]    iq_mem_index;

   wire [3:0]      iq_uncommit;
   assign iq_uncommit = iq_valid & ~iq_commit;

   wire [1:0]      iq_1st, iq_2nd, iq_3rd, iq_4th;
   // ps4 iq_ps4 (.req(iq_valid), .gnt(iq_1st));
   assign iq_1st = iq_rd;
   assign iq_2nd = iq_1st + 2'd1;
   assign iq_3rd = iq_2nd + 2'd1;
   assign iq_4th = iq_3rd + 2'd1;

   wire [3:0] mem_id;

   wire            iq0_is_load, iq0_is_store;
   lc4_decoder iq0_decoder(.insn(iq0_insn), .is_load(iq0_is_load), .is_store(iq0_is_store));
   assign mem_id[0] = (iq0_is_load & iq_uncommit[0]) | (iq0_is_store & iq_valid[0]);

   wire            iq1_is_load, iq1_is_store;
   lc4_decoder iq1_decoder(.insn(iq1_insn), .is_load(iq1_is_load), .is_store(iq1_is_store));
   assign mem_id[1] = (iq1_is_load & iq_uncommit[1]) | (iq1_is_store & iq_valid[1]);

   wire            iq2_is_load, iq2_is_store;
   lc4_decoder iq2_decoder(.insn(iq2_insn), .is_load(iq2_is_load), .is_store(iq2_is_store));
   assign mem_id[2] = (iq2_is_load & iq_uncommit[2]) | (iq2_is_store & iq_valid[2]);

   wire            iq3_is_load, iq3_is_store;
   lc4_decoder iq3_decoder(.insn(iq3_insn), .is_load(iq3_is_load), .is_store(iq3_is_store));
   assign mem_id[3] = (iq3_is_load & iq_uncommit[3]) | (iq3_is_store & iq_valid[3]);

   assign iq_mem = mem_id;

   assign iq_mem_index = (mem_id[iq_1st]) ? iq_1st :
                         (mem_id[iq_2nd]) ? iq_2nd :
                         (mem_id[iq_3rd]) ? iq_3rd :
                         (mem_id[iq_4th]) ? iq_4th : 2'd0;

endmodule
                       
