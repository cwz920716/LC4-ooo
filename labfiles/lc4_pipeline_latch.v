`timescale 1ns / 1ps

module lc4_pipeline_latch(input          clk,
                          input          gwe,
                          input          rst,
                          input          stall,
                          input          flush,

                          input [15:0]   insn_in,
                          input [15:0]   pc_in,
                          input [15:0]   pc_pred_in,
                          input [15:0]   pc_redirect_in,
                          input [15:0]   r1data_in,
                          input [15:0]   r2data_in,  
                          input [15:0]   exec_in,   
                          input [15:0]   dmem_in,
                          input          valid_in,
                          input [1:0]    rob_index_in,
                          input [3:0]    prd_in,
	
                          output [15:0]  insn_out,
                          output [15:0]  pc_out,
                          output [15:0]  pc_pred_out,
                          output [15:0]  pc_redirect_out,
                          output [15:0]  r1data_out,
                          output [15:0]  r2data_out,
                          output [15:0]  exec_out,
                          output [15:0]  dmem_out,
                          output         valid_out,
                          output [1:0]   rob_index_out,
                          output [3:0]   prd_out);
	
	
   wire [15:0]    insn_in_temp;
   wire [15:0]    pc_in_temp;
   wire [15:0]    pc_pred_in_temp;
   wire [15:0]    pc_redirect_in_temp;
   wire [15:0]    r1data_in_temp;
   wire [15:0]    r2data_in_temp;
   wire [15:0]    exec_in_temp;
   wire [15:0]    dmem_in_temp;
   wire [1:0]     rob_index_in_temp;
   wire [3:0]     prd_in_temp;
	
   wire           is_nop = flush | !valid_in | rst;

   // Inserting NOPs
   assign insn_in_temp = (is_nop) ? 16'd0 : insn_in;
   assign pc_in_temp = (is_nop) ? 16'd0 : pc_in;
   assign pc_pred_in_temp = (is_nop) ? 16'd0 : pc_pred_in;
   assign pc_redirect_in_temp = (is_nop) ? 16'd0 : pc_redirect_in;
   assign r1data_in_temp = (is_nop) ? 16'd0 : r1data_in;
   assign r2data_in_temp = (is_nop) ? 16'd0 : r2data_in;
   assign exec_in_temp = (is_nop) ? 16'd0 : exec_in;
   assign dmem_in_temp = (is_nop) ? 16'd0 : dmem_in;
   assign rob_index_in_temp = (is_nop) ? 2'd0 : rob_index_in;
   assign prd_in_temp = (is_nop) ? 4'd0 : prd_in;
	
   // WE for Latch
   wire we;
   assign we = ~stall;
	
   // Registers
   parameter n = 16;
   
   Nbit_reg #(n) insn (insn_in_temp, insn_out, clk, (we), gwe, rst);
   Nbit_reg #(n) pc (pc_in_temp, pc_out, clk, (we), gwe, rst);
   Nbit_reg #(n) pc_pred (pc_pred_in_temp, pc_pred_out, clk, (we), gwe, rst);
   Nbit_reg #(n) pc_redirect (pc_redirect_in_temp, pc_redirect_out, clk, (we), gwe, rst);
   Nbit_reg #(n) r1data (r1data_in_temp, r1data_out, clk, (we), gwe, rst);
   Nbit_reg #(n) r2data (r2data_in_temp, r2data_out, clk, (we), gwe, rst);
   Nbit_reg #(n) exec (exec_in_temp, exec_out, clk, (we), gwe, rst);
   Nbit_reg #(n) dmem (dmem_in_temp, dmem_out, clk, (we), gwe, rst);
   Nbit_reg #(2) rob_index (rob_index_in_temp, rob_index_out, clk, (we), gwe, rst);
   Nbit_reg #(4) prd (prd_in_temp, prd_out, clk, (we), gwe, rst);
   Nbit_reg #(1) valid (~is_nop, valid_out, clk, (we), gwe, rst);
   	
endmodule
