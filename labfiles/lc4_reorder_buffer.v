`timescale 1ns / 1ps

module lc4_reorder_buffer(clk,
                          gwe,
                          rst,
                          flush,

                          full,
                          empty,

                          fe_insn_in,
                          fe_pc_in,
                          fe_pc_pred_in,
                          fe_pr1sel_in,
                          fe_pr2sel_in,
                          fe_prdsel_in,
                          fe_pprdsel_in,
                          rob_enq,
                          is_index_in,
                          rob_issue,
                          wb_pc_redirect_in,
                          wb_r1data_in,
                          wb_r2data_in,
                          wb_rddata_in,
                          wb_index_in,
                          rob_commit,
                          rob_deq,

                          cm_ready_out,
                          cm_rob_index,
                          cm_insn_out,
                          cm_pc_out,
                          cm_pc_pred_out,
                          cm_pc_redirect_out,
                          cm_r1data_out,
                          cm_r2data_out,
                          cm_rddata_out,
                          cm_pr1sel_out,
                          cm_pr2sel_out,
                          cm_prdsel_out,
                          cm_pprdsel_out,

                          iq0_insn_out,
                          iq1_insn_out,
                          iq2_insn_out,
                          iq3_insn_out,
                          iq0_pc_out,
                          iq1_pc_out,
                          iq2_pc_out,
                          iq3_pc_out,
                          iq0_pc_pred_out,
                          iq1_pc_pred_out,
                          iq2_pc_pred_out,
                          iq3_pc_pred_out,
                          iq0_pr1sel_out,
                          iq1_pr1sel_out,
                          iq2_pr1sel_out,
                          iq3_pr1sel_out,
                          iq0_pr2sel_out,
                          iq1_pr2sel_out,
                          iq2_pr2sel_out,
                          iq3_pr2sel_out,
                          iq0_prdsel_out,
                          iq1_prdsel_out,
                          iq2_prdsel_out,
                          iq3_prdsel_out,
                          iq_valid_out,
                          iq_issue_out,
                          iq_commit_out);

   parameter           n = 4;
   parameter           a = 2;

   input               clk;
   input               gwe;
   input               rst;
   input               flush;

   output              full;
   output              empty;
   output [1:0]        iq_rd;

   input [15:0]        fe_insn_in;
   input [15:0]        fe_pc_in;
   input [15:0]        fe_pc_pred_in;
   input [3:0]         fe_pr1sel_in;
   input [3:0]         fe_pr2sel_in;
   input [3:0]         fe_prdsel_in;
   input [3:0]         fe_pprdsel_in;
   input               rob_enq;
   input [1:0]         is_index_in;
   input               rob_issue;
   input [15:0]        wb_pc_redirect_in;
   input [15:0]        wb_r1data_in;
   input [15:0]        wb_r2data_in;
   input [15:0]        wb_rddata_in;
   input [1:0]         wb_index_in;
   input               rob_commit;
   input               rob_deq;

   output              cm_ready_out;
   output [1:0]        cm_rob_index;
   output [15:0]       cm_insn_out;
   output [15:0]       cm_pc_out;
   output [15:0]       cm_pc_pred_out;
   output [15:0]       cm_pc_redirect_out;
   output [15:0]       cm_r1data_out;
   output [15:0]       cm_r2data_out;
   output [15:0]       cm_rddata_out;
   output [3:0]        cm_pr1sel_out;
   output [3:0]        cm_pr2sel_out;
   output [3:0]        cm_prdsel_out;
   output [3:0]        cm_pprdsel_out;

   output [15:0]       iq0_insn_out;
   output [15:0]       iq1_insn_out;
   output [15:0]       iq2_insn_out;
   output [15:0]       iq3_insn_out;
   output [15:0]       iq0_pc_out;
   output [15:0]       iq1_pc_out;
   output [15:0]       iq2_pc_out;
   output [15:0]       iq3_pc_out;
   output [15:0]       iq0_pc_pred_out;
   output [15:0]       iq1_pc_pred_out;
   output [15:0]       iq2_pc_pred_out;
   output [15:0]       iq3_pc_pred_out;
   output [3:0]        iq0_pr1sel_out;
   output [3:0]        iq1_pr1sel_out;
   output [3:0]        iq2_pr1sel_out;
   output [3:0]        iq3_pr1sel_out;
   output [3:0]        iq0_pr2sel_out;
   output [3:0]        iq1_pr2sel_out;
   output [3:0]        iq2_pr2sel_out;
   output [3:0]        iq3_pr2sel_out;
   output [3:0]        iq0_prdsel_out;
   output [3:0]        iq1_prdsel_out;
   output [3:0]        iq2_prdsel_out;
   output [3:0]        iq3_prdsel_out;
   output [3:0]        iq_valid_out;
   output [3:0]        iq_issue_out;
   output [3:0]        iq_commit_out;

   wire                deq;
   wire                enq;
   wire                issue;
   wire                commit;

   assign full = (bundle_valid == 4'hf); 
   assign empty = (bundle_valid == 4'd0);

   assign deq = rob_deq & bundle_commit[rd] & bundle_valid[rd] & ~flush;
   assign issue = rob_issue & ~bundle_issue[is_index_in] & bundle_valid[is_index_in] & ~flush;
   assign commit = rob_commit & ~bundle_commit[wb_index_in] & bundle_valid[wb_index_in] & ~flush;
   assign enq = rob_enq & ~full & ~flush;

   wire [a-1:0]        rd_next;
   wire [a-1:0]        rd;
   wire                rd_we;
   assign rd_next = (flush) ? 2'd0 : rd + 2'd1;
   assign rd_we = deq | flush;
   Nbit_reg #(a, 2'd0)   rd_pointer (rd_next, rd, clk, rd_we, gwe, rst); 

   wire [a-1:0]        wr_next;
   wire [a-1:0]        wr;
   wire                wr_we;
   assign wr_next = (flush) ? 2'd0 : wr + 2'd1;
   assign wr_we = enq | flush;
   Nbit_reg #(a, 2'd0)   wr_pointer (wr_next, wr, clk, wr_we, gwe, rst); 

   genvar i;

   wire [n-1:0]         valid_next;
   wire [n-1:0]         bundle_valid;
   wire [n-1:0]         valid_after_deq;
   wire [n-1:0]         valid_after_enq;
   wire [n-1:0]         valid_after_;
   wire [n-1:0]         valid_after_flush;
   wire                 valid_we;
   assign valid_we = enq | deq | flush;
   for (i = 0; i < n; i = i + 1) 
      assign valid_after_deq[i] = (i == rd & deq) ? 1'b0 : bundle_valid[i];
   for (i = 0; i < n; i = i + 1)
      assign valid_after_enq[i] = (i == wr & enq) ? 1'b1 : bundle_valid[i];
   for (i = 0; i < n; i = i + 1)
      assign valid_after_[i] = (i == wr & enq) ? 1'b1 : valid_after_deq[i];
   assign valid_after_flush = 4'd0; 
   assign valid_next = (flush) ? valid_after_flush :
                       (deq & enq) ? valid_after_ : 
                       (deq) ? valid_after_deq :
                       (enq) ? valid_after_enq :
                       bundle_valid;
   assign valid_we = (enq | deq | flush);
   Nbit_reg #(n, 4'd0)   valid_bits (valid_next, bundle_valid, clk, valid_we, gwe, rst);
   assign iq_valid_out = bundle_valid;

   wire [n-1:0]         issue_next;
   wire [n-1:0]         bundle_issue;
   wire [n-1:0]         issue_after_enq;
   wire [n-1:0]         issue_after_issue;
   wire [n-1:0]         issue_after_;
   wire [n-1:0]         issue_after_flush;
   wire                 issue_we;
   for (i = 0; i < n; i = i + 1)
      assign issue_after_enq[i] = (i == wr & enq) ? 1'b0 : bundle_issue[i];
   for (i = 0; i < n; i = i + 1)
      assign issue_after_issue[i] = (i == is_index_in & issue) ? 1'b1 : bundle_issue[i];
   for (i = 0; i < n; i = i + 1)
      assign issue_after_[i] = (i == is_index_in & issue) ? 1'b1 : issue_after_enq[i];
   assign issue_after_flush = 4'd0; 
   assign issue_next = (flush) ? issue_after_flush :
                       (issue & enq) ? issue_after_ : 
                       (issue) ? issue_after_issue :
                       (enq) ? issue_after_enq :
                       bundle_issue;
   assign issue_we = (enq | issue | flush);
   Nbit_reg #(n, 4'd0)   issue_bits (issue_next, bundle_issue, clk, issue_we, gwe, rst);
   assign iq_issue_out = bundle_issue;
 
   wire [n-1:0]         commit_next;
   wire [n-1:0]         bundle_commit;
   wire [n-1:0]         commit_after_enq;
   wire [n-1:0]         commit_after_commit;
   wire [n-1:0]         commit_after_;
   wire [n-1:0]         commit_after_flush;
   wire                 commit_we;
   for (i = 0; i < n; i = i + 1)
      assign commit_after_enq[i] = (i == wr & enq) ? 1'b0 : bundle_commit[i];
   for (i = 0; i < n; i = i + 1)
      assign commit_after_commit[i] = (i == wb_index_in & commit) ? 1'b1 : bundle_commit[i];
   for (i = 0; i < n; i = i + 1)
      assign commit_after_[i] = (i == wb_index_in & commit) ? 1'b1 : commit_after_enq[i];
   assign commit_after_flush = 4'd0; 
   assign commit_next = (flush) ? commit_after_flush :
                        (commit & enq) ? commit_after_ : 
                        (commit) ? commit_after_commit :
                        (enq) ? commit_after_enq :
                        bundle_commit;
   assign commit_we = (enq | commit | flush);
   Nbit_reg #(n, 4'd0)   commit_bits (commit_next, bundle_commit, clk, commit_we, gwe, rst);
   assign iq_commit_out = bundle_commit;

// Data Section
   ram_4r1w insn_ram (.clk(clk), .gwe(gwe), .rst(rst), .r1sel(2'd0), .r1data(iq0_insn_out), .r2sel(2'd1), .r2data(iq1_insn_out), 
                                                       .r3sel(2'd2), .r3data(iq2_insn_out), .r4sel(2'd3), .r4data(iq3_insn_out), .wsel(wr), .wdata(fe_insn_in), .we(enq));

   ram_4r1w pc_ram (.clk(clk), .gwe(gwe), .rst(rst), .r1sel(2'd0), .r1data(iq0_pc_out), .r2sel(2'd1), .r2data(iq1_pc_out), 
                                                     .r3sel(2'd2), .r3data(iq2_pc_out), .r4sel(2'd3), .r4data(iq3_pc_out), .wsel(wr), .wdata(fe_pc_in), .we(enq));

   ram_4r1w pc_pred_ram (.clk(clk), .gwe(gwe), .rst(rst), .r1sel(2'd0), .r1data(iq0_pc_pred_out), .r2sel(2'd1), .r2data(iq1_pc_pred_out), 
                                                          .r3sel(2'd2), .r3data(iq2_pc_pred_out), .r4sel(2'd3), .r4data(iq3_pc_pred_out), .wsel(wr), .wdata(fe_pc_pred_in), .we(enq));

   ram_4r1w #(4, 2) pr1sel_ram (.clk(clk), .gwe(gwe), .rst(rst), .r1sel(2'd0), .r1data(iq0_pr1sel_out), .r2sel(2'd1), .r2data(iq1_pr1sel_out), 
                                                                 .r3sel(2'd2), .r3data(iq2_pr1sel_out), .r4sel(2'd3), .r4data(iq3_pr1sel_out), .wsel(wr), .wdata(fe_pr1sel_in), .we(enq));

   ram_4r1w #(4, 2) pr2sel_ram (.clk(clk), .gwe(gwe), .rst(rst), .r1sel(2'd0), .r1data(iq0_pr2sel_out), .r2sel(2'd1), .r2data(iq1_pr2sel_out), 
                                                                 .r3sel(2'd2), .r3data(iq2_pr2sel_out), .r4sel(2'd3), .r4data(iq3_pr2sel_out), .wsel(wr), .wdata(fe_pr2sel_in), .we(enq));

   ram_4r1w #(4, 2) prdsel_ram (.clk(clk), .gwe(gwe), .rst(rst), .r1sel(2'd0), .r1data(iq0_prdsel_out), .r2sel(2'd1), .r2data(iq1_prdsel_out), 
                                                                 .r3sel(2'd2), .r3data(iq2_prdsel_out), .r4sel(2'd3), .r4data(iq3_prdsel_out), .wsel(wr), .wdata(fe_prdsel_in), .we(enq));

   wire [3:0] iq0_pprdsel_out, iq1_pprdsel_out, iq2_pprdsel_out, iq3_pprdsel_out;
   ram_4r1w #(4, 2) pprdsel_ram (.clk(clk), .gwe(gwe), .rst(rst), .r1sel(2'd0), .r1data(iq0_pprdsel_out), .r2sel(2'd1), .r2data(iq1_pprdsel_out), 
                                                                  .r3sel(2'd2), .r3data(iq2_pprdsel_out), .r4sel(2'd3), .r4data(iq3_pprdsel_out), .wsel(wr), .wdata(fe_pprdsel_in), .we(enq));

   ram_1r1w pc_redirect_ram (.clk(clk), .gwe(gwe), .rst(rst), .rsel(rd), .rdata(cm_pc_redirect_out), 
                                                              .wsel(wb_index_in), .wdata(wb_pc_redirect_in), .we(commit));
   
   ram_1r1w r1data_ram (.clk(clk), .gwe(gwe), .rst(rst), .rsel(rd), .rdata(cm_r1data_out), 
                                                         .wsel(wb_index_in), .wdata(wb_r1data_in), .we(commit));
   ram_1r1w r2data_ram (.clk(clk), .gwe(gwe), .rst(rst), .rsel(rd), .rdata(cm_r2data_out), 
                                                         .wsel(wb_index_in), .wdata(wb_r2data_in), .we(commit));
   ram_1r1w rddata_ram (.clk(clk), .gwe(gwe), .rst(rst), .rsel(rd), .rdata(cm_rddata_out), 
                                                         .wsel(wb_index_in), .wdata(wb_rddata_in), .we(commit));

// Commit Logic
   assign cm_ready_out = bundle_commit[rd] & bundle_valid[rd];
   mux_Nbit_4to1 #(16) cm_insn_mux (.out(cm_insn_out), .a(iq0_insn_out), .b(iq1_insn_out), .c(iq2_insn_out), .d(iq3_insn_out), .sel(rd));
   mux_Nbit_4to1 #(16) cm_pc_mux (.out(cm_pc_out), .a(iq0_pc_out), .b(iq1_pc_out), .c(iq2_pc_out), .d(iq3_pc_out), .sel(rd));
   mux_Nbit_4to1 #(16) cm_pc_pred_mux (.out(cm_pc_pred_out), .a(iq0_pc_pred_out), .b(iq1_pc_pred_out), .c(iq2_pc_pred_out), .d(iq3_pc_pred_out), .sel(rd));
   mux_Nbit_4to1 #(4) cm_pr1sel_mux (.out(cm_pr1sel_out), .a(iq0_pr1sel_out), .b(iq1_pr1sel_out), .c(iq2_pr1sel_out), .d(iq3_pr1sel_out), .sel(rd));
   mux_Nbit_4to1 #(4) cm_pr2sel_mux (.out(cm_pr2sel_out), .a(iq0_pr2sel_out), .b(iq1_pr2sel_out), .c(iq2_pr2sel_out), .d(iq3_pr2sel_out), .sel(rd));
   mux_Nbit_4to1 #(4) cm_prdsel_mux (.out(cm_prdsel_out), .a(iq0_prdsel_out), .b(iq1_prdsel_out), .c(iq2_prdsel_out), .d(iq3_prdsel_out), .sel(rd));
   mux_Nbit_4to1 #(4) cm_pprdsel_mux (.out(cm_pprdsel_out), .a(iq0_pprdsel_out), .b(iq1_pprdsel_out), .c(iq2_pprdsel_out), .d(iq3_pprdsel_out), .sel(rd));

   assign cm_rob_index = rd;

endmodule
                       
