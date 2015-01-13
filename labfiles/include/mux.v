`timescale 1ns / 1ps

// VERSION 1.1

/* A parameterized bus-width, 16-to-1 mux. */
module mux_Nbit_16to1(out, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, sel);
   parameter z = 1;
   
   output [z-1:0] out;
   input [z-1:0]  a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p;
   input [3:0]    sel;

   assign         out = sel == 4'b0000 ? a : 
                        sel == 4'b0001 ? b :
                        sel == 4'b0010 ? c : 
                        sel == 4'b0011 ? d :
                        sel == 4'b0100 ? e :
                        sel == 4'b0101 ? f :
                        sel == 4'b0110 ? g :
                        sel == 4'b0111 ? h :
                        sel == 4'b1000 ? i :
                        sel == 4'b1001 ? j :
                        sel == 4'b1010 ? k :
                        sel == 4'b1011 ? l :
                        sel == 4'b1100 ? m :
                        sel == 4'b1101 ? n :
                        sel == 4'b1110 ? o :
                        sel == 4'b1111 ? p : 0 /*garbage*/;
endmodule // mux_Nbit_16to1


/* A parameterized bus-width, 8-to-1 mux. */
module mux_Nbit_8to1(out, a, b, c, d, e, f, g, h, sel);
   parameter n = 1;
   
   output [n-1:0] out;
   input [n-1:0]  a, b, c, d, e, f, g, h;
   input [2:0]    sel;

   assign         out = sel == 3'b000 ? a : 
                        sel == 3'b001 ? b :
                        sel == 3'b010 ? c : 
                        sel == 3'b011 ? d :
                        sel == 3'b100 ? e :
                        sel == 3'b101 ? f :
                        sel == 3'b110 ? g :
                        sel == 3'b111 ? h : 0 /*garbage*/;
endmodule // mux_Nbit_8to1


/* A parameterized bus-width, 4-to-1 mux. 
 sel==00 -> a
 sel==01 -> b
 sel==10 -> c
 sel==11 -> d 
*/
module mux_Nbit_4to1(out, a, b, c, d, sel);
   parameter n = 1;
   
   output [n-1:0] out;
   input [n-1:0]  a, b, c, d;
   input [1:0]    sel;

   assign         out = sel == 2'b00 ? a : 
                        sel == 2'b01 ? b :
                        sel == 2'b10 ? c : 
                        sel == 2'b11 ? d : 0 /*garbage*/;
endmodule

/* A parameterized bus-width, 2-to-1 mux. 
 *  sel=0 selects `a', 
 *  sel=1 selects `b'.
 */
module mux_Nbit_2to1(out, a, b, sel);
   parameter n = 1;
   
   output [n-1:0] out;
   input [n-1:0]  a, b;
   input          sel;

   assign         out = sel == 1'b0 ? a : 
                        sel == 1'b1 ? b : 0 /*garbage*/;
endmodule


/* A parameterized bus-width, 64-to-1 mux. */
module mux_Nbit_64to1(out, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31, a32, a33, a34, a35, a36, a37, a38, a39, a40, a41, a42, a43, a44, a45, a46, a47, a48, a49, a50, a51, a52, a53, a54, a55, a56, a57, a58, a59, a60, a61, a62, a63, sel);
   parameter z = 1;

   output [z-1:0] out;
   input [z-1:0]  a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31, a32, a33, a34, a35, a36, a37, a38, a39, a40, a41, a42, a43, a44, a45, a46, a47, a48, a49, a50, a51, a52, a53, a54, a55, a56, a57, a58, a59, a60, a61, a62, a63;
   input [5:0]    sel;

   assign         out =             sel == 6'd0 ? a0:
            sel == 6'd1 ? a1:
            sel == 6'd2 ? a2:
            sel == 6'd3 ? a3:
            sel == 6'd4 ? a4:
            sel == 6'd5 ? a5:
            sel == 6'd6 ? a6:
            sel == 6'd7 ? a7:
            sel == 6'd8 ? a8:
            sel == 6'd9 ? a9:
            sel == 6'd10 ? a10:
            sel == 6'd11 ? a11:
            sel == 6'd12 ? a12:
            sel == 6'd13 ? a13:
            sel == 6'd14 ? a14:
            sel == 6'd15 ? a15:
            sel == 6'd16 ? a16:
            sel == 6'd17 ? a17:
            sel == 6'd18 ? a18:
            sel == 6'd19 ? a19:
            sel == 6'd20 ? a20:
            sel == 6'd21 ? a21:
            sel == 6'd22 ? a22:
            sel == 6'd23 ? a23:
            sel == 6'd24 ? a24:
            sel == 6'd25 ? a25:
            sel == 6'd26 ? a26:
            sel == 6'd27 ? a27:
            sel == 6'd28 ? a28:
            sel == 6'd29 ? a29:
            sel == 6'd30 ? a30:
            sel == 6'd31 ? a31:
            sel == 6'd32 ? a32:
            sel == 6'd33 ? a33:
            sel == 6'd34 ? a34:
            sel == 6'd35 ? a35:
            sel == 6'd36 ? a36:
            sel == 6'd37 ? a37:
            sel == 6'd38 ? a38:
            sel == 6'd39 ? a39:
            sel == 6'd40 ? a40:
            sel == 6'd41 ? a41:
            sel == 6'd42 ? a42:
            sel == 6'd43 ? a43:
            sel == 6'd44 ? a44:
            sel == 6'd45 ? a45:
            sel == 6'd46 ? a46:
            sel == 6'd47 ? a47:
            sel == 6'd48 ? a48:
            sel == 6'd49 ? a49:
            sel == 6'd50 ? a50:
            sel == 6'd51 ? a51:
            sel == 6'd52 ? a52:
            sel == 6'd53 ? a53:
            sel == 6'd54 ? a54:
            sel == 6'd55 ? a55:
            sel == 6'd56 ? a56:
            sel == 6'd57 ? a57:
            sel == 6'd58 ? a58:
            sel == 6'd59 ? a59:
            sel == 6'd60 ? a60:
            sel == 6'd61 ? a61:
            sel == 6'd62 ? a62:
            sel == 6'd63 ? a63: 0;
endmodule // mux_Nbit_64to1

