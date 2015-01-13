`timescale 1ns / 1ps

module lc4_system(/*Clock inputs from FPGA pins*/
                  CLK_100MHz,
                  CLK_32MHz,
                  
                  /* board buttons */
                  RST_BTN_IN,
                  GWE_BTN_IN,
                  
                  /*Daughterboard switches */
                  SWITCH_IN,
                  
                  /*VGA ports*/
                  VGA_OUT_PIXEL_CLOCK,
                  VGA_COMP_SYNCH,
                  VGA_OUT_BLANK_Z,
                  VGA_HSYNCH,
                  VGA_VSYNCH,
                  VGA_OUT_RED,
                  VGA_OUT_GREEN,
                  VGA_OUT_BLUE,
                  
                  /*Expansion board ports*/
                  COUT,
                  AOUT,
                  LDOUT,
                  LDGND,                
                  /*PS2 ports*/
                  PS2KEYBOARD_DATA,
                  PS2KEYBOARD_CLK);
   
   input         CLK_100MHz;     // System clock
   input         CLK_32MHz;      // SystemACE clock
   input         RST_BTN_IN;     // Right push button
   input         GWE_BTN_IN;     // Down push button
   input [7:0]   SWITCH_IN;      // daughterboard switches
   
   //VGA:
   output        VGA_OUT_PIXEL_CLOCK;      // pixel clock for the video DAC
   output        VGA_COMP_SYNCH;           // composite sync for the video DAC
   output        VGA_OUT_BLANK_Z;          // composite blanking for the video DAC
   output        VGA_HSYNCH;               // horizontal sync for the VGA output connector
   output        VGA_VSYNCH;               // vertical sync for the VGA output connector
   output [7:0]  VGA_OUT_RED;              // RED DAC data
   output [7:0]  VGA_OUT_GREEN;            // GREEN DAC data
   output [7:0]  VGA_OUT_BLUE;             // BLUE DAC data
   //Expansion board:
   output [6:0]  COUT;       //7-segment display cathodes
   output [3:0]  AOUT;       //7-segment display anodes
   output [7:0]  LDOUT;      //LEDs
   output        LDGND;      //ground, must always be 1
   assign        LDGND = 1'b1;
   
   //PS/2 Keyboard:
   inout         PS2KEYBOARD_DATA;
   inout         PS2KEYBOARD_CLK;

   // DIO4 lights
   wire [15:0]   seven_segment_data;
   wire [7:0]    led_data;
   
   // CLOCK MANAGEMENT
   wire          GLOBAL_WE;    //global we, toggled to build a single-step clock
   wire          pixel_clk;    //clock for VGA
   wire          ps2_clk;      //clock for PS/2
   wire          exp_clk;      //clock for expansion board
   wire          dcm_reset_1;  //digital clock manager reset signal
   wire          dcm_reset_2;  //digital clock manager reset signal
   wire          GLOBAL_RST;   //global reset signal
   wire          proc_clk;     //the processor clock, same as memory clock
   
   //Currently, the pixel clock is formed by dividing the 100MHz clock by
   //4 using CLKDV, and the system clock (for the pipeline, etc.) is the same
   //as the input clock (from CLKFX). If the pixel clock needs to be changed,
   //it may not be possible to do it using CLKDV (i.e. not an integer or .5
   //factor of the 100MHz clock); you may have to switch the pixel clock to
   //CLKFX and the system clock to CLKDV.
`ifndef __ICARUS__
   dcm_two #(2, 2, 4)
   dcm_inst_1(.CLK_IN( CLK_100MHz ), 
              .CLKDV_OUT( pixel_clk ),  //100 MHz / 4 = 25 MHz
              .RESET( dcm_reset_1 ));
   
   dcm_two #(4, 2, 16)
   dcm_inst_2(.CLK_IN( CLK_32MHz ),
              .CLKDV_OUT( ps2_clk ),    //32 MHz / 16 = 2 MHz
              .CLKFX_OUT( exp_clk ),    //32 MHz / 4 * 2 = 16 MHz
              .RESET( dcm_reset_2 ));
`endif
   
   assign        proc_clk = exp_clk;
   
   /* Generate "single-step clock" by one-pulsing the global
    write-enable. The one-pulse circuitry cleans up the signal edges
    for us. */
   wire          global_we_pulse;
   one_pulse clk_pulse(.clk( proc_clk ), 
                       .rst( dcm_reset_1 | dcm_reset_2 ),
                       .btn( ~GWE_BTN_IN ), // FPGA buttons are active-low
                       .pulse_out( global_we_pulse ));
   
   /* Clean up trailing edges of the GLOBAL_WE switch input */
   wire          global_we_switch;
   
   Nbit_reg #(1, 0) gwe_cleaner(.in(SWITCH_IN[7]), // FPGA switches are active-low
                                .out( global_we_switch ), 
                                .clk( proc_clk ), 
                                .we( 1'b1 ), 
                                .gwe( 1'b1 ), 
                                .rst( GLOBAL_RST ));
   
 
   wire          i1re, i2re, dre, gwe_out;
   lc4_we_gen we_gen(.clk(proc_clk),
       .i1re(i1re),
       .i2re(i2re),
       .dre(dre),
       .gwe(gwe_out));
       
   
   assign GLOBAL_WE = global_we_pulse | (gwe_out & global_we_switch);
 
 
 
   /* Clean up the edges of the manual reset signal. Only the trailing
      edge should really matter, though.*/
   wire          rst_btn;
   Nbit_reg #(1, 0) reset_cleaner(.in( ~RST_BTN_IN ), // FPGA buttons are active-low
                                  .out( rst_btn ), 
                                  .clk( proc_clk ), 
                                  .we( 1'b1 ), 
                                  .gwe( 1'b1 ), 
                                  .rst( dcm_reset_1 | dcm_reset_2 ));
   or( GLOBAL_RST, dcm_reset_1, dcm_reset_2, rst_btn );
   
   // MEMORY INTERFACE
   // INSTRUCTIONS
   wire [15:0]   imem1_addr, imem2_addr;
   wire [15:0]   imem1_out, imem2_out;
   // DATA MEMORY
   wire [15:0]   dmem_addr;
   wire [15:0]   dmem_in;
   wire          dmem_we;
   wire [15:0]   dmem_mout;
   
   // DEVICE INTERFACES
   // P/S2 KEYBOARD
   wire          read_kbsr = ~dmem_we & (dmem_addr == 16'hFE00);
   wire          kbsr;
   wire          read_kbdr = ~dmem_we & (dmem_addr == 16'hFE02);
   wire [7:0]    kbdr;
   // TIMER
   wire          read_tsr = ~dmem_we & (dmem_addr == 16'hFE08);
   wire          write_tir = dmem_we & (dmem_addr == 16'hFE0A);
   wire          tsr;
   // VGA
   wire [13:0]   vga_addr;
   wire [15:0]   vga_data;
   
   // MEMORY/DEVICE MUX
   wire [15:0]   dmem_out = dmem_we ? 16'h0000 :
                 (dmem_addr == 16'hFE00) ? {kbsr, {15{1'b0}}} :
                 (dmem_addr == 16'hFE02) ? {8'h00, kbdr} :
                 (dmem_addr == 16'hFE08) ? {tsr, {15{1'b0}}} :
                 (dmem_addr < 16'hFE00) ? dmem_mout : 16'h0000;
   
	
   // PROCESSOR

   lc4_processor proc_inst(.clk(proc_clk),
                           .rst(GLOBAL_RST),
                           .gwe(GLOBAL_WE),
                           .imem_addr(imem1_addr),
                           .imem_out(imem1_out),
                           .dmem_addr(dmem_addr),
                           .dmem_out(dmem_out),
                           .dmem_we(dmem_we),
                           .dmem_in(dmem_in),
                           .switch_data(SWITCH_IN),
                           .seven_segment_data(seven_segment_data),
                           .led_data(led_data)
                           );
   
   assign imem2_addr = 16'd0;
   
   // MEMORY
 
   // The memory for bit-mapped video and other I/O. Port a is a read-only
   // port for the VGA video. Port b is a read-write port for memory-mapped
   // I/O data. The addresses used in the memory are only 14 bits because the
   // most-significant bits are always 11. Port b is accessed in the memory
   // stage of a pipeline; memory-mapped I/O is implemented by executing loads
   // and stores to I/O memory.          

   lc4_memory memory (.idclk(proc_clk),
                      .i1re(i1re),
                      .i2re(i2re),
                      .dre(dre),
                      .gwe(GLOBAL_WE),
                      .rst(GLOBAL_RST),
                      .i1addr(imem1_addr),
                      .i2addr(imem2_addr),
                      .i1out(imem1_out),
                      .i2out(imem2_out),
                      .daddr(dmem_addr),
                      .din(dmem_in),
                      .dout(dmem_mout),
                      .dwe(dmem_we),
                      .vaddr({2'b11, vga_addr}),
                      .vout(vga_data),     //VGA data out
                      .vclk(pixel_clk)     //VGA clock
                      ); 
   
      
   // PS/2 KEYBOARD CONTROLLER
   ps2_kbd ps2_kbd_inst(.read_kbsr( read_kbsr ),
                        .kbsr( kbsr ), 
                        .read_kbdr( read_kbdr ),
                        .kbdr( kbdr ),
                        .reset( GLOBAL_RST ), // global reset
                        // I/O pin connections
                        .SYSTEM_CLOCK(proc_clk),
                        .CLOCK_2MHz(ps2_clk),
                        .PS2KEYBOARD_DATA(PS2KEYBOARD_DATA),
                        .PS2KEYBOARD_CLK(PS2KEYBOARD_CLK));
   // Timer device
   timer_device timer(.write_interval( write_tir ),
                      .interval_in( dmem_in ),
                      .read_status( read_tsr ),
                      .status_out ( tsr ),
                      .GWE(GLOBAL_WE),
                      .RST(GLOBAL_RST),
                      .CLK(proc_clk));
   
   //vga_controller handles the VGA signals.
   vga_controller vga_cntrl_inst(.PIXEL_CLK(~pixel_clk),
                                 .RESET(GLOBAL_RST),
                                 .VGA_OUT_PIXEL_CLOCK(VGA_OUT_PIXEL_CLOCK),
                                 .VGA_COMP_SYNCH(VGA_COMP_SYNCH),
                                 .VGA_OUT_BLANK_Z(VGA_OUT_BLANK_Z),
                                 .VGA_HSYNCH(VGA_HSYNCH),
                                 .VGA_VSYNCH(VGA_VSYNCH),
                                 .VGA_OUT_RED(VGA_OUT_RED),
                                 .VGA_OUT_GREEN(VGA_OUT_GREEN),
                                 .VGA_OUT_BLUE(VGA_OUT_BLUE),
                                 .VGA_ADDR(vga_addr),
                                 .VGA_DATA(vga_data[14:0]));
   
   //The expansion board controller:
   di04 dio4_inst(.seven_segment_data(seven_segment_data),
                  .led_data(led_data),
                  .SEV_SEG_CLK(exp_clk),            //I [0]    32 MHz clock input
                  .COUT(COUT),                      //O [6:0]  seven-segment cathode pins
                  .AOUT(AOUT),                      //O [3:0]  seven-segment anode pins
                  .LDOUT(LDOUT)                     //O [7:0]  LED pins
                  );
   
endmodule

