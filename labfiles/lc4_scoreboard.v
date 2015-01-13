`timescale 1ns / 1ps

module lc4_scoreboard(iq0_insn, iq1_insn, iq2_insn, iq3_insn,
                      iq0_prd, iq1_prd, iq2_prd, iq3_prd,
                      iq_valid, iq_issue, iq_commit,
                      a0_valid, a0_prd, a0_rddata,
                      l0_valid, l0_prd, l0_ready, l0_rddata,
                      l1_valid, l1_prd, l1_rddata,
                      wb_valid, wb_prd, wb_rddata,
                      fe_is_load, fe_is_store, fe_waw, iqx_pri, iqx, iqx_raw, iqx_ready, iqx_bypass);

   input [15:0]    iq0_insn, iq1_insn, iq2_insn, iq3_insn;
   input [3:0]     iq0_prd, iq1_prd, iq2_prd, iq3_prd;
   input [3:0]     iq_valid, iq_issue, iq_commit;
   input           fe_is_load, fe_is_store, a0_valid, l0_valid, l0_ready, l1_valid, wb_valid;
   input [15:0]    a0_rddata, l0_rddata, l1_rddata, wb_rddata;
   input [3:0]     a0_prd, l0_prd, l1_prd, wb_prd, iqx_pri;
   input [1:0]     iqx;

   output          fe_waw, iqx_raw, iqx_ready;
   output [15:0]   iqx_bypass;

   wire [2:0]      iq0_r1;
   wire [2:0]      iq0_r2;
   wire [2:0]      iq0_rd;
   wire            iq0_r1re;
   wire            iq0_r2re;
   wire            iq0_rdre;
   wire            iq0_is_load;
   wire            iq0_is_store;
   lc4_decoder iq0_decoder(.insn(iq0_insn), .r1sel(iq0_r1), .r1re(iq0_r1re), .r2sel(iq0_r2), .r2re(iq0_r2re), .wsel(iq0_rd), .regfile_we(iq0_rdre), .is_load(iq0_is_load), .is_store(iq0_is_store));

   wire [2:0]      iq1_r1;
   wire [2:0]      iq1_r2;
   wire [2:0]      iq1_rd;
   wire            iq1_r1re;
   wire            iq1_r2re;
   wire            iq1_rdre;
   wire            iq1_is_load;
   wire            iq1_is_store;
   lc4_decoder iq1_decoder(.insn(iq1_insn), .r1sel(iq1_r1), .r1re(iq1_r1re), .r2sel(iq1_r2), .r2re(iq1_r2re), .wsel(iq1_rd), .regfile_we(iq1_rdre), .is_load(iq1_is_load), .is_store(iq1_is_store));

   wire [2:0]      iq2_r1;
   wire [2:0]      iq2_r2;
   wire [2:0]      iq2_rd;
   wire            iq2_r1re;
   wire            iq2_r2re;
   wire            iq2_rdre;
   wire            iq2_is_load;
   wire            iq2_is_store;
   lc4_decoder iq2_decoder(.insn(iq2_insn), .r1sel(iq2_r1), .r1re(iq2_r1re), .r2sel(iq2_r2), .r2re(iq2_r2re), .wsel(iq2_rd), .regfile_we(iq2_rdre), .is_load(iq2_is_load), .is_store(iq2_is_store));

   wire [2:0]      iq3_r1;
   wire [2:0]      iq3_r2;
   wire [2:0]      iq3_rd;
   wire            iq3_r1re;
   wire            iq3_r2re;
   wire            iq3_rdre;
   wire            iq3_is_load;
   wire            iq3_is_store;
   lc4_decoder iq3_decoder(.insn(iq3_insn), .r1sel(iq3_r1), .r1re(iq3_r1re), .r2sel(iq3_r2), .r2re(iq3_r2re), .wsel(iq3_rd), .regfile_we(iq3_rdre), .is_load(iq3_is_load), .is_store(iq3_is_store));

   wire [3:0]      iq_uncommit;
   wire [3:0]      iq_unissue;
   wire [3:0]      iq_ready;

   assign iq_unissue = iq_valid & ~iq_issue;
   assign iq_uncommit = iq_valid & ~iq_commit;
   assign iq_ready = iq_valid & iq_commit;
 
   wire iq_has_store, iq_has_load;
   assign iq_has_store = ((iq0_is_store) & iq_valid[0]) |
                         ((iq1_is_store) & iq_valid[1]) |
                         ((iq2_is_store) & iq_valid[2]) |
                         ((iq3_is_store) & iq_valid[3]);

   assign iq_has_load = ((iq0_is_load) & iq_valid[0]) |
                        ((iq1_is_load) & iq_valid[1]) |
                        ((iq2_is_load) & iq_valid[2]) |
                        ((iq3_is_load) & iq_valid[3]);

   assign fe_waw = 1'b0; // (iq_has_store & (fe_is_load | fe_is_store)) | (fe_is_store & (iq_has_load | iq_has_store));

   assign iqx_raw = (iqx_pri == iq0_prd & iq0_rdre & iq_unissue[0] & iqx != 2'd0) |
                    (iqx_pri == iq1_prd & iq1_rdre & iq_unissue[1] & iqx != 2'd1) |
                    (iqx_pri == iq2_prd & iq2_rdre & iq_unissue[2] & iqx != 2'd2) |
                    (iqx_pri == iq3_prd & iq3_rdre & iq_unissue[3] & iqx != 2'd3) |
                    (iqx_pri == l0_prd & l0_valid & ~l0_ready);
 
   assign iqx_ready = (iqx_pri == a0_prd & a0_valid) ? 1'b0 :
                      (iqx_pri == l0_prd & l0_valid & l0_ready) ? 1'b0 :
                      (iqx_pri == l1_prd & l1_valid) ? 1'b0 :
                      (iqx_pri == wb_prd & wb_valid) ? 1'b0 :
                      (iqx_raw) ? 1'b0 : 1'b1;

   assign iqx_bypass = (iqx_pri == a0_prd & a0_valid) ? a0_rddata :
                       (iqx_pri == l0_prd & l0_valid & l0_ready) ? l0_rddata :
                       (iqx_pri == l1_prd & l1_valid) ? l1_rddata :
                       (iqx_pri == wb_prd & wb_valid) ? wb_rddata :
                       16'd0;

endmodule
