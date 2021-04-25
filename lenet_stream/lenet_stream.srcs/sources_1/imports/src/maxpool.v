`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Moratuwa, Sri Lanka
// Author: Miyuru Thathsara
// 
// Create Date: 04/04/2021 08:54:26 PM
// Design Name: Max Pool
// Module Name: maxpool
// Project Name: maxpool
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module maxpool
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
localparam BUFFER_NUM_DATA                                                  = IMAGE_WIDTH /  2;
localparam BUFFER_WIDTH                                                     = FIXED_POINT_SIZE * BUFFER_NUM_DATA;
localparam COLUMN_COUNTER_WIDTH                                             = count2width(IMAGE_WIDTH) + 1'b1;
localparam ROW_COUNTER_WIDTH                                                = count2width(IMAGE_HEIGHT) + 1'b1;
//////////////////////////////////////////////////////////////////////////////////
// I/O Configuration
//////////////////////////////////////////////////////////////////////////////////
input                                                                       clk;
input                                                                       resetn;
input signed        [ FIXED_POINT_SIZE - 1 : 0 ]                            dataIn;
input                                                                       dataValidIn;
output reg signed   [ FIXED_POINT_SIZE - 1 : 0 ]                            dataOut;
output reg                                                                  dataValidOut;
//////////////////////////////////////////////////////////////////////////////////
// Wires and Registers
//////////////////////////////////////////////////////////////////////////////////
reg                                                                         reset_a;
reg                                                                         reset_b;
reg                 [ BUFFER_WIDTH - 1 : 0 ]                                data_buffer;
reg                 [ COLUMN_COUNTER_WIDTH - 1 : 0 ]                        column_counter;
reg                 [ ROW_COUNTER_WIDTH - 1 : 0 ]                           row_counter;
reg signed          [ FIXED_POINT_SIZE - 1 : 0 ]                            data_reg;
reg signed          [ FIXED_POINT_SIZE - 1 : 0 ]                            hor_max_data_reg;
reg                                                                         hor_max_data_valid_reg;
reg                 [ ROW_COUNTER_WIDTH - 1 : 0 ]                           row_counter_reg;
wire                                                                        reset_wire;
//////////////////////////////////////////////////////////////////////////////////
// Implementation
//////////////////////////////////////////////////////////////////////////////////
assign reset_wire                                                           = resetn & reset_b;

always@(posedge clk) begin
    reset_a                                                                 <= resetn;
    reset_b                                                                 <= reset_a;
end

always@(posedge clk or negedge reset_wire) begin
    if(~reset_wire)begin
        column_counter                                                      <= { COLUMN_COUNTER_WIDTH { 1'b0 } };
        row_counter                                                         <= { ROW_COUNTER_WIDTH { 1'b0 } };
        row_counter_reg                                                     <= { ROW_COUNTER_WIDTH { 1'b0 } };
    end
    else begin
        row_counter_reg                                                     <= row_counter;
        if( dataValidIn )begin
            if( column_counter < IMAGE_WIDTH - 1'b1 )begin
                column_counter                                              <= column_counter + 1'b1;
            end
            else begin
                column_counter                                              <= { COLUMN_COUNTER_WIDTH { 1'b0 } };
                if( row_counter < IMAGE_HEIGHT - 1'b1 )begin
                    row_counter                                             <= row_counter + 1'b1;
                end
                else begin
                    row_counter                                             <= { ROW_COUNTER_WIDTH { 1'b0 } };
                end
            end
        end
    end
end

always@(posedge clk or negedge reset_wire)begin
    if( ~reset_wire )begin
        data_reg                                                            <= { FIXED_POINT_SIZE { 1'b0 } };
        hor_max_data_reg                                                    <= { FIXED_POINT_SIZE { 1'b0 } };
        hor_max_data_valid_reg                                              <= 1'b0;
    end
    else begin
        if( dataValidIn )begin
            if( column_counter[0] == 1'b0 )begin
                data_reg                                                    <= dataIn;
                hor_max_data_valid_reg                                      <= 1'b0;
            end
            else begin
                hor_max_data_valid_reg                                      <= 1'b1;
                if( $signed( data_reg ) >= $signed( dataIn ) )begin
                    hor_max_data_reg                                        <= data_reg;
                end
                else begin
                    hor_max_data_reg                                        <= dataIn;
                end
            end
        end
    end
end

always@(posedge clk or negedge reset_wire)begin
    if( ~reset_wire )begin
        data_buffer                                                         <= { BUFFER_WIDTH { 1'b0 } };
        dataOut                                                             <= { FIXED_POINT_SIZE { 1'b0 } };
        dataValidOut                                                        <= 1'b0;
    end
    else begin
        if( hor_max_data_valid_reg )begin
            if( row_counter_reg[0] == 1'b0 )begin
                data_buffer                                                 <= data_buffer << FIXED_POINT_SIZE;
                data_buffer[ FIXED_POINT_SIZE - 1 : 0 ]                     <= hor_max_data_reg;
                dataValidOut                                                <= 1'b0;
            end
            else begin
                dataValidOut                                                <= 1'b1;
                data_buffer                                                 <= data_buffer << FIXED_POINT_SIZE;         
                if( $signed( data_buffer[ BUFFER_WIDTH - 1 -: FIXED_POINT_SIZE ] ) >= $signed( hor_max_data_reg ) )begin
                    dataOut                                                 <= data_buffer[ BUFFER_WIDTH - 1 -: FIXED_POINT_SIZE ];
                end
                else begin
                    dataOut                                                 <= hor_max_data_reg;
                end
            end
        end
        else begin
            dataOut                                                         <= { FIXED_POINT_SIZE { 1'b0 } };
            dataValidOut                                                    <= 1'b0;
        end
    end
end
endmodule
