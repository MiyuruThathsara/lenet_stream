`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Moratuwa, Sri Lanka
// Author: Miyuru Thathsara
// 
// Create Date: 04/12/2021 10:00:30 PM
// Design Name: Weights Kernel
// Module Name: weights_kernel
// Project Name: Lenet Stream Architecture
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module weights_kernel
(
    clka,
    ena,
    wea,
    addra,
    dina,
    douta
);
`include "params.vh"
//////////////////////////////////////////////////////////////////////////////////
// Parameters
//////////////////////////////////////////////////////////////////////////////////
parameter DEPTH_OF_THE_KERNEL                                               = 16;
parameter LAYER_NUMBER                                                      = 1;
parameter KERNEL_NUMBER                                                     = 1;
//////////////////////////////////////////////////////////////////////////////////
// Local Parameters
//////////////////////////////////////////////////////////////////////////////////
localparam ADDR_WIDTH                                                       = count2width(DEPTH_OF_THE_KERNEL) + 1'b1;
localparam WEIGHT_IN_SIZE                                                   = KERNEL_SIZE * KERNEL_SIZE * FIXED_POINT_SIZE;
//////////////////////////////////////////////////////////////////////////////////
// I/O Configuration
//////////////////////////////////////////////////////////////////////////////////
input                                                                       clka;
input                                                                       ena;
input                                                                       wea;
input               [ ADDR_WIDTH - 1 : 0 ]                                  addra;
input signed        [ WEIGHT_IN_SIZE - 1 : 0 ]                              dina;
output reg signed   [ WEIGHT_IN_SIZE - 1 : 0 ]                              douta;
//////////////////////////////////////////////////////////////////////////////////
// Wires and Registers
//////////////////////////////////////////////////////////////////////////////////
reg                 [ WEIGHT_IN_SIZE - 1 : 0 ]                              ram [ DEPTH_OF_THE_KERNEL - 1 : 0 ];
//////////////////////////////////////////////////////////////////////////////////
// Implementation
//////////////////////////////////////////////////////////////////////////////////
initial begin
    $readmemb( { "../../../../lenet_stream.srcs/sources_1/imports/src/data/Kernel_Binary_layer_", convertIntToChars(LAYER_NUMBER), "_kernel_", convertIntToChars(KERNEL_NUMBER), ".mem" }, ram );
end

always@( posedge clka )begin
    if( ena )begin
        if( wea )begin
            ram[ addra ]                                                        <= dina;
        end
        else begin
            douta                                                               <= ram[ addra ];
        end
    end
end
endmodule
