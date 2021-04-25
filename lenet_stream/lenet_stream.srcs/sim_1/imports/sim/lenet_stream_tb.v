`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Moratuwa, Sri Lanka
// Author: Miyuru Thathsara
// 
// Create Date: 04/11/2021 12:54:51 PM
// Design Name: Lenet Stream TB
// Module Name: lenet_stream_tb
// Project Name: Lenet Stream Architecture
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module lenet_stream_tb();
//////////////////////////////////////////////////////////////////////////////////
// Parameters
//////////////////////////////////////////////////////////////////////////////////
`include "../lenet_stream.srcs/sources_1/imports/src/params.vh"
parameter DEPTH_OF_THE_KERNEL                                               = 1;
//////////////////////////////////////////////////////////////////////////////////
// Local parameters
//////////////////////////////////////////////////////////////////////////////////
localparam DATA_OUT_SIZE                                                    = KERNEL_SIZE * KERNEL_SIZE * FIXED_POINT_SIZE;
localparam NUM_OF_ACTIVATIONS                                               = IMAGE_WIDTH * IMAGE_HEIGHT;
localparam WEIGHT_IN_SIZE                                                   = KERNEL_SIZE * KERNEL_SIZE * FIXED_POINT_SIZE;
//////////////////////////////////////////////////////////////////////////////////
// I/O Configurations
//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////
// Wires and Registers
//////////////////////////////////////////////////////////////////////////////////
reg                                                                         clk;
reg                                                                         resetn;
reg         [ FIXED_POINT_SIZE - 1 : 0 ]                                    dataIn;
reg                                                                         dataValidIn;
reg         [ WEIGHT_IN_SIZE - 1 : 0 ]                                      weightIn;
reg                                                                         weightValidIn;
wire        [ FIXED_POINT_SIZE - 1 : 0 ]                                    dataOut;
wire                                                                        dataValidOut;
reg signed  [ FIXED_POINT_SIZE - 1 : 0 ]                                    image[ NUM_OF_ACTIVATIONS - 1 : 0 ];
integer                                                                     i;
//////////////////////////////////////////////////////////////////////////////////
// Implementation
//////////////////////////////////////////////////////////////////////////////////

accelerator_top
#(
  .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
  .FIXED_POINT_FRACTION_SIZE(FIXED_POINT_FRACTION_SIZE),
  .KERNEL_SIZE(KERNEL_SIZE),
  .IMAGE_WIDTH(IMAGE_WIDTH),
  .IMAGE_HEIGHT(IMAGE_HEIGHT),
  .DEPTH_OF_THE_KERNEL(DEPTH_OF_THE_KERNEL)  
)
accelerator_top(
    .clk(clk),
    .resetn(resetn),
    .dataIn(dataIn),
    .dataValidIn(dataValidIn),
    .weightIn(weightIn),
    .weightValidIn(weightValidIn),
    .dataOut(dataOut),
    .dataValidOut(dataValidOut)
    );

always #5 clk = ~clk;

initial $readmemb("../../../../sim/Image_Binary_1.txt", image);

initial begin
    #0;
    clk                                                 = 1'b0;
    resetn                                              = 1'b0;
    dataValidIn                                         = 1'b0;
    dataIn                                              = 1'b0;
    #10;
    resetn                                              = 1'b1;
    #10;
    resetn                                              = 1'b0;
    #10;
    resetn                                              = 1'b1;

    for( i = 0; i < NUM_OF_ACTIVATIONS; i = i + 1'b1)begin
        @(posedge clk);
        dataValidIn                                     = 1'b1;
        dataIn                                          = image[i];
    end
    @(posedge clk);
    dataValidIn                                         = 1'b0;
end
endmodule
