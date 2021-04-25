`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Moratuwa, Sri Lanka
// Author: Miyuru Thathsara
// 
// Create Date: 04/12/2021 10:00:30 PM
// Design Name: FC1 Weights
// Module Name: fc1_weights
// Project Name: Lenet Stream Architecture
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fc1_weights
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
parameter NUM_OF_ACTIVATIONS                                                = 120;
parameter NUM_OF_NEURONES                                                   = 84;
//////////////////////////////////////////////////////////////////////////////////
// Local Parameters
//////////////////////////////////////////////////////////////////////////////////
localparam ADDR_WIDTH                                                       = count2width(NUM_OF_ACTIVATIONS) + 1'b1;
localparam WEIGHT_IN_SIZE                                                   = NUM_OF_NEURONES * FIXED_POINT_SIZE;
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
reg                 [ WEIGHT_IN_SIZE - 1 : 0 ]                              ram [ NUM_OF_ACTIVATIONS - 1 : 0 ];
//////////////////////////////////////////////////////////////////////////////////
// Implementation
//////////////////////////////////////////////////////////////////////////////////
initial begin
    $readmemb( "../../../../lenet_stream.srcs/sources_1/imports/src/data/Fc1_Binary.mem", ram );
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
