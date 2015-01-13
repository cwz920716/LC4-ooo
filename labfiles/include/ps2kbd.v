`timescale 1ns / 1ps
`default_nettype none

// VERSION 1.1
  
/*

 This is a module that wraps the ps2 interface to the keyboard (see
 ps2_keyboard_interface.v, courtesy of opencores.org). It provides 2
 "registers": the Keyboard Status Register (KBSR) and the Keyboard
 Data Register (KBDR). The KBSR has the value x8000 when there is
 unread input from the keyboard residing in the KBDR. The KBDR holds
 this input, as an 8-bit ASCII value (in the low-order 8 bits of its
 register). Once the data in the KBDR is read, the KBSR is reset to 0,
 until some new input arrives from the keyboard.  Note that the value
 in the KBDR is not reset on a read, so it is possible to read stale
 values from the KBDR.

 All you really need to know to use this module is that the `select'
 input chooses whether the value of the KBSR (`select' == 0) or the
 KBDR (`select' == 1) gets put onto the `out' bus. Writing to the
 keyboard is not supported. The `reset' input is the global reset
 signal, which clears the KBSR and KBDR.

 The other inputs to this module are a 2MHz clock (if you want to send
 some other frequency clock, update the parameterization in
 ps2_keyboard_interface.v accordingly), and connections to the PS/2
 connector's data and clock pins.

 KNOWN ISSUES
 
 Holding down a key on the keyboard does not generate multiple
 discrete events - that is, if a key is pressed (setting KBSR to 1),
 you read the KBDR (setting KBSR to 0), and then the key is released,
 the KBSR will still be 0. This behavior is probably ideal for games
 (the target application of this processor), as buffering keyboard
 input coupled with any lag in the processor is annoying. But it'd be
 nice to have a way to buffer up keyboard input if desired.
 
 At time = 0, the KBSR has the value 8000 in it (as if a key had been
 pressed). Once a key has been pressed, it works correctly thereafter,
 but it has a bogus value in the beginning, perhaps because of some
 delay in `kbreleased' becoming 1 from the keyboard controller. This
 problem is undetectable when this module is placed in an actual
 processor, as the global reset signal asserted at time=0 should give
 the keyboard interface state machine time to stabilize `kbreleased'.

 */

module ps2_kbd(read_kbsr,
	       kbsr,
	       read_kbdr,
	       kbdr,
               reset, // global reset

               // I/O pin connections
               SYSTEM_CLOCK,
               CLOCK_2MHz,
               PS2KEYBOARD_DATA,
               PS2KEYBOARD_CLK);

   input         read_kbsr, read_kbdr;
   output 	 kbsr;
   output [7:0]  kbdr;

   wire 	 kbsr;
   wire [7:0] 	 kbdr;
   input reset;
	
   input         SYSTEM_CLOCK;
   input         CLOCK_2MHz;
   inout         PS2KEYBOARD_DATA;
   inout         PS2KEYBOARD_CLK;
   wire          SYSTEM_CLOCK;
   wire          CLOCK_2MHz;
   wire          PS2KEYBOARD_DATA;
   wire          PS2KEYBOARD_CLK;

   // internal wires
   wire          kb_released;
   wire [7:0]    ascii;

   wire 	 key_pressed;
   one_pulse key_pulser (.clk( SYSTEM_CLOCK ), 
			 .rst( reset ), 
			 .btn( ~kb_released ), 
			 .pulse_out( key_pressed ));

   // holds status of the data register; set by us when a key is
   // released, and cleared by us when processor reads from KBDR
   Nbit_reg #(1, 0) KBSR (.in( read_kbdr ? 1'b0 : 
			       key_pressed ? 1'b1 : kbsr ), 
                          .out( kbsr ), 
                          .clk( SYSTEM_CLOCK ), 
                          .we( 1'b1 ), 
                          .gwe( 1'b1 ),
                          .rst( reset ));

   
   // holds ASCII data from the keyboard; constantly written by the
   // device and read by the processor
   Nbit_reg #(8, 0) KBDR (.in( ascii ), 
                          .out( kbdr ), 
                          .clk( SYSTEM_CLOCK ), 
                          .we( 1'b1 ), 
                          .gwe( 1'b1 ),
                          .rst( reset ));

   ps2_keyboard_interface ps2kb (// to the keyboard
                                 .clk( CLOCK_2MHz ),
                                 .reset( reset ),
                                 .ps2_clk( PS2KEYBOARD_CLK ),
                                 .ps2_data( PS2KEYBOARD_DATA ),

                                 // from the keyboard
                                 .rx_ascii( ascii ),
                                 .rx_released( kb_released ),
                                 
                                 // signals from keyboard that we don't care about
                                 .rx_data_ready( ),
                                 .keypress( ),
                                 .rx_extended( ),
                                 .rx_shift_key_on( ),
                                 .rx_scan_code( ),
                                 .tx_write_ack_o( ),
                                 .tx_error_no_keyboard_ack( ),
                                 // signals to keyboard that we don't care about
                                 .rx_read( 1'b0 ),
                                 .tx_data( 8'h00 ),
                                 .tx_write( 1'b0 ));

endmodule
