`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Moratuwa, Sri Lanka
// Author: Miyuru Thathsara
// 
// Create Date: 04/04/2021 08:42:13 AM
// Design Name: ReLU activation
// Module Name: relu
// Project Name: convolution
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module relu
(
    clk,
    resetn,
    dataIn,
    dataValidIn,
    dataOut,
    dataValidOut
);
//////////////////////////////////////////////////////////////////////////////////
// Parameters
//////////////////////////////////////////////////////////////////////////////////
`include "params.vh"
//////////////////////////////////////////////////////////////////////////////////
// Local Parameters
//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////
// I/O Configuration
//////////////////////////////////////////////////////////////////////////////////
input                                                                   clk;
input                                                                   resetn;
input signed        [ FIXED_POINT_SIZE - 1 : 0 ]                        dataIn;
input                                                                   dataValidIn;
output reg signed   [ FIXED_POINT_SIZE - 1 : 0 ]                        dataOut;
output reg                                                              dataValidOut;
//////////////////////////////////////////////////////////////////////////////////
// Wires and Registers
//////////////////////////////////////////////////////////////////////////////////
reg                                                                     reset_a;
reg                                                                     reset_b;
wire                                                                    reset_wire;
//////////////////////////////////////////////////////////////////////////////////
// Implementation
//////////////////////////////////////////////////////////////////////////////////
assign reset_wire                                                                   = resetn & reset_b;

always @(posedge clk) begin
    reset_a                                                                         <= resetn;
    reset_b                                                                         <= reset_a;
end

always@(posedge clk or negedge reset_wire) begin
    if( ~reset_wire )begin
        dataOut                                                                     <= { FIXED_POINT_SIZE { 1'b0 } };
        dataValidOut                                                                <= 1'b0;
    end
    else begin
        dataValidOut                                                                <= dataValidIn;
        if( dataValidIn )begin
            if( dataIn < 0 )begin
                dataOut                                                             <= { FIXED_POINT_SIZE { 1'b0 } };
            end
            else begin
                dataOut                                                             <= dataIn;
            end
        end
    end
end
endmodule
