`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Moratuwa, Sri Lanka
// Author: Miyuru Thathsara
// 
// Create Date: 04/12/2021 10:00:30 PM
// Design Name: FC Biases
// Module Name: fc2_bias
// Project Name: Lenet Stream Architecture
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fc2_bias
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
parameter NUM_OF_NEURONES                                                   = 10;
//////////////////////////////////////////////////////////////////////////////////
// Local Parameters
//////////////////////////////////////////////////////////////////////////////////
localparam MEM_DEPTH                                                        = 4;
localparam ADDR_WIDTH                                                       = 2;
localparam DATA_SIZE                                                        = NUM_OF_NEURONES * FIXED_POINT_SIZE;
//////////////////////////////////////////////////////////////////////////////////
// I/O Configuration
//////////////////////////////////////////////////////////////////////////////////
input                                                                       clka;
input                                                                       ena;
input                                                                       wea;
input               [ ADDR_WIDTH - 1 : 0 ]                                  addra;
input signed        [ DATA_SIZE - 1 : 0 ]                                   dina;
output reg signed   [ DATA_SIZE - 1 : 0 ]                                   douta;
//////////////////////////////////////////////////////////////////////////////////
// Wires and Registers
//////////////////////////////////////////////////////////////////////////////////
reg                 [ DATA_SIZE - 1 : 0 ]                                   ram [ MEM_DEPTH - 1 : 0 ];
//////////////////////////////////////////////////////////////////////////////////
// Implementation
//////////////////////////////////////////////////////////////////////////////////
initial begin
    $readmemb( { "../../../../lenet_stream.srcs/sources_1/imports/src/data/Fc2_Binary_Biases.mem" }, ram );
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
