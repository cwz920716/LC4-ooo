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

   /*** YOUR CODE HERE ***/

   // Start with pc & fetch logic
   wire          F_valid;
   wire [15:0]   F_pc;
   wire [15:0]   F_pc_pred;
   wire [15:0]   F_imem_out;
   wire [15:0]   F_imem_addr;
   wire [15:0]   F_insn;
   wire [2:0]    F_r1, F_r2, F_rd;
   wire F_mam;
   
   // RFC: Add Branch Redirect Logic
   wire F_pc_stall;

   lc4_fetch_stage fetch (.pc(F_pc),
                          .imem_out(imem_out), .imem_addr(imem_addr),
                          .insn(F_insn), .pc_pred(F_pc_pred), 
                          .r1(F_r1), .r2(F_r2), .rd(F_rd),
                          .rob_full(ROB_full), .fl_full(FL_full), .mam(F_mam),
                          .stall(F_pc_stall), .fl_alloc(FL_alloc),
                          .iq0_insn(ROB_iq0_insn), .iq1_insn(ROB_iq1_insn), .iq2_insn(ROB_iq2_insn), .iq3_insn(ROB_iq3_insn),
                          .iq_valid(ROB_valid), .iq_issue(ROB_issue), .iq_commit(ROB_commit));

   Nbit_reg #(16, 16'h8200) pc_reg (.in(F_pc_pred), .out(F_pc), .clk(clk), .we(~F_pc_stall), .gwe(gwe), .rst(rst));

   // Rename Table
   wire RT_flush;
   assign RT_flush = 1'b0;
   wire [3:0] RT_pr1sel, RT_pr2sel, RT_pprdsel;
   lc4_rename_table rename_table (.clk(clk), .gwe(gwe), .rst(rst), .flush(RT_flush), .r1sel(F_r1), .r1psel(RT_pr1sel), 
                                                                                     .r2sel(F_r2), .r2psel(RT_pr2sel), 
                                                                                     .r3sel(F_rd), .r3psel(RT_pprdsel), 
                                                                                     .wsel(F_rd), .wpsel(FL_next), .we(FL_alloc));

   // Free List
   wire FL_flush;
   wire FL_alloc;
   wire FL_full;
   wire [3:0] FL_next;
   assign FL_flush = 1'b0;
   lc4_free_list free_list (.clk(clk), .gwe(gwe), .rst(rst), .flush(FL_flush), .alloc(FL_alloc), .dealloc(C_regfile_we), .cpr(C_pprd), .full(FL_full), .next(FL_next));

   // Reorder Buffer ROB, aka instruction queue
   wire ROB_flush;
   wire ROB_full;
   wire ROB_enq;
   wire [1:0] ROB_rd;

   assign ROB_enq = ~F_pc_stall;

   wire [15:0] ROB_iq0_insn, ROB_iq1_insn, ROB_iq2_insn, ROB_iq3_insn;
   wire [15:0] ROB_iq0_pc, ROB_iq1_pc, ROB_iq2_pc, ROB_iq3_pc;
   wire [15:0] ROB_iq0_pc_pred, ROB_iq1_pc_pred, ROB_iq2_pc_pred, ROB_iq3_pc_pred;
   wire [3:0] ROB_iq0_pr1sel, ROB_iq1_pr1sel, ROB_iq2_pr1sel, ROB_iq3_pr1sel;
   wire [3:0] ROB_iq0_pr2sel, ROB_iq1_pr2sel, ROB_iq2_pr2sel, ROB_iq3_pr2sel;
   wire [3:0] ROB_iq0_prdsel, ROB_iq1_prdsel, ROB_iq2_prdsel, ROB_iq3_prdsel;
   wire [3:0] ROB_valid, ROB_issue, ROB_commit;
   // wire [1:0] ROB_iq_rd;

   // RFC: Add Flush for mis-pred
   assign ROB_flush = 1'b0;
   lc4_reorder_buffer reorder_buffer (.clk(clk), .gwe(gwe), .rst(rst), .flush(ROB_flush),
                                      .full(ROB_full),
                                      .fe_insn_in(F_insn), .fe_pc_in(F_pc), .fe_pc_pred_in(F_pc_pred), .rob_enq(ROB_enq),
                                      .fe_pr1sel_in(RT_pr1sel), .fe_pr2sel_in(RT_pr2sel), .fe_prdsel_in(FL_next), .fe_pprdsel_in(RT_pprdsel),
                                      .is_index_in(I_rob_index), .rob_issue(I_valid),
                                      .wb_pc_redirect_in(W_pc_redirect), .wb_r1data_in(W_r1data), .wb_r2data_in(W_r2data), .wb_rddata_in(W_rddata), 
                                      .wb_index_in(W_rob_index), .rob_commit(W_valid),
                                      .rob_deq(C_valid),
                                      .cm_ready_out(C_valid), .cm_insn_out(C_insn), .cm_pc_out(C_pc), .cm_pc_pred_out(C_pc_pred), .cm_rob_index(ROB_rd),
                                      .cm_pc_redirect_out(C_pc_redirect), .cm_r1data_out(C_r1data), .cm_r2data_out(C_r2data), .cm_rddata_out(C_rddata),
                                      .cm_prdsel_out(C_prd), .cm_pprdsel_out(C_pprd),
                                      .iq0_insn_out(ROB_iq0_insn), .iq1_insn_out(ROB_iq1_insn), .iq2_insn_out(ROB_iq2_insn), .iq3_insn_out(ROB_iq3_insn),
                                      .iq0_pc_out(ROB_iq0_pc), .iq1_pc_out(ROB_iq1_pc), .iq2_pc_out(ROB_iq2_pc), .iq3_pc_out(ROB_iq3_pc),
                                      .iq0_pc_pred_out(ROB_iq0_pc_pred), .iq1_pc_pred_out(ROB_iq1_pc_pred), .iq2_pc_pred_out(ROB_iq2_pc_pred), .iq3_pc_pred_out(ROB_iq3_pc_pred), 
                                      .iq0_pr1sel_out(ROB_iq0_pr1sel), .iq1_pr1sel_out(ROB_iq1_pr1sel), .iq2_pr1sel_out(ROB_iq2_pr1sel), .iq3_pr1sel_out(ROB_iq3_pr1sel), 
                                      .iq0_pr2sel_out(ROB_iq0_pr2sel), .iq1_pr2sel_out(ROB_iq1_pr2sel), .iq2_pr2sel_out(ROB_iq2_pr2sel), .iq3_pr2sel_out(ROB_iq3_pr2sel), 
                                      .iq0_prdsel_out(ROB_iq0_prdsel), .iq1_prdsel_out(ROB_iq1_prdsel), .iq2_prdsel_out(ROB_iq2_prdsel), .iq3_prdsel_out(ROB_iq3_prdsel),
                                      .iq_valid_out(ROB_valid), .iq_issue_out(ROB_issue), .iq_commit_out(ROB_commit));

   // Issue
   wire I_valid, I_is_a_type, I_is_l_type;
   wire [15:0] I_r1bypass, I_r2bypass, I_insn, I_pc, I_pc_pred;
   wire [3:0] I_pr1sel, I_pr2sel, I_prd;
   wire [1:0] I_rob_index;

   lc4_issue_stage issue (.iq0_insn(ROB_iq0_insn), .iq1_insn(ROB_iq1_insn), .iq2_insn(ROB_iq2_insn), .iq3_insn(ROB_iq3_insn),
                          .iq0_pr1(ROB_iq0_pr1sel), .iq1_pr1(ROB_iq1_pr1sel), .iq2_pr1(ROB_iq2_pr1sel), .iq3_pr1(ROB_iq3_pr1sel),
                          .iq0_pr2(ROB_iq0_pr2sel), .iq1_pr2(ROB_iq1_pr2sel), .iq2_pr2(ROB_iq2_pr2sel), .iq3_pr2(ROB_iq3_pr2sel),
                          .iq0_prd(ROB_iq0_prdsel), .iq1_prd(ROB_iq1_prdsel), .iq2_prd(ROB_iq2_prdsel), .iq3_prd(ROB_iq3_prdsel),
                          .iq0_pc(ROB_iq0_pc), .iq1_pc(ROB_iq1_pc), .iq2_pc(ROB_iq2_pc), .iq3_pc(ROB_iq3_pc),
                          .iq0_pc_pred(ROB_iq0_pc_pred), .iq1_pc_pred(ROB_iq1_pc_pred), .iq2_pc_pred(ROB_iq2_pc_pred), .iq3_pc_pred(ROB_iq3_pc_pred),
                          .iq_valid(ROB_valid), .iq_issue(ROB_issue), .iq_commit(ROB_commit), .iq_rd(ROB_rd),
                          .a0_ref(A0_valid & A0_regfile_we), .a0_prd(A0_prd), .a0_rddata(A0_exec_out),
                          .l0_ref(L0_valid & L0_regfile_we), .l0_prd(L0_prd), .l0_ready(~L0_is_load), .l0_rddata(L0_exec_out), .l0_struct(L0_valid),
                          .l1_ref(L1_valid & L1_regfile_we), .l1_prd(L1_prd), .l1_rddata(L1_rddata),
                          .wb_ref(W_valid & W_regfile_we), .wb_prd(W_prd), .wb_rddata(W_rddata),
                          .is_r1data(I_r1data), .is_r2data(I_r2data),
                          .is_valid(I_valid), .is_rob_index(I_rob_index), .is_pr1sel(I_pr1sel), .is_pr2sel(I_pr2sel),
                          .is_r1bypass(I_r1bypass), .is_r2bypass(I_r2bypass),
                          .is_insn(I_insn), .is_pc(I_pc), .is_pc_pred(I_pc_pred), .is_prd(I_prd), .is_is_a_type(I_is_a_type), .is_is_l_type(I_is_l_type), .is_mem_out(I_mem));

   // Regfile 
   wire [7:0] PRF_valid;
   wire PRF_flush;
   wire [15:0] I_r1data, I_r2data;
   wire [2:0] I_nzp;

   assign PRF_flush = 1'b0;
   lc4_ooo_regfile ooo_regfile (.clk(clk), .gwe(gwe), .rst(rst), .flush(PRF_flush), 
                                .r1sel(I_pr1sel), .r1data(I_r1data), .r2sel(I_pr2sel), .r2data(I_r2data), .nzp_out(I_nzp),
                                .prf_wsel(W_prd), .prf_wdata(W_rddata), .prf_we(W_regfile_we), .prf_nzp_in(W_nzp), .prf_nzp_we(W_nzp_we), 
                                .arf_wsel(C_rd), .arf_wdata(C_rddata), .arf_we(C_regfile_we), .arf_nzp_in(C_nzp), .arf_nzp_we(C_nzp_we));

   // A0 Stage
   wire IA_stall, IA_flush, IA_valid;
   assign IA_stall = 1'b0;
   assign IA_flush = 1'b0;
   assign IA_valid = I_valid & I_is_a_type;
 
   wire A0_valid;
   wire [15:0] A0_insn, A0_pc, A0_pc_pred, A0_r1data, A0_r2data, A0_exec_out;
   wire [1:0] A0_rob_index;
   wire A0_regfile_we;
   wire [3:0] A0_prd;

   lc4_pipeline_latch IA_latch (.clk(clk), .gwe(gwe), .rst(rst), .stall(IA_stall), .flush(IA_flush), 
                                .valid_in(IA_valid), 
                                .insn_in(I_insn), .pc_in(I_pc), .pc_pred_in(I_pc_pred), 
                                .r1data_in(I_r1bypass), .r2data_in(I_r2bypass), .rob_index_in(I_rob_index),
                                .prd_in(I_prd),
                                .valid_out(A0_valid), 
                                .insn_out(A0_insn), .pc_out(A0_pc), .pc_pred_out(A0_pc_pred), 
                                .r1data_out(A0_r1data), .r2data_out(A0_r2data), .rob_index_out(A0_rob_index),
                                .prd_out(A0_prd));

   lc4_arith_stage arith (.insn(A0_insn), .pc(A0_pc), .r1data(A0_r1data), .r2data(A0_r2data),
                          .exec_out(A0_exec_out), .regfile_we(A0_regfile_we));

   wire AW_stall, AW_flush;
   assign AW_stall = 1'b0;
   assign AW_flush = 1'b0;

   wire AW_valid;
   wire [15:0] AW_insn, AW_pc, AW_pc_pred, AW_exec, AW_r1data, AW_r2data;
   wire [1:0] AW_rob_index;
   wire [3:0] AW_prd;
   lc4_pipeline_latch AW_latch (.clk(clk), .gwe(gwe), .rst(rst), .stall(AW_stall), .flush(AW_flush), 
                                .valid_in(A0_valid), 
                                .insn_in(A0_insn), .pc_in(A0_pc), .pc_pred_in(A0_pc_pred), 
                                .r1data_in(A0_r1data), .r2data_in(A0_r2data), .rob_index_in(A0_rob_index), .exec_in(A0_exec_out),
                                .prd_in(A0_prd),
                                .valid_out(AW_valid), 
                                .insn_out(AW_insn), .pc_out(AW_pc), .pc_pred_out(AW_pc_pred), 
                                .r1data_out(AW_r1data), .r2data_out(AW_r2data), .rob_index_out(AW_rob_index), .exec_out(AW_exec),
                                .prd_out(AW_prd));

   // L0 stage
   wire IL_stall, IL_flush, IL_valid;
   assign IL_stall = 1'b0;
   assign IL_flush = 1'b0;
   assign IL_valid = I_valid & I_is_l_type;
 
   wire L0_valid;
   wire [15:0] L0_insn, L0_pc, L0_pc_pred, L0_r1data, L0_r2data, L0_exec_out;
   wire [1:0] L0_rob_index;
   wire L0_regfile_we, L0_is_load;
   wire [3:0] L0_prd;

   lc4_pipeline_latch IL_latch (.clk(clk), .gwe(gwe), .rst(rst), .stall(IA_stall), .flush(IA_flush), 
                                .valid_in(IL_valid), 
                                .insn_in(I_insn), .pc_in(I_pc), .pc_pred_in(I_pc_pred), 
                                .r1data_in(I_r1bypass), .r2data_in(I_r2bypass), .rob_index_in(I_rob_index),
                                .prd_in(I_prd),
                                .valid_out(L0_valid), 
                                .insn_out(L0_insn), .pc_out(L0_pc), .pc_pred_out(L0_pc_pred), 
                                .r1data_out(L0_r1data), .r2data_out(L0_r2data), .rob_index_out(L0_rob_index),
                                .prd_out(L0_prd));

   lc4_load0_stage load0 (.insn(L0_insn), .pc(L0_pc), .r1data(L0_r1data), .r2data(L0_r2data),
                          .exec_out(L0_exec_out), .is_load(L0_is_load), .regfile_we(L0_regfile_we));

   wire L01_stall, L01_flush;
   assign L01_stall = 1'b0;
   assign L01_flush = 1'b0;

   wire L1_valid;
   wire [15:0] L1_insn, L1_pc, L1_pc_pred, L1_exec, L1_r1data, L1_r2data;
   wire [1:0] L1_rob_index;
   lc4_pipeline_latch L01_latch (.clk(clk), .gwe(gwe), .rst(rst), .stall(L01_stall), .flush(L01_flush), 
                                 .valid_in(L0_valid), 
                                 .insn_in(L0_insn), .pc_in(A0_pc), .pc_pred_in(L0_pc_pred), 
                                 .r1data_in(L0_r1data), .r2data_in(L0_r2data), .rob_index_in(L0_rob_index), .exec_in(L0_exec_out),
                                 .prd_in(L0_prd),
                                 .valid_out(L1_valid), 
                                 .insn_out(L1_insn), .pc_out(L1_pc), .pc_pred_out(L1_pc_pred), 
                                 .r1data_out(L1_r1data), .r2data_out(L1_r2data), .rob_index_out(L1_rob_index), .exec_out(L1_exec),
                                 .prd_out(L1_prd));

   wire L1_dmem_we, L1_is_load, L1_regfile_we;
   wire [15:0] L1_dmem_addr, L1_rddata;
   wire [3:0] L1_prd;

   // RFC: Add memory address logic
   lc4_load1_stage load1 (.insn(L1_insn), .exec_out(L1_exec), .dmem_out(dmem_out),
                          .dmem_addr(L1_dmem_addr), .dmem_we(L1_dmem_we), .rddata(L1_rddata),
                          .is_load(L1_is_load), .regfile_we(L1_regfile_we));

   // RFC: LW
   wire LW_stall, LW_flush;
   assign LW_stall = 1'b0;
   assign LW_flush = 1'b0;

   wire LW_valid;
   wire [15:0] LW_insn, LW_pc, LW_pc_pred, LW_exec, LW_r1data, LW_r2data, LW_dmem;
   wire [1:0] LW_rob_index;
   wire [3:0] LW_prd;
   lc4_pipeline_latch LW_latch (.clk(clk), .gwe(gwe), .rst(rst), .stall(LW_stall), .flush(LW_flush), 
                                .valid_in(L1_valid), 
                                .insn_in(L1_insn), .pc_in(L1_pc), .pc_pred_in(L1_pc_pred), 
                                .r1data_in(L1_r1data), .r2data_in(L1_r2data), .rob_index_in(L1_rob_index), .exec_in(L1_exec), .dmem_in(L1_rddata),
                                .prd_in(L1_prd),
                                .valid_out(LW_valid), 
                                .insn_out(LW_insn), .pc_out(LW_pc), .pc_pred_out(LW_pc_pred), 
                                .r1data_out(LW_r1data), .r2data_out(LW_r2data), .rob_index_out(LW_rob_index), .exec_out(LW_exec), .dmem_out(LW_dmem),
                                .prd_out(LW_prd));

   // Write-Back Stage
   wire W_valid, W_regfile_we, W_nzp_we;
   wire [15:0] W_pc_redirect, W_r1data, W_r2data, W_rddata;
   wire [1:0] W_rob_index;
   wire [2:0] W_nzp;
   wire [3:0] W_prd;
   // RFC: PC Branch
   lc4_writeback_stage write (.AW_valid(AW_valid), .LW_valid(LW_valid), 
                              .AW_rob_index(AW_rob_index), .LW_rob_index(LW_rob_index),
                              .AW_prd(AW_prd), .LW_prd(LW_prd),
                              .AW_insn(AW_insn), .LW_insn(LW_insn),
                              .AW_rddata(AW_exec), .LW_rddata(LW_dmem),
                              .AW_r1data(AW_r1data), .AW_r2data(AW_r2data), .LW_r1data(LW_r1data), .LW_r2data(LW_r2data),
                              .AW_pc_redirect(AW_pc_pred), .LW_pc_redirect(LW_pc_pred),
                              .W_valid(W_valid), .W_rob_index(W_rob_index), .W_pc_redirect(W_pc_redirect), 
                              .W_r1data(W_r1data), .W_r2data(W_r2data), .W_rddata(W_rddata),
                              .W_prd(W_prd), .W_nzp(W_nzp), .W_regfile_we(W_regfile_we), .W_nzp_we(W_nzp_we));

   // Commit Stage
   wire C_valid, C_regfile_we, C_is_store, C_insn_is_store, C_is_load, C_insn_is_load, C_nzp_we, C_insn_regfile_we, C_insn_nzp_we;
   wire [2:0] C_rd, C_nzp;
   wire [3:0] C_prd, C_pprd;
   wire [15:0] C_insn, C_pc, C_pc_pred, C_pc_redirect, C_r1data, C_r2data, C_rddata;

   assign C_regfile_we = C_valid & C_insn_regfile_we;
   assign C_nzp_we = C_valid & C_insn_nzp_we;
   assign C_is_store = C_valid & C_insn_is_store;
   assign C_is_load = C_valid & C_insn_is_load;
   lc4_decoder C_decoder (.insn(C_insn), .wsel(C_rd), .regfile_we(C_insn_regfile_we), .nzp_we(C_insn_nzp_we), .is_store(C_insn_is_store), .is_load(C_insn_is_load));
   assign C_nzp = (C_rddata == 16'd0) ? (3'b010) :
                  (C_rddata[15] == 1'b1) ? (3'b100) : (3'b001);
   assign dmem_in = C_r2data;
   assign dmem_addr = (C_is_store & C_valid) ? C_rddata :
                      (L1_is_load & L1_valid) ? L1_dmem_addr :
                      16'h0000;
   assign dmem_we = (C_is_store) ? 1'b1 : 1'b0;
   // RFC: Branch Logic ???

   // Test Logic
   wire [15:0] C_mem_out;
   wire [3:0] I_mem;
   lc4_ldr_str test_mem (C_insn, C_r1data, C_mem_out);
   assign test_stall = (C_valid) ? (2'd0) : 2'd3;			// Testbench: is this is stall cycle? (don't compare the test values)
   assign test_pc = C_pc;							// Testbench: program counter
   assign test_insn = C_insn; 					// Testbench: instruction bits
   assign test_regfile_we = C_regfile_we;	// Testbench: register file write enable
   assign test_regfile_reg = C_rd;		// Testbench: which register to write in the register file 
   assign test_regfile_in = C_rddata;			// Testbench: value to write into the register file
   assign test_nzp_we = C_nzp_we;				// Testbench: NZP condition codes write enable
   assign test_nzp_in = C_nzp;      			// Testbench: value to write to NZP bits
   assign test_dmem_we = dmem_we;			// Testbench: data memory write enable
   assign test_dmem_addr = (C_is_load | C_is_store) ? C_mem_out : 16'h0000;  	// Testbench: address to read/write memory
   assign test_dmem_value = C_is_store ? C_r2data : (C_is_load ? C_rddata : 16'h0000);	// Testbench: value read/writen from/to memory
 
`define CYCLE_TRACE "out.cycles"
`ifdef CYCLE_TRACE
   integer     output_file;
   
   initial begin
      output_file = $fopen(`CYCLE_TRACE, "w");
   end
   
   always @(posedge gwe) begin
      $fdisplay(output_file, "%h eq%b %d %d %d %d is%b wb%b cm%b x%b %b", F_pc, 
                              // ROB_iq0_pc, ROB_iq1_pc, ROB_iq2_pc, ROB_iq3_pc, ROB_valid, ROB_issue, ROB_commit, 
                              ROB_enq, RT_pr1sel, RT_pr2sel, FL_next, RT_pprdsel, I_valid, W_valid, C_valid, ROB_valid & ROB_commit, I_mem);
   end
`endif

   // For on-board debugging, the LEDs and segment-segment display can
   // be configured to display useful information.  The below code
   // assigns the four hex digits of the seven-segment display to either
   // the PC or instruction, based on how the switches are set.
   
   assign seven_segment_data = (switch_data[6:0] == 7'd0) ? F_pc :
                               (switch_data[6:0] == 7'd1) ? imem_out :
                               (switch_data[6:0] == 7'd2) ? dmem_addr :
                               (switch_data[6:0] == 7'd3) ? dmem_out :
                               (switch_data[6:0] == 7'd4) ? dmem_in :
                               /*else*/ 16'hDEAD;
   assign led_data = switch_data;
   
endmodule

