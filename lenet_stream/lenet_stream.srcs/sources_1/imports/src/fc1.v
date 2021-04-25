`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Moratuwa, Sri Lanka
// Author: Miyuru Thathsara
// 
// Create Date: 04/05/2021 01:55:57 AM
// Design Name: Fully Connected Layer
// Module Name: fc
// Project Name: FC
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fc1
(
    clk,
    resetn,
    biasIn,
    dataIn,
    dataValidIn,
    dataOut,
    dataValidOut
);
//////////////////////////////////////////////////////////////////////////////////
// Parameters
//////////////////////////////////////////////////////////////////////////////////
`include "params.vh "
parameter NUM_OF_NEURONES                                                   = 84;
parameter NUM_OF_ACTIVATIONS                                                = 120;
//////////////////////////////////////////////////////////////////////////////////
// Local Parameters
//////////////////////////////////////////////////////////////////////////////////
localparam MULT_WIDTH                                                       = FIXED_POINT_SIZE * 2;
localparam ACCUM_ADD_WIDTH                                                  = count2width( NUM_OF_ACTIVATIONS ) + 1'b1;
localparam ACCUM_WIDTH                                                      = ACCUM_ADD_WIDTH + MULT_WIDTH;
localparam ACTIVATION_COUNTER_WIDTH                                         = count2width( NUM_OF_ACTIVATIONS ) + 1'b1;
localparam BUFFER_WIDTH                                                     = NUM_OF_NEURONES * ACCUM_WIDTH;
localparam WEIGHT_BUS_WIDTH                                                 = NUM_OF_NEURONES * FIXED_POINT_SIZE;
localparam DATA_OUT_COUNTER_WIDTH                                           = count2width(NUM_OF_NEURONES) + 1'b1;
localparam ACCUM_EXTRA_MSB                                                  = ACCUM_WIDTH - FIXED_POINT_SIZE - FIXED_POINT_SIZE / 2;
localparam ACCUM_EXTRA_LSB                                                  = FIXED_POINT_SIZE / 2;
localparam BIAS_DATA_SIZE                                                   = NUM_OF_NEURONES * FIXED_POINT_SIZE;
//////////////////////////////////////////////////////////////////////////////////
// I/O Configuration
//////////////////////////////////////////////////////////////////////////////////
input                                                                       clk;
input                                                                       resetn;
input signed            [ BIAS_DATA_SIZE - 1 : 0 ]                          biasIn;
input signed            [ FIXED_POINT_SIZE - 1 : 0 ]                        dataIn;
input                                                                       dataValidIn;
output signed           [ FIXED_POINT_SIZE - 1 : 0 ]                        dataOut;
output                                                                      dataValidOut;
//////////////////////////////////////////////////////////////////////////////////
// Wires and Registers
//////////////////////////////////////////////////////////////////////////////////
reg                                                                         reset_a;
reg                                                                         reset_b;
reg signed              [ FIXED_POINT_SIZE - 1 : 0 ]                        data_in_reg;
reg                                                                         data_valid_reg;
reg                     [ BUFFER_WIDTH - 1 : 0 ]                            accum_buffer;
reg                     [ ACTIVATION_COUNTER_WIDTH - 1 : 0 ]                activation_counter;
reg                     [ ACTIVATION_COUNTER_WIDTH - 1 : 0 ]                activation_counter_reg;
reg                                                                         accum_end_flag;
reg                     [ DATA_OUT_COUNTER_WIDTH - 1 : 0 ]                  data_out_counter;
reg                     [ FIXED_POINT_SIZE - 1 : 0 ]                        activation_out;
reg                                                                         activation_valid_out;
wire signed             [ ACCUM_WIDTH - 1 : 0 ]                             accum_activation;
wire signed             [ WEIGHT_BUS_WIDTH - 1 : 0 ]                        weight_wire;
wire                                                                        reset_wire;
integer                                                                     i1;
integer                                                                     i2;
//////////////////////////////////////////////////////////////////////////////////
// Implementation
//////////////////////////////////////////////////////////////////////////////////
assign reset_wire                                                           = resetn & reset_b;
assign accum_activation                                                     = $signed( accum_buffer[ 0 +: ACCUM_WIDTH ] ) + $signed( { biasIn[ data_out_counter * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ], { FIXED_POINT_FRACTION_SIZE { 1'b0 } } });

always@(posedge clk) begin
    reset_a                                                                 <= resetn;
    reset_b                                                                 <= reset_a;
end

always@(posedge clk or negedge reset_wire)begin
    if( ~reset_wire )begin
        data_in_reg                                                         <= { FIXED_POINT_SIZE { 1'b0 } };
        data_valid_reg                                                      <= 1'b0;
        activation_counter                                                  <= { ACTIVATION_COUNTER_WIDTH { 1'b0 } };
        activation_counter_reg                                              <= { ACTIVATION_COUNTER_WIDTH { 1'b0 } };
    end
    else begin
        data_in_reg                                                         <= dataIn;
        data_valid_reg                                                      <= dataValidIn;
        activation_counter_reg                                              <= activation_counter;
        if( dataValidIn )begin
            if( activation_counter < NUM_OF_ACTIVATIONS - 1 )begin
                activation_counter                                          <= activation_counter + 1'b1;
            end
            else begin
                activation_counter                                          <= { ACTIVATION_COUNTER_WIDTH { 1'b0 } };
            end
        end
    end
end

always@( posedge clk or negedge reset_wire )begin
    if( ~reset_wire )begin
        accum_buffer                                                        <= { BUFFER_WIDTH { 1'b0 } };
        accum_end_flag                                                      <= 1'b0;
        data_out_counter                                                    <= { DATA_OUT_COUNTER_WIDTH { 1'b0 } };
    end
    else begin
        if( accum_end_flag )begin
            accum_buffer                                                    <= accum_buffer >> ACCUM_WIDTH;
            if( data_out_counter < NUM_OF_NEURONES - 1 )begin
                accum_end_flag                                              <= 1'b1;
                activation_valid_out                                        <= 1'b1;
                data_out_counter                                            <= data_out_counter + 1'b1;
            end
            else begin
                accum_end_flag                                              <= 1'b0;
                activation_valid_out                                        <= 1'b0;
                data_out_counter                                            <= { DATA_OUT_COUNTER_WIDTH { 1'b0 } };
            end
        end
        else begin
            if( data_valid_reg )begin
                if( activation_counter_reg == { ACTIVATION_COUNTER_WIDTH { 1'b0 } } )begin
                    for( i1 = 0; i1 < NUM_OF_NEURONES; i1 = i1 + 1 )begin
                        accum_buffer[ i1 * ACCUM_WIDTH +: ACCUM_WIDTH ]     <= $signed( weight_wire[ i1 * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ] ) * $signed(data_in_reg);
                    end
                end
                else begin
                    for( i2 = 0; i2 < NUM_OF_NEURONES; i2 = i2 + 1 )begin
                        accum_buffer[ i2 * ACCUM_WIDTH +: ACCUM_WIDTH ]     <= $signed( accum_buffer[ i2 * ACCUM_WIDTH +: ACCUM_WIDTH ] ) + $signed( weight_wire[ i2 * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ] ) * $signed(data_in_reg);
                    end
                    if( activation_counter_reg < NUM_OF_ACTIVATIONS - 1 )begin
                        accum_end_flag                                      <= 1'b0;
                        activation_valid_out                                <= 1'b0;
                    end
                    else begin
                        accum_end_flag                                      <= 1'b1;
                        activation_valid_out                                <= 1'b1;
                    end
                end
            end
        end
    end
end

always@(*)begin
    if( accum_activation[ ACCUM_WIDTH - 1 ] )begin
        if( accum_activation[ ACCUM_WIDTH - 1 -: ACCUM_EXTRA_MSB ] < { ACCUM_EXTRA_MSB { 1'b1 } })begin
            activation_out                                                  <= { 1'b1, { ( FIXED_POINT_SIZE - 1 ) { 1'b0 } } };
        end
        else begin
            activation_out                                                  <= accum_activation[ FIXED_POINT_FRACTION_SIZE +: FIXED_POINT_SIZE ];
        end
    end
    else begin
        if( accum_activation[ ACCUM_WIDTH - 1 -: ACCUM_EXTRA_MSB ] > { ACCUM_EXTRA_MSB { 1'b0 } })begin
            activation_out                                                  <= { 1'b0, { ( FIXED_POINT_SIZE - 1 ) { 1'b1 } } };
        end
        else begin
            activation_out                                                  <= accum_activation[ FIXED_POINT_FRACTION_SIZE +: FIXED_POINT_SIZE ];
        end
    end
end

fc1_weights
#(
    .NUM_OF_ACTIVATIONS(NUM_OF_ACTIVATIONS),
    .NUM_OF_NEURONES(NUM_OF_NEURONES)
)
fc1_weights
(
    .clka(clk),
    .ena(dataValidIn),
    .wea(1'b0),
    .addra(activation_counter),
    .dina({ WEIGHT_BUS_WIDTH { 1'b0 } }),
    .douta(weight_wire)
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
    .dataIn(activation_out),
    .dataValidIn(activation_valid_out),
    .dataOut(dataOut),
    .dataValidOut(dataValidOut)
);
endmodule
