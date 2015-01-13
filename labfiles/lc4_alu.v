`timescale 1ns / 1ps

module lc4_alu(insn, pc, r1data, r2data, out);
   
   input [15:0] insn, pc, r1data, r2data;
   output [15:0] out;
   
   /*** YOUR CODE HERE ***/
   wire[15:0] arith_out;
   wire[15:0] logic_out;
   wire[15:0] branch_out;
   wire[15:0] shift_out;
   wire[15:0] rti_jmpr_jsrr_out;
   wire[15:0] mem_out;
   wire[15:0] const_out;
   wire[15:0] jmp_out;
   wire[15:0] hiconst_out;
   wire[15:0] trap_out;
   wire[15:0] compare_out;
   wire[15:0] jsr_out;
	 
   wire[3:0] op_sel_4;
   wire[4:0] op_sel_5;
	 
   assign op_sel_4 = insn[15:12];
   assign op_sel_5 = insn[15:11];
	 
   lc4_arith arith(insn, r1data, r2data, arith_out);
   lc4_logic log(insn, r1data, r2data, logic_out);
   lc4_alu_branch branch(insn, pc, branch_out);
   lc4_shift shift(insn, r1data, r2data, shift_out);
   lc4_rti_jmpr_jsrr jumpr(r1data, rti_jmpr_jsrr_out);
   lc4_ldr_str mem(insn, r1data, mem_out);
   lc4_const const(insn, const_out);
   lc4_jmp jmp(insn, pc, jmp_out);
   lc4_hi_const hiconst(insn, r1data, hiconst_out);
   lc4_trap trap(insn, trap_out);
   lc4_compare cmp(insn, r1data, r2data, compare_out);
   lc4_jsr jsr(insn, pc, jsr_out);
	 
   // opcode decoder
   assign out = (op_sel_4 == 4'd1) ? (arith_out) :
                (op_sel_4 == 4'd5) ? (logic_out) : 
                (op_sel_4 == 4'd0) ? (branch_out) : 
                (op_sel_5 == 5'b01000) ? (rti_jmpr_jsrr_out) :
                (op_sel_4 == 4'b0111) ? (mem_out) :
                (op_sel_4 == 4'b0110) ? (mem_out) :
                (op_sel_4 == 4'b1000) ? (rti_jmpr_jsrr_out) :
                (op_sel_4 == 4'b1001) ? (const_out) :
                (op_sel_5 == 5'b11000) ? (rti_jmpr_jsrr_out) :
                (op_sel_5 == 5'b11001) ? (jmp_out) :
                (op_sel_4 == 4'b1101) ? (hiconst_out) :
                (op_sel_4 == 4'b1111) ? (trap_out) :
                (op_sel_4 == 4'b1010) ? (shift_out) : 
                (op_sel_4 == 4'b0010) ? (compare_out) : 
                (op_sel_5 == 5'b01001) ? (jsr_out) : 16'b0;

endmodule

/* SEXT (IMM5)  */
module sext_imm5 (in, out);

   input [15:0] in;
   output [15:0] out;
	
   assign out = (in[4] == 1'b0) ? (16'b0000000000011111 & in) : (16'b1111111111100000 | in);
	
endmodule

/* SEXT (IMM6) */
module sext_imm6 (in, out);

   input[15:0] in;
   output[15:0] out;
	
   assign out = (in[5] == 1'b0) ? (16'b0000000000111111 & in) : (16'b1111111111000000 | in);
	
endmodule

/* SEXT (IMM7) */
module sext_imm7 (in, out);

   input[15:0] in;
   output[15:0] out;
	
   assign out = (in[6] == 1'b0) ? (16'b0000000001111111 & in) : (16'b1111111110000000 | in);

endmodule

/* SEXT (IMM9) */
module sext_imm9 (in, out);

   input[15:0] in;
   output[15:0] out;
	
   assign out = (in[8] == 1'b0) ? (16'b0000000111111111 & in) : (16'b1111111000000000 | in);

endmodule

/* SEXT (IMM11) */
module sext_imm11 (in, out);

   input[15:0] in;
   output[15:0] out;
	
   assign out = (in[10] == 1'b0) ? (16'b0000011111111111 & in) : (16'b1111100000000000 | in);

endmodule

/* BRANCH MODULE */
module lc4_alu_branch (insn, pc, branch_out);

   input[15:0] insn;
   input[15:0] pc;
   output[15:0] branch_out;
	
   wire[15:0] add_one;
   wire[15:0] sext_imm_9;
   wire [3:0] sub_op_sel;
	
   assign add_one = 16'd1;
   assign sub_op_sel = insn[11:9];
	
   sext_imm9 sext9(insn, sext_imm_9);
	
   assign branch_out = 	((pc + add_one) + sext_imm_9);
		
endmodule



/* ARITH MODULE */
module lc4_arith (insn, r1data, r2data, arith_out);

   input[15:0] insn;
   input[15:0] r1data;
   input[15:0] r2data;
   output[15:0] arith_out;
	
   wire[3:0] sel_1;
   wire sel_2;
	
   wire[15:0] quotient;
   wire[15:0] remainder;
   wire[15:0] intermediate;
   wire[15:0] addi_in;
	
   assign sel_1 = insn[5:3];
   assign sel_2 = insn[5];
	
   lc4_divider div(r1data, r2data, remainder, quotient);
   sext_imm5 addi(insn, addi_in);
	
   assign intermediate = (sel_1 == 3'd0) ? (r1data + r2data) : (
                                           (sel_1 == 3'd1) ? (r1data * r2data) : (
                                                             (sel_1 == 3'd2) ? (r1data - r2data) : (quotient)
                         ));
									
   assign arith_out = (sel_2 == 1'b0) ? (intermediate) : (addi_in + r1data);
	
endmodule


/* LOGIC MODULE */
module lc4_logic (insn, r1data, r2data, logic_out);

   input[15:0] insn;
   input[15:0] r1data;
   input[15:0] r2data;
   output[15:0] logic_out;
	
   wire[15:0] intermediate;
   wire[15:0] sext_5;
   wire[3:0] sel_1;
   wire sel_2;
	
   assign sel_1 = insn[5:3];
   assign sel_2 = insn[5];
	
   sext_imm5 andi(insn, sext_5);
	
   assign intermediate = (sel_1 == 3'd0) ? (r1data & r2data) : (
                                           (sel_1 == 3'd1) ? (~r1data) : (
                                                             (sel_1 == 3'd2) ? (r1data | r2data) : (r1data ^ r2data)
                         ));
									
   assign logic_out = (sel_2 == 1'b0) ? (intermediate) :  (r1data & sext_5);	
	
endmodule


/* SHIFT MODULE (includes mod operator) */
module lc4_shift (insn, r1data, r2data, shift_out);

   input[15:0] insn;
   input[15:0] r1data;
   input[15:0] r2data;
   output[15:0] shift_out;
	
   wire[2:0] sub_op;
   wire[15:0] remainder_out;
   wire[15:0] quotient_out;
   wire[15:0] shift_left_out;
   wire[15:0] shift_right_arith_out;
   wire[15:0] shift_right_logical_out;
   wire arith_shift_input;
   wire logical_shift_input;
	
   assign sub_op = insn[5:4];
   assign logical_shift_input = 1'b0;
   assign arith_shift_input = r1data[15];
	
   lc4_divider remainder(r1data, r2data, remainder_out, quotient_out);
   barrel_shift_left sll(insn, r1data, shift_left_out);
   barrel_shift_right sra(insn, r1data, arith_shift_input, shift_right_arith_out);
   barrel_shift_right srl(insn, r1data, logical_shift_input, shift_right_logical_out);
	
	
   // sub_opcode mux
   assign shift_out = (sub_op == 2'd0) ? (shift_left_out) : (
                                         (sub_op == 2'd1) ? (shift_right_arith_out) : (
                                         (sub_op == 2'd2) ? (shift_right_logical_out) : (remainder_out)
                      ));
	
endmodule


/* SLL Operation (r1data is what is being shifted) */
module barrel_shift_left(insn, r1data, out);

   input[15:0] insn;
   input[15:0] r1data;
   output[15:0] out;
	
   wire[3:0] shift;
   wire[15:0] shift_8_out;
   wire[15:0] shift_4_out;
   wire[15:0] shift_2_out;
   wire[15:0] shift_1_out;
   wire[15:0] inter_8;
   wire[15:0] inter_4;
   wire[15:0] inter_2;
   wire[15:0] inter_1;
	
   assign shift = insn[3:0];
	
   // shift 8
   assign shift_8_out[15] = r1data[7];
   assign shift_8_out[14] = r1data[6];
   assign shift_8_out[13] = r1data[5];
   assign shift_8_out[12] = r1data[4];
   assign shift_8_out[11] = r1data[3];
   assign shift_8_out[10] = r1data[2];
   assign shift_8_out[9] = r1data[1];
   assign shift_8_out[8] = r1data[0];
   assign shift_8_out[7] = 1'b0;
   assign shift_8_out[6] = 1'b0;
   assign shift_8_out[5] = 1'b0;
   assign shift_8_out[4] = 1'b0;
   assign shift_8_out[3] = 1'b0;
   assign shift_8_out[2] = 1'b0;
   assign shift_8_out[1] = 1'b0;
   assign shift_8_out[0] = 1'b0;
	
   // shift 4
   assign shift_4_out[15] = inter_8[11];
   assign shift_4_out[14] = inter_8[10];
   assign shift_4_out[13] = inter_8[9];
   assign shift_4_out[12] = inter_8[8];
   assign shift_4_out[11] = inter_8[7];
   assign shift_4_out[10] = inter_8[6];
   assign shift_4_out[9] = inter_8[5];
   assign shift_4_out[8] = inter_8[4];
   assign shift_4_out[7] = inter_8[3];
   assign shift_4_out[6] = inter_8[2];
   assign shift_4_out[5] = inter_8[1];
   assign shift_4_out[4] = inter_8[0];
   assign shift_4_out[3] = 1'b0;
   assign shift_4_out[2] = 1'b0;
   assign shift_4_out[1] = 1'b0;
   assign shift_4_out[0] = 1'b0;
	
   // shift 2
   assign shift_2_out[15] = inter_4[13];
   assign shift_2_out[14] = inter_4[12];
   assign shift_2_out[13] = inter_4[11];
   assign shift_2_out[12] = inter_4[10];
   assign shift_2_out[11] = inter_4[9];
   assign shift_2_out[10] = inter_4[8];
   assign shift_2_out[9] = inter_4[7];
   assign shift_2_out[8] = inter_4[6];
   assign shift_2_out[7] = inter_4[5];
   assign shift_2_out[6] = inter_4[4];
   assign shift_2_out[5] = inter_4[3];
   assign shift_2_out[4] = inter_4[2];
   assign shift_2_out[3] = inter_4[1];
   assign shift_2_out[2] = inter_4[0];
   assign shift_2_out[1] = 1'b0;
   assign shift_2_out[0] = 1'b0;
	
   // shift 1
   assign shift_1_out[15] = inter_2[14];
   assign shift_1_out[14] = inter_2[13];
   assign shift_1_out[13] = inter_2[12];
   assign shift_1_out[12] = inter_2[11];
   assign shift_1_out[11] = inter_2[10];
   assign shift_1_out[10] = inter_2[9];
   assign shift_1_out[9] = inter_2[8];
   assign shift_1_out[8] = inter_2[7];
   assign shift_1_out[7] = inter_2[6];
   assign shift_1_out[6] = inter_2[5];
   assign shift_1_out[5] = inter_2[4];
   assign shift_1_out[4] = inter_2[3];
   assign shift_1_out[3] = inter_2[2];
   assign shift_1_out[2] = inter_2[1];
   assign shift_1_out[1] = inter_2[0];
   assign shift_1_out[0] = 1'b0;
	
   // mux structure for barrel shifter
   assign inter_8 = (shift[3] == 1'b1) ? (shift_8_out) : (r1data);
   assign inter_4 = (shift[2] == 1'b1) ? (shift_4_out) : (inter_8);
   assign inter_2 = (shift[1] == 1'b1) ? (shift_2_out) : (inter_4);
   assign out = (shift[0] == 1'b1) ? (shift_1_out) : (inter_2);

endmodule


/* Shift Right (SRA and SRL) shift_in either 1 or 0 */
module barrel_shift_right(insn, r1data, shift_in, out);

   input[15:0] insn;
   input[15:0] r1data;
   input shift_in;
   output[15:0] out;
	
   wire[3:0] shift;
   wire[15:0] shift_8_out;
   wire[15:0] shift_4_out;
   wire[15:0] shift_2_out;
   wire[15:0] shift_1_out;
   wire[15:0] inter_8;
   wire[15:0] inter_4;
   wire[15:0] inter_2;
   wire[15:0] inter_1;
	
   assign shift = insn[3:0];
	
   // shift 8
   assign shift_8_out[15] = shift_in;
   assign shift_8_out[14] = shift_in;
   assign shift_8_out[13] = shift_in;
   assign shift_8_out[12] = shift_in;
   assign shift_8_out[11] = shift_in;
   assign shift_8_out[10] = shift_in;
   assign shift_8_out[9] = shift_in;
   assign shift_8_out[8] = shift_in;
   assign shift_8_out[7] = r1data[15];
   assign shift_8_out[6] = r1data[14];
   assign shift_8_out[5] = r1data[13];
   assign shift_8_out[4] = r1data[12];
   assign shift_8_out[3] = r1data[11];
   assign shift_8_out[2] = r1data[10];
   assign shift_8_out[1] = r1data[9];
   assign shift_8_out[0] = r1data[8];
	
   // shift 4
   assign shift_4_out[15] = shift_in;
   assign shift_4_out[14] = shift_in;
   assign shift_4_out[13] = shift_in;
   assign shift_4_out[12] = shift_in;
   assign shift_4_out[11] = inter_8[15];
   assign shift_4_out[10] = inter_8[14];
   assign shift_4_out[9] = inter_8[13];
   assign shift_4_out[8] = inter_8[12];
   assign shift_4_out[7] = inter_8[11];
   assign shift_4_out[6] = inter_8[10];
   assign shift_4_out[5] = inter_8[9];
   assign shift_4_out[4] = inter_8[8];
   assign shift_4_out[3] = inter_8[7];
   assign shift_4_out[2] = inter_8[6];
   assign shift_4_out[1] = inter_8[5];
   assign shift_4_out[0] = inter_8[4];
	
   // shift 2
   assign shift_2_out[15] = shift_in;
   assign shift_2_out[14] = shift_in;
   assign shift_2_out[13] = inter_4[15];
   assign shift_2_out[12] = inter_4[14];
   assign shift_2_out[11] = inter_4[13];
   assign shift_2_out[10] = inter_4[12];
   assign shift_2_out[9] = inter_4[11];
   assign shift_2_out[8] = inter_4[10];
   assign shift_2_out[7] = inter_4[9];
   assign shift_2_out[6] = inter_4[8];
   assign shift_2_out[5] = inter_4[7];
   assign shift_2_out[4] = inter_4[6];
   assign shift_2_out[3] = inter_4[5];
   assign shift_2_out[2] = inter_4[4];
   assign shift_2_out[1] = inter_4[3];
   assign shift_2_out[0] = inter_4[2];
	
   // shift 1
   assign shift_1_out[15] = shift_in;
   assign shift_1_out[14] = inter_2[15];
   assign shift_1_out[13] = inter_2[14];
   assign shift_1_out[12] = inter_2[13];
   assign shift_1_out[11] = inter_2[12];
   assign shift_1_out[10] = inter_2[11];
   assign shift_1_out[9] = inter_2[10];
   assign shift_1_out[8] = inter_2[9];
   assign shift_1_out[7] = inter_2[8];
   assign shift_1_out[6] = inter_2[7];
   assign shift_1_out[5] = inter_2[6];
   assign shift_1_out[4] = inter_2[5];
   assign shift_1_out[3] = inter_2[4];
   assign shift_1_out[2] = inter_2[3];
   assign shift_1_out[1] = inter_2[2];
   assign shift_1_out[0] = inter_2[1];
	
   // mux structure for barrel shifter
   assign inter_8 = (shift[3] == 1'b1) ? (shift_8_out) : (r1data);
   assign inter_4 = (shift[2] == 1'b1) ? (shift_4_out) : (inter_8);
   assign inter_2 = (shift[1] == 1'b1) ? (shift_2_out) : (inter_4);
   assign out = (shift[0] == 1'b1) ? (shift_1_out) : (inter_2);
	
endmodule


/* CONST MODULE */
module lc4_const(insn, const_out);

   input[15:0] insn;
   output[15:0] const_out;
	
   sext_imm9 sext(insn, const_out);
	
endmodule

/* HICONST MODULE */
module lc4_hi_const(insn, r1data, const_out);

   input[15:0] insn;
   input[15:0] r1data;
   output[15:0] const_out;
   wire[15:0] shift_out;
	
   barrel_shift_left sll(16'd8, insn, shift_out);
	
   assign const_out = ((r1data & 16'hFF) | shift_out);

endmodule

/* TRAP MODULE */
module lc4_trap(insn, trap_out);

   input[15:0] insn;
   output[15:0] trap_out;
	
   wire[15:0] intermediate;
	
   assign intermediate = 16'b0000000011111111 & insn;	
   assign trap_out = 16'b1000000000000000 | intermediate;
	
endmodule

/* RTI and JMPR and JSRR MODULE */
module lc4_rti_jmpr_jsrr(r1data, out);

   input[15:0] r1data;
   output[15:0] out;
	
   assign out = r1data;
	
endmodule

/* JSR MODULE */
module lc4_jsr(insn, pc, out);

   input[15:0] insn;
   input[15:0] pc;
   output[15:0] out;
	
   wire[15:0] shift_out;
   wire[15:0] intermediate;
   wire[15:0] intermediate2;
	
   barrel_shift_left shift_left(16'd4, insn, shift_out);
   assign intermediate2 = shift_out & 16'b0111111111111111;
   assign intermediate = pc & 16'h8000;
   assign out = intermediate | intermediate2;
	
endmodule

/* JMP MODULE */
module lc4_jmp(insn, pc, jmp_out);

   input[15:0] insn;
   input[15:0] pc;
   output[15:0] jmp_out;
	
   wire[15:0] sext_out;
	
   sext_imm11 sext(insn, sext_out);
	
   assign jmp_out = ((pc + (16'b1)) + sext_out);

endmodule

/* LDR & STR MODULE */
module lc4_ldr_str(insn, r1data, out);

   input[15:0] insn;
   input[15:0] r1data;
   output[15:0] out;
	
   wire[15:0] sext_out;
	
   sext_imm6 sext(insn, sext_out);
   assign out = r1data + sext_out;
	
endmodule


/* COMPARE MODULE */
module lc4_compare(insn, r1data, r2data, out);

   input[15:0] insn;
   input[15:0] r1data;
   input[15:0] r2data;
   output[15:0] out;
	
   wire[1:0] sub_op;
   wire[15:0] sext_imm7_out;
   wire[15:0] uimm7;
   wire[15:0] cmp_out;
   wire[15:0] cmpu_out;
   wire[15:0] cmpi_out;
   wire[15:0] cmpiu_out;
	
   assign sub_op = insn[8:7];
   assign uimm7 = insn & 16'b0000000001111111;
	
   sext_imm7 sext(insn, sext_imm7_out);
   lc4_cmps cmp(r1data, r2data, cmp_out);
   lc4_cmpu cmpu(r1data, r2data, cmpu_out);
   lc4_cmps cmpi(r1data, sext_imm7_out, cmpi_out);
   lc4_cmpu cmpiu(r1data, uimm7, cmpiu_out);
	
   assign out = (sub_op == 2'b00) ? (cmp_out) : (
                                    (sub_op == 2'b01) ? (cmpu_out) : (
                                                        (sub_op == 2'b10) ? (cmpi_out) : cmpiu_out
                ));
			
endmodule


/* Compare unsigned */
module lc4_cmpu(r1data, r2data, out);

   input[15:0] r1data;
   input[15:0] r2data;
   output[15:0] out;
	
   wire[16:0] r1_extend;
   wire[16:0] r2_extend;
   wire[16:0] sub_out;
	
   assign r1_extend[16] = 1'b0;
   assign r1_extend[15] = r1data[15];
   assign r1_extend[14] = r1data[14];
   assign r1_extend[13] = r1data[13];
   assign r1_extend[12] = r1data[12];
   assign r1_extend[11] = r1data[11];
   assign r1_extend[10] = r1data[10];
   assign r1_extend[9] = r1data[9];
   assign r1_extend[8] = r1data[8];
   assign r1_extend[7] = r1data[7];
   assign r1_extend[6] = r1data[6];
   assign r1_extend[5] = r1data[5];
   assign r1_extend[4] = r1data[4];
   assign r1_extend[3] = r1data[3];
   assign r1_extend[2] = r1data[2];
   assign r1_extend[1] = r1data[1];
   assign r1_extend[0] = r1data[0];
	
   assign r2_extend[16] = 1'b0;
   assign r2_extend[15] = r2data[15];
   assign r2_extend[14] = r2data[14];
   assign r2_extend[13] = r2data[13];
   assign r2_extend[12] = r2data[12];
   assign r2_extend[11] = r2data[11];
   assign r2_extend[10] = r2data[10];
   assign r2_extend[9] = r2data[9];
   assign r2_extend[8] = r2data[8];
   assign r2_extend[7] = r2data[7];
   assign r2_extend[6] = r2data[6];
   assign r2_extend[5] = r2data[5];
   assign r2_extend[4] = r2data[4];
   assign r2_extend[3] = r2data[3];
   assign r2_extend[2] = r2data[2];
   assign r2_extend[1] = r2data[1];
   assign r2_extend[0] = r2data[0];
	
   assign sub_out = r1_extend - r2_extend;
	
   assign out = (sub_out == 17'd0) ? (16'd0) :
                                     (sub_out[16] == 1'b1) ? (16'hFFFF) : (16'd1);

endmodule


/* Compare signed */
module lc4_cmps(r1data, r2data, out);

   input[15:0] r1data;
   input[15:0] r2data;
   output[15:0] out;
	
   wire[16:0] r1_extend;
   wire[16:0] r2_extend;
   wire[16:0] sub_out;
	
   assign r1_extend[16] = r1data[15];
   assign r1_extend[15] = r1data[15];
   assign r1_extend[14] = r1data[14];
   assign r1_extend[13] = r1data[13];
   assign r1_extend[12] = r1data[12];
   assign r1_extend[11] = r1data[11];
   assign r1_extend[10] = r1data[10];
   assign r1_extend[9] = r1data[9];
   assign r1_extend[8] = r1data[8];
   assign r1_extend[7] = r1data[7];
   assign r1_extend[6] = r1data[6];
   assign r1_extend[5] = r1data[5];
   assign r1_extend[4] = r1data[4];
   assign r1_extend[3] = r1data[3];
   assign r1_extend[2] = r1data[2];
   assign r1_extend[1] = r1data[1];
   assign r1_extend[0] = r1data[0];
	
   assign r2_extend[16] = r2data[15];
   assign r2_extend[15] = r2data[15];
   assign r2_extend[14] = r2data[14];
   assign r2_extend[13] = r2data[13];
   assign r2_extend[12] = r2data[12];
   assign r2_extend[11] = r2data[11];
   assign r2_extend[10] = r2data[10];
   assign r2_extend[9] = r2data[9];
   assign r2_extend[8] = r2data[8];
   assign r2_extend[7] = r2data[7];
   assign r2_extend[6] = r2data[6];
   assign r2_extend[5] = r2data[5];
   assign r2_extend[4] = r2data[4];
   assign r2_extend[3] = r2data[3];
   assign r2_extend[2] = r2data[2];
   assign r2_extend[1] = r2data[1];
   assign r2_extend[0] = r2data[0];
	
   assign sub_out = r1_extend - r2_extend;
	
   assign out = (sub_out == 17'd0) ? (16'd0) :
                                     (sub_out[16] == 1'b1) ? (16'hFFFF) : (16'd1);
   
endmodule
