`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Moratuwa, Sri Lanka
// Author: Miyuru Thathsara
// 
// Create Date: 04/01/2021 01:27:07 PM
// Design Name: Accumilator
// Module Name: accumilator
// Project Name: Convolutional Layer
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module accumilator
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
parameter DEPTH_OF_THE_KERNEL                                                   = 16;
parameter KERNEL_NUMBER                                                         = 1;
parameter LAYER_NUMBER                                                          = 1;
//////////////////////////////////////////////////////////////////////////////////
// Local Parameters
//////////////////////////////////////////////////////////////////////////////////
localparam DEPTH_COUNTER_WIDTH                                                  = count2width(DEPTH_OF_THE_KERNEL) + 1'b1;
localparam TOTAL_ACTIVATIONS                                                    = IMAGE_WIDTH * IMAGE_HEIGHT;  
localparam ACTIVATION_COUNTER_WIDTH                                             = count2width(CONV1_IMAGE_WIDTH * CONV1_IMAGE_HEIGHT);
localparam ADDITIONAL_ACCUM_WIDTH                                               = count2width(DEPTH_OF_THE_KERNEL) + 1'b1;        
localparam ACCUM_WIDTH                                                          = ADDITIONAL_ACCUM_WIDTH + FIXED_POINT_SIZE;
//////////////////////////////////////////////////////////////////////////////////
// I/O Configuration
//////////////////////////////////////////////////////////////////////////////////
input                                                                           clk;
input                                                                           resetn;
input signed        [ FIXED_POINT_SIZE - 1 : 0 ]                                biasIn;
input signed        [ FIXED_POINT_SIZE - 1 : 0 ]                                dataIn;
input                                                                           dataValidIn;
input                                                                           accumLastIn;
output reg signed   [ FIXED_POINT_SIZE - 1 : 0 ]                                dataOut;
output reg                                                                      dataValidOut;
output reg                                                                      accumLastOut;
//////////////////////////////////////////////////////////////////////////////////
// Wires and Registers
//////////////////////////////////////////////////////////////////////////////////
reg                                                                             reset_a;
reg                                                                             reset_b;
reg                 [ DEPTH_COUNTER_WIDTH - 1 : 0 ]                             depth_counter;
reg                 [ DEPTH_COUNTER_WIDTH - 1 : 0 ]                             depth_counter_reg;
wire                [ ACTIVATION_COUNTER_WIDTH - 1 : 0 ]                        activation_addr_counter;
reg                 [ ACTIVATION_COUNTER_WIDTH - 1 : 0 ]                        activation_counter;
reg                 [ ACTIVATION_COUNTER_WIDTH - 1 : 0 ]                        activation_counter_a;
reg                 [ ACTIVATION_COUNTER_WIDTH - 1 : 0 ]                        activation_counter_reg_a;
reg                 [ ACTIVATION_COUNTER_WIDTH - 1 : 0 ]                        activation_counter_reg_b;
reg signed          [ ACCUM_WIDTH - 1 : 0 ]                                     accumilator;
reg                                                                             wr_en;
wire                                                                            rd_en;
reg                                                                             data_valid_reg;
reg signed          [ FIXED_POINT_SIZE - 1 : 0 ]                                data_in_reg;
reg                                                                             bram_read;
reg                                                                             bram_read_a;
reg                                                                             bram_read_flag;
reg                                                                             bram_read_flag_down;
reg                                                                             bram_read_flag_reg;
reg                                                                             bram_read_flag_reg_a;
reg                                                                             bram_read_flag_reg_b;
reg                                                                             bram_read_write_flag;
reg                 [ FIXED_POINT_SIZE - 1 : 0 ]                                accum_write;
wire signed         [ FIXED_POINT_SIZE - 1 : 0 ]                                accum_activation;
wire                                                                            reset_wire;
//////////////////////////////////////////////////////////////////////////////////
// Implementation
//////////////////////////////////////////////////////////////////////////////////
assign reset_wire                                                               = resetn & reset_b;
assign rd_en                                                                    = bram_read | dataValidIn | bram_read_a;
assign activation_addr_counter                                                  = bram_read_a ? activation_counter_a : activation_counter;

always@(posedge clk) begin
    reset_a                                                                     <= resetn;
    reset_b                                                                     <= reset_a;
end

always@(posedge clk or negedge reset_wire)begin
    if(~reset_wire)begin
        activation_counter                                                      <= { ACTIVATION_COUNTER_WIDTH { 1'b0 } };
        depth_counter                                                           <= { DEPTH_COUNTER_WIDTH { 1'b0 } };
        depth_counter_reg                                                       <= { DEPTH_COUNTER_WIDTH { 1'b0 } };
        bram_read_flag                                                          <= 1'b0;
        bram_read_write_flag                                                    <= 1'b0;
        bram_read                                                               <= 1'b0;
    end
    else begin
        depth_counter_reg                                                       <= depth_counter;
        if( dataValidIn )begin
            if( bram_read_write_flag )begin
                if( activation_counter < TOTAL_ACTIVATIONS - 1'b1 )begin
                    activation_counter                                          <= activation_counter + 1'b1;
                    bram_read                                                   <= 1'b1;
                end
                else begin
                    activation_counter                                          <= { ACTIVATION_COUNTER_WIDTH { 1'b0 } };
                    if( depth_counter < DEPTH_OF_THE_KERNEL - 1'b1 )begin
                        depth_counter                                           <= depth_counter + 1'b1;
                        bram_read                                               <= 1'b1;
                    end
                    else begin
                        depth_counter                                           <= { DEPTH_COUNTER_WIDTH { 1'b0 } };
                        bram_read_write_flag                                    <= 1'b0;
                        bram_read                                               <= 1'b0;
                        if( KERNEL_NUMBER == 1 )begin
                            bram_read_flag                                      <= 1'b1;
                        end
                        else begin
                            bram_read_flag                                      <= 1'b0;
                        end
                    end
                end
            end
            else begin
                if( activation_counter < TOTAL_ACTIVATIONS - 1'b1 )begin
                    activation_counter                                          <= activation_counter + 1'b1;
                end
                else begin
                    activation_counter                                          <= { ACTIVATION_COUNTER_WIDTH { 1'b0 } };
                    if( depth_counter < DEPTH_OF_THE_KERNEL - 1'b1 )begin
                        depth_counter                                           <= depth_counter + 1'b1;
                        if( depth_counter == { DEPTH_COUNTER_WIDTH { 1'b0 } } )begin
                            bram_read_write_flag                                <= 1'b1;
                            bram_read                                           <= 1'b1;
                        end
                        else begin
                            bram_read_write_flag                                <= 1'b0;
                            bram_read                                           <= 1'b0;
                        end
                    end
                    else begin
                        depth_counter                                           <= { DEPTH_COUNTER_WIDTH { 1'b0 } };
                        if( KERNEL_NUMBER == 1 )begin
                            if( depth_counter == { DEPTH_COUNTER_WIDTH { 1'b0 } } )begin
                                bram_read_flag                                  <= 1'b1;
                            end
                            else begin
                                bram_read_flag                                  <= 1'b0;
                            end
                        end
                    end
                end
            end
        end
        else begin
            bram_read                                                           <= 1'b0;
            if( LAYER_NUMBER == 3 )begin
                if( bram_read_flag )begin
                    bram_read_flag                                              <= 1'b0;
                end
            end
            else begin
                if( bram_read_flag_down )begin
                    bram_read_flag                                              <= 1'b0;
                end
            end
            if( accumLastIn )begin
                bram_read_flag                                                  <= 1'b1;
            end
        end
    end
end

always@(posedge clk or negedge reset_wire)begin
    if( ~reset_wire )begin
        accumilator                                                             <= { ACCUM_WIDTH { 1'b0 } };
        wr_en                                                                   <= 1'b0;
        activation_counter_reg_a                                                <= { ACTIVATION_COUNTER_WIDTH { 1'b0 } };
        activation_counter_reg_b                                                <= { ACTIVATION_COUNTER_WIDTH { 1'b0 } };
        dataValidOut                                                            <= 1'b0;
        dataOut                                                                 <= { FIXED_POINT_SIZE { 1'b0 } };
    end
    else begin
        activation_counter_reg_b                                                <= activation_counter_reg_a;
        activation_counter_reg_a                                                <= activation_counter;
        if( data_valid_reg )begin
            wr_en                                                               <= 1'b1;
            if( depth_counter_reg == { DEPTH_COUNTER_WIDTH { 1'b0 } } )begin
                if( data_in_reg[ FIXED_POINT_SIZE - 1 ] )begin
                    accumilator                                                 <= { { ADDITIONAL_ACCUM_WIDTH {1'b1} }, data_in_reg };
                end
                else begin
                    accumilator                                                 <= { { ADDITIONAL_ACCUM_WIDTH {1'b0} }, data_in_reg };
                end
            end
            else begin
                accumilator                                                     <= data_in_reg + accum_activation;
            end
        end
        else begin
            wr_en                                                               <= 1'b0;
        end
    end
end

always@(posedge clk or negedge reset_wire)begin
    if( ~reset_wire )begin
        bram_read_flag_reg                                                          <= 1'b0;
        bram_read_flag_reg_a                                                        <= 1'b0;
        bram_read_flag_reg_b                                                        <= 1'b0;
        bram_read_a                                                                 <= 1'b0;
        activation_counter_a                                                        <= { ACTIVATION_COUNTER_WIDTH { 1'b0 } };
        bram_read_flag_down                                                         <= 1'b0;
        accumLastOut                                                                <= 1'b0;
    end
    else begin
        bram_read_flag_reg                                                          <= bram_read_flag;
        bram_read_flag_reg_a                                                        <= bram_read_flag_reg;
        bram_read_flag_reg_b                                                        <= bram_read_flag_reg_a;
        if( bram_read_a )begin
            if( activation_counter_a < TOTAL_ACTIVATIONS - 1'b1 )begin
                activation_counter_a                                                <= activation_counter_a + 1'b1;
                if( activation_counter_a == TOTAL_ACTIVATIONS - 3'd4 )begin
                    bram_read_flag_down                                             <= 1'b1;
                    accumLastOut                                                    <= 1'b0;
                end
                else begin
                    bram_read_flag_down                                             <= 1'b0;
                    if( activation_counter_a == TOTAL_ACTIVATIONS - 3'd2 )begin
                        accumLastOut                                                <= 1'b1;
                    end
                    else begin
                        accumLastOut                                                <= 1'b0;
                    end
                end
            end
            else begin
                activation_counter_a                                                <= { ACTIVATION_COUNTER_WIDTH { 1'b0 } };
                bram_read_a                                                         <= 1'b0;
                if( LAYER_NUMBER == 3 )begin
                    accumLastOut                                                    <= 1'b1;
                end
                else begin
                    accumLastOut                                                    <= 1'b0;
                end
            end
        end
        else begin
            accumLastOut                                                            <= 1'b0;
            if( bram_read_flag_reg )begin
                bram_read_a                                                         <= 1'b1;
            end
        end
    end
end

always@(posedge clk or negedge reset_wire) begin
    if(~reset_wire)begin
        data_valid_reg                                                          <= 1'b0;
        data_in_reg                                                             <= { FIXED_POINT_SIZE { 1'b0 } };
    end
    else begin
        data_valid_reg                                                          <= dataValidIn;
        data_in_reg                                                             <= dataIn;
        if( bram_read_flag_reg_b )begin
            dataValidOut                                                        <= 1'b1;
            dataOut                                                             <= accum_activation + biasIn;
        end
        else begin
            dataValidOut                                                        <= 1'b0;
            dataOut                                                             <= { FIXED_POINT_SIZE { 1'b0 } };
        end
    end
end

always@(*)begin
    if( accumilator[ ACCUM_WIDTH - 1 ] < 1'b1 )begin
        if( accumilator[ ACCUM_WIDTH - 1 : FIXED_POINT_SIZE ] > { ADDITIONAL_ACCUM_WIDTH { 1'b0 } } )begin
            accum_write                                                         <= { 1'b0, { ( FIXED_POINT_SIZE - 1 ) { 1'b1 } } };
        end
        else begin
            accum_write                                                         <= accumilator[ FIXED_POINT_SIZE - 1 : 0 ];
        end
    end
    else begin
        if( accumilator[ ACCUM_WIDTH - 1 : FIXED_POINT_SIZE ] < { ADDITIONAL_ACCUM_WIDTH { 1'b1 } } )begin
            accum_write                                                         <= { 1'b1, { ( FIXED_POINT_SIZE - 1 ) { 1'b0 } } };
        end
        else begin
            accum_write                                                         <= accumilator[ FIXED_POINT_SIZE - 1 : 0 ];
        end
    end
end

activation_bram

activation_bram
(
    .clka(clk),
    .wea(wr_en),
    .addra(activation_counter_reg_b),
    .dina(accum_write),
    .clkb(clk),
    .enb(rd_en),
    .addrb(activation_addr_counter),
    .doutb(accum_activation)
);
endmodule
