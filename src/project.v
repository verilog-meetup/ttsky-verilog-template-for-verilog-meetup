/*
 * Copyright (c) 2024-2025 Tiny Tapeout and Verilog Meetup
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_verilog_meetup_template_project_TODO
(
    input  [7:0] ui_in,    // Dedicated inputs
    output [7:0] uo_out,   // Dedicated outputs
    input  [7:0] uio_in,   // IOs: Input path
    output [7:0] uio_out,  // IOs: Output path
    output [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input        ena,      // always 1 when the design is powered, so you can ignore it
    input        clk,      // clock
    input        rst_n     // reset_n - low to reset
);

    //------------------------------------------------------------------------

    wire [6:0] sw;

    wire       tm1638_clk;
    wire       tm1638_stb;

    wire       tm1638_dio_in;
    wire       tm1638_dio_out;
    wire       tm1638_dio_out_en;

    wire       vga_hsync;
    wire       vga_vsync;

    wire [1:0] vga_red;
    wire [1:0] vga_green;
    wire [1:0] vga_blue;

    wire       mic_lr;
    wire       mic_ws;
    wire       mic_sck;
    wire       mic_sd;

    wire       uart_rx;

    wire       sticky_failure;

    //------------------------------------------------------------------------

    layer_between_project_and_lab_top i_layer
    (
        .rst ( ~ rst_n ),
        .*
    );

    //------------------------------------------------------------------------

    // All output pins must be assigned. If not used, assign to 0.

    assign sw             = ui_in [6:0];
    assign uart_rx        = ui_in [7];

    //------------------------------------------------------------------------

    assign uio_oe  [2:0]  = '1;

    assign uio_out [0]    = mic_lr;
    assign uio_out [1]    = mic_ws;
    assign uio_out [2]    = mic_sck;

    assign uio_oe  [3]    = 1'b0;
    assign uio_out [3]    = 1'b0;
    assign mic_sd         = uio_in [3];

    assign uio_oe  [4]    = 1'b1;
    assign uio_out [4]    = sticky_failure;

    assign uio_oe  [5]    = tm1638_dio_out_en;
    assign uio_out [5]    = tm1638_dio_out;
    assign tm1638_dio_in  = uio_in [5];

    assign uio_oe  [7:6]  = '1;

    assign uio_out [6]    = tm1638_clk;
    assign uio_out [7]    = tm1638_stb;

    //------------------------------------------------------------------------

    assign uo_out  [0]    = vga_red   [1];
    assign uo_out  [1]    = vga_green [1];
    assign uo_out  [2]    = vga_blue  [1];
    assign uo_out  [3]    = vga_vsync    ;
    assign uo_out  [4]    = vga_red   [0];
    assign uo_out  [5]    = vga_green [0];
    assign uo_out  [6]    = vga_blue  [0];
    assign uo_out  [7]    = vga_hsync    ;

    //------------------------------------------------------------------------

    // List all unused inputs to prevent warnings
    wire _unused = & { ena, uio_in [7:6], uio_in [4], uio_in [2:0], 1'b0 };

endmodule
