`include "swap_bits.svh"

module layer_between_project_and_lab_top
# (
    parameter clk_mhz       = 25,
              pixel_mhz     = 25,

              w_key         = 8,
              w_sw          = 7,
              w_led         = 8,
              w_digit       = 8,
              w_gpio        = 1,  // unused

              screen_width  = 640,
              screen_height = 480,

              w_red         = 2,
              w_green       = 2,
              w_blue        = 2,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                        clk,
    input                        rst,

    input        [w_sw    - 1:0] sw,

    output                       tm1638_clk,
    output                       tm1638_stb,

    input                        tm1638_dio_in,
    output                       tm1638_dio_out,
    output                       tm1638_dio_out_en,

    output logic                 vga_hsync,
    output logic                 vga_vsync,

    output logic [w_red   - 1:0] vga_red,
    output logic [w_green - 1:0] vga_green,
    output logic [w_blue  - 1:0] vga_blue,

    output                       mic_lr,
    output                       mic_ws,
    output                       mic_sck,
    input                        mic_sd,

    input                        uart_rx,

    output                       sticky_failure
);

    //------------------------------------------------------------------------

    wire slow_clk = clk;

    // Keys, switches, LEDs

    wire [w_key   - 1:0] key;
    wire [w_led   - 1:0] led;

    // A dynamic seven-segment display

    wire [          7:0] abcdefgh;
    wire [w_digit - 1:0] digit;

    // Graphics

    wire [w_x     - 1:0] x;
    wire [w_y     - 1:0] y;

    wire [w_red   - 1:0] red;
    wire [w_green - 1:0] green;
    wire [w_blue  - 1:0] blue;

    // Microphone, sound output and UART

    wire [         23:0] mic;
    wire [         15:0] sound;

    wire                 uart_tx;

    // General-purpose Input/Output

    wire [w_gpio  - 1:0] gpio;

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       ( clk_mhz       ),

        .w_key         ( w_key         ),
        .w_sw          ( w_sw          ),
        .w_led         ( w_led         ),
        .w_digit       ( w_digit       ),
        .w_gpio        ( w_gpio        ),

        .screen_width  ( screen_width  ),
        .screen_height ( screen_height ),

        .w_red         ( w_red         ),
        .w_green       ( w_green       ),
        .w_blue        ( w_blue        )
    )
    i_lab_top (.*);

    //------------------------------------------------------------------------

    wire [7:0]  hgfedcba;
    `SWAP_BITS (hgfedcba, abcdefgh);

    tm1638_board_controller
    # (
        .clk_mhz          ( clk_mhz           ),
        .w_digit          ( w_digit           ),
        .w_seg            ( 8                 )
    )
    i_tm1638
    (
        .clk              ,
        .rst              ,
        .hgfedcba         ,
        .digit            ,
        .ledr             ( led               ),
        .keys             ( key               ),

        .sio_clk          ( tm1638_clk        ),
        .sio_stb          ( tm1638_stb        ),

        .sio_data_in      ( tm1638_dio_in     ),
        .sio_data_out     ( tm1638_dio_out    ),
        .sio_data_out_en  ( tm1638_dio_out_en )
    );

    //------------------------------------------------------------------------

    wire hsync, vsync, display_on;

    wire [9:0] hpos; assign x = w_x' (hpos);
    wire [9:0] vpos; assign y = w_y' (vpos);

    wire pixel_clk;  // Unused because main clock is 25 MHz

    vga
    # (
        .CLK_MHZ     ( clk_mhz   ),
        .PIXEL_MHZ   ( pixel_mhz )
    )
    i_vga
    (
        .clk         ,
        .rst         ,

        .hsync       ,
        .vsync       ,

        .display_on  ,

        .hpos        ,
        .vpos        ,

        .pixel_clk
    );

    //------------------------------------------------------------------------

    always_ff @ (posedge clk)
        if (rst)
        begin
            vga_hsync <= 1'b0;
            vga_vsync <= 1'b0;
        end
        else
        begin
            vga_hsync <= hsync;
            vga_vsync <= vsync;
        end

    //------------------------------------------------------------------------

    always_ff @ (posedge clk)
    begin
        vga_red   <= display_on ? red   : '0;
        vga_green <= display_on ? green : '0;
        vga_blue  <= display_on ? blue  : '0;
    end

    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver
    # (
        .clk_mhz  ( clk_mhz )
    )
    i_microphone
    (
        .clk      ( clk     ),
        .rst      ( rst     ),
        .lr       ( mic_lr  ),
        .ws       ( mic_ws  ),
        .sck      ( mic_sck ),
        .sd       ( mic_sd  ),
        .value    ( mic     )
    );

    //------------------------------------------------------------------------

    // TODO: Think how to use this signal for self-diagnostics
    assign sticky_failure = 1'b0;

endmodule
