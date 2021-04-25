`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Moratuwa, Sri Lanka
// Author: Miyuru Thathsara
// 
// Create Date: 03/31/2021 01:13:53 PM
// Design Name: Convolution Module
// Module Name: convolution
// Project Name: convolution
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module convolution
(
    clk,
    resetn,
    biasIn,
    dataIn,
    dataValidIn,
    accumLastIn,
    dataOut,
    dataValidOut,
    accumLastOut
);
//////////////////////////////////////////////////////////////////////////////////
// Parameters
//////////////////////////////////////////////////////////////////////////////////
`include "params.vh"
parameter DEPTH_OF_THE_KERNEL                                           = 16;
parameter LAYER_NUMBER                                                  = 1;
parameter KERNEL_NUMBER                                                 = 1;
//////////////////////////////////////////////////////////////////////////////////
// Local Parameters
//////////////////////////////////////////////////////////////////////////////////
localparam DATA_IN_SIZE                                                 = KERNEL_SIZE * KERNEL_SIZE * FIXED_POINT_SIZE;
localparam WEIGHT_IN_SIZE                                               = KERNEL_SIZE * KERNEL_SIZE * FIXED_POINT_SIZE;
localparam KERNEL_TOT_SIZE                                              = KERNEL_SIZE * KERNEL_SIZE;
localparam MULT_REG_SIZE                                                = FIXED_POINT_SIZE * 2;
localparam TOTAL_MULT_REG_SIZE                                          = MULT_REG_SIZE * KERNEL_TOT_SIZE;
localparam MULT_REG_VAL_SIZE                                            = FIXED_POINT_SIZE * KERNEL_TOT_SIZE;
localparam ADDR_REG_WIDTH                                               = count2width(DEPTH_OF_THE_KERNEL) + 1'b1;
localparam FIXED_POINT_DECIMAL_SIZE                                     = FIXED_POINT_SIZE - FIXED_POINT_FRACTION_SIZE;
localparam MULT_REG_MSB                                                 = MULT_REG_SIZE - FIXED_POINT_DECIMAL_SIZE;
localparam MULT_REG_LSB                                                 = FIXED_POINT_FRACTION_SIZE;
localparam ROW_COUNTER_WIDTH                                            = count2width(IMAGE_HEIGHT) + 1'b1;
localparam COLUMN_COUNTER_WIDTH                                         = count2width(IMAGE_WIDTH) + 1'b1;
//////////////////////////////////////////////////////////////////////////////////
// I/O Configurations
//////////////////////////////////////////////////////////////////////////////////
input                                                                   clk;
input                                                                   resetn;
input signed        [ FIXED_POINT_SIZE - 1 : 0 ]                        biasIn;
input signed        [ DATA_IN_SIZE - 1 : 0 ]                            dataIn;
input                                                                   dataValidIn;
input                                                                   accumLastIn;
output signed       [ FIXED_POINT_SIZE - 1 : 0 ]                        dataOut;
output                                                                  dataValidOut;
output                                                                  accumLastOut;
//////////////////////////////////////////////////////////////////////////////////
// Wires and Registers
//////////////////////////////////////////////////////////////////////////////////
reg                                                                     reset_a;
reg                                                                     reset_b;
wire                                                                    reset_wire;
reg signed          [ TOTAL_MULT_REG_SIZE - 1 : 0 ]                     mult_reg;
reg signed          [ MULT_REG_VAL_SIZE - 1 : 0 ]                       mult_reg_val;
reg                                                                     mult_reg_val_valid;
reg                 [ ADDR_REG_WIDTH - 1 : 0 ]                          addr_reg;
reg signed          [ DATA_IN_SIZE - 1 : 0 ]                            data_reg;
wire signed         [ FIXED_POINT_SIZE - 1 : 0 ]                        addtree_data;
wire                                                                    addtree_valid;
wire signed         [ FIXED_POINT_SIZE - 1 : 0 ]                        accum_data;
wire                                                                    accum_valid;
reg                                                                     kernel_en;
reg                 [ ROW_COUNTER_WIDTH - 1 : 0 ]                       row_counter;
reg                 [ COLUMN_COUNTER_WIDTH - 1 : 0 ]                    column_counter;
wire signed         [ WEIGHT_IN_SIZE - 1 : 0 ]                          weight_wire;
integer                                                                 i;
integer                                                                 j;
//////////////////////////////////////////////////////////////////////////////////
// Implementation
//////////////////////////////////////////////////////////////////////////////////
assign reset_wire                                                                   = resetn & reset_b;

always@(*)begin
    for( j = 0; j < KERNEL_TOT_SIZE; j = j + 1 )begin
        if( mult_reg[ ( j + 1 ) * MULT_REG_SIZE - 1 ] < 1'b1 )begin
            if( mult_reg[ j * MULT_REG_SIZE + MULT_REG_MSB +: FIXED_POINT_DECIMAL_SIZE ] > { FIXED_POINT_DECIMAL_SIZE {1'b0} } )begin
                mult_reg_val[ j * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ]            <= { 1'b0, { ( FIXED_POINT_SIZE - 1'b1 ){ 1'b1 } } };
            end
            else begin
                if( mult_reg[ j * MULT_REG_SIZE + MULT_REG_LSB - 1 ] == 1'b0 )begin
                    mult_reg_val[ j * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ]        <= mult_reg[ j * MULT_REG_SIZE + MULT_REG_LSB +: FIXED_POINT_SIZE ];
                end
                else begin
                    mult_reg_val[ j * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ]        <= mult_reg[ j * MULT_REG_SIZE + MULT_REG_LSB +: FIXED_POINT_SIZE ] + 1'b1;
                end
            end
        end
        else begin
            if( mult_reg[ j * MULT_REG_SIZE + MULT_REG_MSB +: FIXED_POINT_DECIMAL_SIZE ] < { FIXED_POINT_DECIMAL_SIZE {1'b1} } )begin
                mult_reg_val[ j * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ]            <= { 1'b1, { ( FIXED_POINT_SIZE - 1'b1 ){ 1'b0 } } };
            end
            else begin
                if( |mult_reg[ j * MULT_REG_SIZE + MULT_REG_LSB - 2 -: MULT_REG_LSB - 1 ] == 1'b1 )begin
                    if( mult_reg[ j * MULT_REG_SIZE + MULT_REG_LSB - 1 ] == 1'b0 )begin
                        mult_reg_val[ j * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ]    <= mult_reg[ j * MULT_REG_SIZE + MULT_REG_LSB +: FIXED_POINT_SIZE ] + 1'b1;
                    end
                    else begin
                        mult_reg_val[ j * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ]    <= mult_reg[ j * MULT_REG_SIZE + MULT_REG_LSB +: FIXED_POINT_SIZE ];
                    end
                end
                else begin
                    if( mult_reg[ j * MULT_REG_SIZE + MULT_REG_LSB - 1 ] == 1'b1 )begin
                        mult_reg_val[ j * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ]    <= mult_reg[ j * MULT_REG_SIZE + MULT_REG_LSB +: FIXED_POINT_SIZE ] + 1'b1;
                    end
                    else begin
                        mult_reg_val[ j * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ]    <= mult_reg[ j * MULT_REG_SIZE + MULT_REG_LSB +: FIXED_POINT_SIZE ];
                    end
                end
            end
        end
    end
end

always @(posedge clk) begin
    reset_a                                                                         <= resetn;
    reset_b                                                                         <= reset_a;
end

always@(posedge clk or negedge reset_wire)begin
    if(~reset_wire)begin
        mult_reg                                                                    <= { TOTAL_MULT_REG_SIZE { 1'b0 } };
        mult_reg_val_valid                                                          <= 1'b0;
    end
    else begin
        mult_reg_val_valid                                                          <= kernel_en;
        if(kernel_en)begin
            for( i = 0; i < KERNEL_TOT_SIZE; i = i + 1'b1 )begin
                mult_reg[ i * MULT_REG_SIZE +: MULT_REG_SIZE ]                      <= $signed( weight_wire[ i * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ] ) * $signed( data_reg[ i * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ] );
            end
        end
    end
end

always@(posedge clk or negedge reset_wire)begin
    if(~reset_wire)begin
        addr_reg                                                                    <= { ADDR_REG_WIDTH {1'b0} };
        kernel_en                                                                   <= 1'b0;
        data_reg                                                                    <= { DATA_IN_SIZE { 1'b0 } };
        column_counter                                                              <= { COLUMN_COUNTER_WIDTH {1'b0} };
        row_counter                                                                 <= { ROW_COUNTER_WIDTH {1'b0} };
    end
    else begin
        kernel_en                                                                   <= dataValidIn;
        data_reg                                                                    <= dataIn;
        if(dataValidIn)begin
            if( column_counter < IMAGE_WIDTH - 1'b1 )begin
                    column_counter                                              <= column_counter + 1'b1;
            end
            else begin
                column_counter                                                  <= { COLUMN_COUNTER_WIDTH { 1'b0 } };
                if( row_counter < IMAGE_HEIGHT - 1'b1 )begin
                    row_counter                                                 <= row_counter + 1'b1;
                end
                else begin
                    row_counter                                                 <= { ROW_COUNTER_WIDTH { 1'b0 } };
                    if( addr_reg < DEPTH_OF_THE_KERNEL - 1'b1 )begin
                        addr_reg                                                <= addr_reg + 1'b1;
                    end
                    else begin
                        addr_reg                                                <= { ADDR_REG_WIDTH { 1'b0 } };
                    end
                end
            end
        end
        // else begin
        //     if(column_counter >= IMAGE_WIDTH - 1'b1)begin
        //         if(row_counter >= IMAGE_HEIGHT - 1'b1)begin
        //             addr_reg                                                        <= { ADDR_REG_WIDTH {1'b0} };
        //             row_counter                                                     <= { ROW_COUNTER_WIDTH {1'b0} };
        //             column_counter                                                  <= { COLUMN_COUNTER_WIDTH {1'b0} };
        //         end
        //     end
        // end
    end
end

weights_kernel
#(
    .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
    .FIXED_POINT_FRACTION_SIZE(FIXED_POINT_FRACTION_SIZE),
    .KERNEL_SIZE(KERNEL_SIZE),
    .DEPTH_OF_THE_KERNEL(DEPTH_OF_THE_KERNEL),
    .LAYER_NUMBER(LAYER_NUMBER),
    .KERNEL_NUMBER(KERNEL_NUMBER)
)
weights_kernel
(
    .clka(clk),
    .ena(dataValidIn),
    .wea(1'b0),
    .addra(addr_reg),
    .dina({ WEIGHT_IN_SIZE { 1'b0 } }),
    .douta(weight_wire)
);

addertree_25
#(
    .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
    .FIXED_POINT_FRACTION_SIZE(FIXED_POINT_FRACTION_SIZE),
    .KERNEL_SIZE(KERNEL_SIZE),
    .IMAGE_WIDTH(IMAGE_WIDTH),
    .IMAGE_HEIGHT(IMAGE_HEIGHT)
)
addertree
(
    .clk(clk),
    .resetn(resetn),
    .dataIn(mult_reg_val),
    .dataValidIn(mult_reg_val_valid),
    .dataOut(addtree_data),
    .dataValidOut(addtree_valid)
);

accumilator
#(
    .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
    .FIXED_POINT_FRACTION_SIZE(FIXED_POINT_FRACTION_SIZE),
    .KERNEL_SIZE(KERNEL_SIZE),
    .IMAGE_WIDTH(IMAGE_WIDTH),
    .IMAGE_HEIGHT(IMAGE_HEIGHT),
    .DEPTH_OF_THE_KERNEL(DEPTH_OF_THE_KERNEL),
    .KERNEL_NUMBER(KERNEL_NUMBER),
    .LAYER_NUMBER(LAYER_NUMBER)
)
accumilator
(
    .clk(clk),
    .resetn(resetn),
    .biasIn(biasIn),
    .dataIn(addtree_data),
    .dataValidIn(addtree_valid),
    .accumLastIn(accumLastIn),
    .dataOut(accum_data),
    .dataValidOut(accum_valid),
    .accumLastOut(accumLastOut)
);

relu
#(
    .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
    .FIXED_POINT_FRACTION_SIZE(FIXED_POINT_FRACTION_SIZE),
    .KERNEL_SIZE(KERNEL_SIZE),
    .IMAGE_WIDTH(IMAGE_WIDTH),
    .IMAGE_HEIGHT(IMAGE_HEIGHT)
)
relu
(
    .clk(clk),
    .resetn(resetn),
    .dataIn(accum_data),
    .dataValidIn(accum_valid),
    .dataOut(dataOut),
    .dataValidOut(dataValidOut)
);
endmodule
