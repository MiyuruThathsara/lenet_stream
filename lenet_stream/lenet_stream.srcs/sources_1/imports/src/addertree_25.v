`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Moratuwa, Sri Lanka
// Author: Miyuru Thathsara
// 
// Create Date: 03/31/2021 09:34:43 PM
// Design Name: Adder Tree for 25 elements
// Module Name: addertree_25
// Project Name: Convolution
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module addertree_25
(
    clk,
    resetn,
    dataIn,
    dataValidIn,
    dataOut,
    dataValidOut
);
/////////////////////////////////////////////////////////////////////////////////
// Parameters
/////////////////////////////////////////////////////////////////////////////////
`include "params.vh"
/////////////////////////////////////////////////////////////////////////////////
// Local Parameters
/////////////////////////////////////////////////////////////////////////////////
localparam KERNEL_TOT_SIZE                                              = KERNEL_SIZE * KERNEL_SIZE;
localparam MULT_REG_VAL_SIZE                                            = FIXED_POINT_SIZE * KERNEL_TOT_SIZE;
localparam ADD_WIDTH                                                    = 2 * FIXED_POINT_SIZE;
localparam ACC_STAGE1_WIDTH                                             = FIXED_POINT_SIZE + 1'b1;
localparam ACC_STAGE2_WIDTH                                             = ACC_STAGE1_WIDTH + 1'b1;
localparam ACC_STAGE3_WIDTH                                             = ACC_STAGE2_WIDTH + 1'b1;
localparam ACC_STAGE4_WIDTH                                             = ACC_STAGE3_WIDTH + 1'b1;
localparam ACC_STAGE5_WIDTH                                             = ACC_STAGE4_WIDTH + 1'b1;
localparam NUM_ADD_STAGE1                                               = ( KERNEL_TOT_SIZE / 2 + 1'b1 );
localparam NUM_ADD_STAGE2                                               = ( NUM_ADD_STAGE1 / 2 + 1'b1 );
localparam NUM_ADD_STAGE3                                               = ( NUM_ADD_STAGE2 / 2 + 1'b1 );
localparam NUM_ADD_STAGE4                                               = ( NUM_ADD_STAGE3 / 2 );
localparam NUM_ADD_STAGE5                                               = ( NUM_ADD_STAGE4 / 2 );
localparam ADD_STAGE1_REG                                               = NUM_ADD_STAGE1 * ACC_STAGE1_WIDTH;
localparam ADD_STAGE2_REG                                               = NUM_ADD_STAGE2 * ACC_STAGE2_WIDTH;
localparam ADD_STAGE3_REG                                               = NUM_ADD_STAGE3 * ACC_STAGE3_WIDTH;
localparam ADD_STAGE4_REG                                               = NUM_ADD_STAGE4 * ACC_STAGE4_WIDTH;
localparam ADD_STAGE5_REG                                               = NUM_ADD_STAGE5 * ACC_STAGE5_WIDTH;
/////////////////////////////////////////////////////////////////////////////////
// I/O Configurations
/////////////////////////////////////////////////////////////////////////////////
input                                                                   clk;
input                                                                   resetn;
input signed        [ MULT_REG_VAL_SIZE - 1 : 0 ]                       dataIn;
input                                                                   dataValidIn;
output reg signed   [ FIXED_POINT_SIZE - 1 : 0 ]                        dataOut;
output reg                                                              dataValidOut; 
/////////////////////////////////////////////////////////////////////////////////
// Wires and Registers
/////////////////////////////////////////////////////////////////////////////////
reg                                                                     reset_a;
reg                                                                     reset_b;
reg                 [ ADD_STAGE1_REG - 1 : 0 ]                          add_reg_1;
reg                 [ ADD_STAGE2_REG - 1 : 0 ]                          add_reg_2;
reg                 [ ADD_STAGE3_REG - 1 : 0 ]                          add_reg_3;
reg                 [ ADD_STAGE3_REG - 1 : 0 ]                          inter_reg_3;
reg                 [ ADD_STAGE4_REG - 1 : 0 ]                          add_reg_4;
reg                 [ ADD_STAGE5_REG - 1 : 0 ]                          add_reg_5;
wire                                                                    reset_wire;
integer                                                                 i1;
integer                                                                 i2;
integer                                                                 i3;
integer                                                                 i4;
integer                                                                 i5;
/////////////////////////////////////////////////////////////////////////////////
// Implementation
/////////////////////////////////////////////////////////////////////////////////
assign reset_wire                                                               = resetn & reset_b;

always @(posedge clk) begin
    reset_a                                                                     <= resetn;
    reset_b                                                                     <= reset_a;
end

always @(posedge clk or negedge reset_wire) begin
    if(~reset_wire)begin
        inter_reg_3                                                             <= { ADD_STAGE3_REG { 1'b0 } };
        dataValidOut                                                            <= 1'b0;
    end
    else begin
        dataValidOut                                                            <= dataValidIn;
        inter_reg_3                                                             <= add_reg_3;
    end
end

always@(*)begin
    if( add_reg_5[ ADD_STAGE5_REG - 1 ] < 1'b1 )begin
        if( add_reg_5[ ADD_STAGE5_REG - 1 : FIXED_POINT_SIZE ] > 0 )begin
            dataOut                                                             <= { 1'b0, { ( FIXED_POINT_SIZE - 1 ) { 1'b1 } } };
        end
        else begin
            dataOut                                                             <= add_reg_5[ FIXED_POINT_SIZE - 1 : 0 ];
        end
    end
    else begin
        if( add_reg_5[ ADD_STAGE5_REG - 1 : FIXED_POINT_SIZE ] < { ( ADD_STAGE5_REG - FIXED_POINT_SIZE ) { 1'b1 } } )begin
            dataOut                                                             <= { 1'b1, { ( FIXED_POINT_SIZE - 1 ) { 1'b0 } } };
        end
        else begin
            dataOut                                                             <= add_reg_5[ FIXED_POINT_SIZE - 1 : 0 ];
        end
    end
end

// Stage 1
always@(*)begin
    for( i1 = 0; i1 < KERNEL_TOT_SIZE; i1 = i1 + 1 )begin
        if( i1 == 0 )begin
            if(dataIn[ FIXED_POINT_SIZE - 1 ] == 1'b0)begin
                add_reg_1[ i1 * ACC_STAGE1_WIDTH +: ACC_STAGE1_WIDTH ]          <= { 1'b0, dataIn[ i1 * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ] };
            end
            else begin
                add_reg_1[ i1 * ACC_STAGE1_WIDTH +: ACC_STAGE1_WIDTH ]          <= { 1'b1, dataIn[ i1 * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ] };
            end
        end
        else begin
            if( i1 % 2 == 1 )begin
                add_reg_1[ ( i1 - ( i1 / 2 ) ) * ACC_STAGE1_WIDTH +: ACC_STAGE1_WIDTH ]          
                                                                                <= $signed( dataIn[ i1 * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ] ) + $signed( dataIn[ ( i1 + 1 ) * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ] );
            end
        end
    end
end

// Stage 2
always@(*)begin
    for( i2 = 0; i2 < NUM_ADD_STAGE1; i2 = i2 + 1 )begin
        if( i2 == 0 )begin
            if(add_reg_1[ ACC_STAGE1_WIDTH - 1 ] == 1'b0)begin
                add_reg_2[ i2 * ACC_STAGE2_WIDTH +: ACC_STAGE2_WIDTH ]          <= { 1'b0, add_reg_1[ i2 * ACC_STAGE1_WIDTH +: ACC_STAGE1_WIDTH ] };
            end
            else begin
                add_reg_2[ i2 * ACC_STAGE2_WIDTH +: ACC_STAGE2_WIDTH ]          <= { 1'b1, add_reg_1[ i2 * ACC_STAGE1_WIDTH +: ACC_STAGE1_WIDTH ] };
            end
        end
        else begin
            if( i2 % 2 == 1 )begin
                add_reg_2[ ( i2 - ( i2 / 2 ) ) * ACC_STAGE2_WIDTH +: ACC_STAGE2_WIDTH ]          
                                                                                <= $signed( add_reg_1[ i2 * ACC_STAGE1_WIDTH +: ACC_STAGE1_WIDTH ] ) + $signed( add_reg_1[ ( i2 + 1 ) * ACC_STAGE1_WIDTH +: ACC_STAGE1_WIDTH ] );
            end
        end
    end
end

// Stage 3
always@(*)begin
    for( i3 = 0; i3 < NUM_ADD_STAGE2; i3 = i3 + 1 )begin
        if( i3 == 0 )begin
            if(add_reg_2[ ACC_STAGE1_WIDTH - 1 ] == 1'b0)begin
                add_reg_3[ i3 * ACC_STAGE3_WIDTH +: ACC_STAGE3_WIDTH ]          <= { 1'b0, add_reg_2[ i3 * ACC_STAGE2_WIDTH +: ACC_STAGE2_WIDTH ] };
            end
            else begin
                add_reg_3[ i3 * ACC_STAGE3_WIDTH +: ACC_STAGE3_WIDTH ]          <= { 1'b1, add_reg_2[ i3 * ACC_STAGE2_WIDTH +: ACC_STAGE2_WIDTH ] };
            end
        end
        if( i3 % 2 == 1 )begin
            add_reg_3[ ( i3 - ( i3 / 2 ) ) * ACC_STAGE3_WIDTH +: ACC_STAGE3_WIDTH ]              
                                                                                <= $signed( add_reg_2[ i3 * ACC_STAGE2_WIDTH +: ACC_STAGE2_WIDTH ] ) + $signed( add_reg_2[ ( i3 + 1 ) * ACC_STAGE2_WIDTH +: ACC_STAGE2_WIDTH ] );
        end
    end
end

// Stage 4
always@(*)begin
    for( i4 = 0; i4 < NUM_ADD_STAGE3; i4 = i4 + 1 )begin
        if( i4 % 2 == 0 )begin
            add_reg_4[ ( i4 - ( i4 / 2 ) ) * ACC_STAGE4_WIDTH +: ACC_STAGE4_WIDTH ]              
                                                                                <= $signed( inter_reg_3[ i4 * ACC_STAGE3_WIDTH +: ACC_STAGE3_WIDTH ] ) + $signed( inter_reg_3[ ( i4 + 1 ) * ACC_STAGE3_WIDTH +: ACC_STAGE3_WIDTH ] );
        end
    end
end

// Stage 5
always@(*)begin
    for( i5 = 0; i5 < NUM_ADD_STAGE4; i5 = i5 + 1 )begin
        if( i5 % 2 == 0 )begin
            add_reg_5[ ( i5 - ( i5 / 2 ) ) * ACC_STAGE5_WIDTH +: ACC_STAGE5_WIDTH ]              
                                                                                <= $signed( add_reg_4[ i5 * ACC_STAGE4_WIDTH +: ACC_STAGE4_WIDTH ] ) + $signed( add_reg_4[ ( i5 + 1 ) * ACC_STAGE4_WIDTH +: ACC_STAGE4_WIDTH ] );
        end
    end
end
endmodule
