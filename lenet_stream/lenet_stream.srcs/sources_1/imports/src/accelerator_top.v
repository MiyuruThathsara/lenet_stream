`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Moratuwa, Sri Lanka
// Author: Miyuru Thathsara
// 
// Create Date: 04/07/2021 06:31:01 PM
// Design Name: Lenet Streaming Architecture
// Module Name: accelerator_top
// Project Name: Lenet Streaming Architecture
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module accelerator_top
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
localparam DATA_OUT_SIZE                                                    = KERNEL_SIZE * KERNEL_SIZE * FIXED_POINT_SIZE;
localparam CONV1_DATA_WIDTH                                                 = FIXED_POINT_SIZE * CONV1_NUM_KERNELS;
localparam CONV2_DATA_WIDTH                                                 = FIXED_POINT_SIZE * CONV2_NUM_KERNELS;
localparam CONV3_DATA_WIDTH                                                 = FIXED_POINT_SIZE * CONV3_NUM_KERNELS;
localparam CONV1_NUM_ACTIVATIONS                                            = CONV1_IMAGE_WIDTH * CONV1_IMAGE_HEIGHT;
localparam CONV2_NUM_ACTIVATIONS                                            = CONV2_IMAGE_WIDTH * CONV2_IMAGE_HEIGHT;
localparam CONV3_NUM_ACTIVATIONS                                            = CONV3_IMAGE_WIDTH * CONV3_IMAGE_HEIGHT;
localparam CONV1_ACTIVATION_COUNTER_WIDTH                                   = count2width( CONV1_IMAGE_WIDTH * CONV1_IMAGE_HEIGHT ) + 1'b1;
localparam CONV2_ACTIVATION_COUNTER_WIDTH                                   = count2width( CONV2_IMAGE_WIDTH * CONV2_IMAGE_HEIGHT ) + 1'b1;
localparam CONV3_ACTIVATION_COUNTER_WIDTH                                   = count2width( CONV3_IMAGE_WIDTH * CONV3_IMAGE_HEIGHT ) + 1'b1;
localparam CONV1_KERNEL_COUNTER_WIDTH                                       = count2width( CONV1_NUM_KERNELS ) + 1'b1;
localparam CONV2_KERNEL_COUNTER_WIDTH                                       = count2width( CONV2_NUM_KERNELS ) + 1'b1;
localparam CONV3_KERNEL_COUNTER_WIDTH                                       = count2width( CONV3_NUM_KERNELS ) + 1'b1;
localparam CONV1_BIAS_DATA_SIZE                                             = CONV1_NUM_KERNELS * FIXED_POINT_SIZE;
localparam CONV2_BIAS_DATA_SIZE                                             = CONV2_NUM_KERNELS * FIXED_POINT_SIZE;
localparam CONV3_BIAS_DATA_SIZE                                             = CONV3_NUM_KERNELS * FIXED_POINT_SIZE;
localparam FC1_BIAS_DATA_SIZE                                               = FC1_NUM_OF_NEURONES * FIXED_POINT_SIZE;
localparam FC2_BIAS_DATA_SIZE                                               = FC2_NUM_OF_NEURONES * FIXED_POINT_SIZE;
//////////////////////////////////////////////////////////////////////////////////
// I/O Configuration
//////////////////////////////////////////////////////////////////////////////////
input                                                                       clk;
input                                                                       resetn;
input signed        [ FIXED_POINT_SIZE - 1 : 0 ]                            dataIn;
input                                                                       dataValidIn;
output signed       [ FIXED_POINT_SIZE - 1 : 0 ]                            dataOut;
output                                                                      dataValidOut;
//////////////////////////////////////////////////////////////////////////////////
// Wires and Registers
//////////////////////////////////////////////////////////////////////////////////
reg                                                                         reset_a;
reg                                                                         reset_b;
wire                                                                        reset_wire;
wire                [ DATA_OUT_SIZE - 1 : 0 ]                               line_buffer1_data;
wire                                                                        line_buffer1_valid;
wire                [ DATA_OUT_SIZE - 1 : 0 ]                               line_buffer2_data;
wire                                                                        line_buffer2_valid;
wire                [ DATA_OUT_SIZE - 1 : 0 ]                               line_buffer3_data;
wire                                                                        line_buffer3_valid;
wire                [ CONV1_DATA_WIDTH - 1 : 0 ]                            conv1_data;
wire                [ CONV1_NUM_KERNELS - 1 : 0 ]                           conv1_valid;
reg signed          [ FIXED_POINT_SIZE - 1 : 0 ]                            conv1_data_out;
reg                                                                         conv1_valid_out;
wire signed         [ FIXED_POINT_SIZE - 1 : 0 ]                            maxpool1_data_out;
wire                                                                        maxpool1_valid_out;
wire                [ CONV2_DATA_WIDTH - 1 : 0 ]                            conv2_data;
wire                [ CONV2_NUM_KERNELS - 1 : 0 ]                           conv2_valid;
reg signed          [ FIXED_POINT_SIZE - 1 : 0 ]                            conv2_data_out;
reg                                                                         conv2_valid_out;
wire signed         [ FIXED_POINT_SIZE - 1 : 0 ]                            maxpool2_data_out;
wire                                                                        maxpool2_valid_out;
wire                [ CONV3_DATA_WIDTH - 1 : 0 ]                            conv3_data;
wire                [ CONV3_NUM_KERNELS - 1 : 0 ]                           conv3_valid;
reg signed          [ FIXED_POINT_SIZE - 1 : 0 ]                            conv3_data_out;
reg                                                                         conv3_valid_out;
wire signed         [ FIXED_POINT_SIZE - 1 : 0 ]                            maxpool3_data_out;
wire                                                                        maxpool3_valid_out;
wire signed         [ FIXED_POINT_SIZE - 1 : 0 ]                            fc1_data_out;
wire                                                                        fc1_valid_out;
wire                [ CONV1_NUM_KERNELS - 1 : 0 ]                           conv1_accum_last;
wire                [ CONV2_NUM_KERNELS - 1 : 0 ]                           conv2_accum_last;
wire                [ CONV3_NUM_KERNELS - 1 : 0 ]                           conv3_accum_last;
reg                 [ CONV1_ACTIVATION_COUNTER_WIDTH - 1 : 0 ]              conv1_activation_counter;
reg                 [ CONV2_ACTIVATION_COUNTER_WIDTH - 1 : 0 ]              conv2_activation_counter;
reg                 [ CONV3_ACTIVATION_COUNTER_WIDTH - 1 : 0 ]              conv3_activation_counter;
reg                 [ CONV1_KERNEL_COUNTER_WIDTH - 1 : 0 ]                  conv1_kernel_counter;
reg                 [ CONV2_KERNEL_COUNTER_WIDTH - 1 : 0 ]                  conv2_kernel_counter;
reg                 [ CONV3_KERNEL_COUNTER_WIDTH - 1 : 0 ]                  conv3_kernel_counter;
wire                [ CONV1_BIAS_DATA_SIZE - 1 : 0 ]                        conv1_bias_in;
wire                [ CONV2_BIAS_DATA_SIZE - 1 : 0 ]                        conv2_bias_in;
wire                [ CONV3_BIAS_DATA_SIZE - 1 : 0 ]                        conv3_bias_in;
wire                [ FC1_BIAS_DATA_SIZE - 1 : 0 ]                          fc1_bias_in;
wire                [ FC2_BIAS_DATA_SIZE - 1 : 0 ]                          fc2_bias_in;
//////////////////////////////////////////////////////////////////////////////////
// Implementation
//////////////////////////////////////////////////////////////////////////////////

assign reset_wire                                                               = resetn & reset_b;

always@(posedge clk)begin
    reset_a                                                                     <= resetn;
    reset_b                                                                     <= reset_a;
end

lineBuffer
#(
    .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
    .DATA_WIDTH(DATA_WIDTH),
    .FIXED_POINT_FRACTION_SIZE(FIXED_POINT_FRACTION_SIZE),
    .KERNEL_SIZE(KERNEL_SIZE),
    .IMAGE_WIDTH(CONV1_IN_IMAGE_WIDTH),
    .IMAGE_HEIGHT(CONV1_IN_IMAGE_HEIGHT)
)
lineBuffer1
(
    .clk(clk),
    .resetn(resetn),
    .dataIn(dataIn),
    .dataValidIn(dataValidIn),
    .dataOut(line_buffer1_data),
    .dataValidOut(line_buffer1_valid)
);

conv1_bias
#(
    .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
    .NUM_OF_KERNELS(CONV1_NUM_KERNELS)
)
conv1_bias
(
    .clka(clk),
    .ena(1'b1),
    .wea(1'b0),
    .addra(2'b0),
    .dina({ CONV1_BIAS_DATA_SIZE {1'b0} }),
    .douta(conv1_bias_in)
);

genvar i1;
generate
    for( i1 = 0; i1 < CONV1_NUM_KERNELS; i1 = i1 + 1 )begin
        if( i1 == 0 )begin
            convolution
            #(
                .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
                .DATA_WIDTH(DATA_WIDTH),
                .FIXED_POINT_FRACTION_SIZE(FIXED_POINT_FRACTION_SIZE),
                .KERNEL_SIZE(KERNEL_SIZE),
                .IMAGE_WIDTH(CONV1_IMAGE_WIDTH),
                .IMAGE_HEIGHT(CONV1_IMAGE_HEIGHT),
                .DEPTH_OF_THE_KERNEL(CONV1_DEPTH_KERNEL),
                .LAYER_NUMBER(1),
                .KERNEL_NUMBER(i1 + 1)
            )
            convolution1
            (
                .clk(clk),
                .resetn(resetn),
                .biasIn(conv1_bias_in[ i1 * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ]),
                .dataIn(line_buffer1_data),
                .dataValidIn(line_buffer1_valid),
                .accumLastIn(1'b0),
                .dataOut(conv1_data[ i1 * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ]),
                .dataValidOut(conv1_valid[ i1 ]),
                .accumLastOut(conv1_accum_last[ i1 ])
            );
        end
        else begin
            convolution
            #(
                .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
                .DATA_WIDTH(DATA_WIDTH),
                .FIXED_POINT_FRACTION_SIZE(FIXED_POINT_FRACTION_SIZE),
                .KERNEL_SIZE(KERNEL_SIZE),
                .IMAGE_WIDTH(CONV1_IMAGE_WIDTH),
                .IMAGE_HEIGHT(CONV1_IMAGE_HEIGHT),
                .DEPTH_OF_THE_KERNEL(CONV1_DEPTH_KERNEL),
                .LAYER_NUMBER(1),
                .KERNEL_NUMBER(i1 + 1)
            )
            convolution1
            (
                .clk(clk),
                .resetn(resetn),
                .biasIn(conv1_bias_in[ i1 * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ]),
                .dataIn(line_buffer1_data),
                .dataValidIn(line_buffer1_valid),
                .accumLastIn(conv1_accum_last[ i1 - 1 ]),
                .dataOut(conv1_data[ i1 * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ]),
                .dataValidOut(conv1_valid[ i1 ]),
                .accumLastOut(conv1_accum_last[ i1 ])
            );
        end
    end
endgenerate

always@( posedge clk or negedge reset_wire )begin
    if( ~reset_wire )begin
        conv1_activation_counter                                                <= { CONV1_ACTIVATION_COUNTER_WIDTH { 1'b0 } };
        conv1_kernel_counter                                                    <= { CONV1_KERNEL_COUNTER_WIDTH { 1'b0 } };
    end
    else begin
        if( |conv1_valid )begin
            if( conv1_activation_counter < CONV1_NUM_ACTIVATIONS - 1'b1 )begin
                conv1_activation_counter                                        <= conv1_activation_counter + 1'b1;
            end
            else begin
                conv1_activation_counter                                        <= { CONV1_ACTIVATION_COUNTER_WIDTH { 1'b0 } };
                if( conv1_kernel_counter < CONV1_NUM_KERNELS - 1'b1 )begin
                    conv1_kernel_counter                                        <= conv1_kernel_counter + 1'b1;
                end
                else begin
                    conv1_kernel_counter                                        <= { CONV1_KERNEL_COUNTER_WIDTH { 1'b0 } };
                end
            end
        end
    end
end

always@(*)begin
    conv1_data_out                                                              <= conv1_data[ conv1_kernel_counter * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ];
    conv1_valid_out                                                             <= conv1_valid[ conv1_kernel_counter ];
end

maxpool
#(
    .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
    .DATA_WIDTH(DATA_WIDTH),
    .FIXED_POINT_FRACTION_SIZE(FIXED_POINT_FRACTION_SIZE),
    .KERNEL_SIZE(KERNEL_SIZE),
    .IMAGE_WIDTH(CONV1_IMAGE_WIDTH),
    .IMAGE_HEIGHT(CONV1_IMAGE_HEIGHT)
)
maxpool1
(
    .clk(clk),
    .resetn(resetn),
    .dataIn(conv1_data_out),
    .dataValidIn(conv1_valid_out),
    .dataOut(maxpool1_data_out),
    .dataValidOut(maxpool1_valid_out)
);

lineBuffer
#(
    .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
    .DATA_WIDTH(DATA_WIDTH),
    .FIXED_POINT_FRACTION_SIZE(FIXED_POINT_FRACTION_SIZE),
    .KERNEL_SIZE(KERNEL_SIZE),
    .IMAGE_WIDTH(CONV2_IN_IMAGE_WIDTH),
    .IMAGE_HEIGHT(CONV2_IN_IMAGE_HEIGHT)
)
lineBuffer2
(
    .clk(clk),
    .resetn(resetn),
    .dataIn(maxpool1_data_out),
    .dataValidIn(maxpool1_valid_out),
    .dataOut(line_buffer2_data),
    .dataValidOut(line_buffer2_valid)
);

conv2_bias
#(
    .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
    .NUM_OF_KERNELS(CONV2_NUM_KERNELS)
)
conv2_bias
(
    .clka(clk),
    .ena(1'b1),
    .wea(1'b0),
    .addra(2'b0),
    .dina({ CONV2_BIAS_DATA_SIZE {1'b0} }),
    .douta(conv2_bias_in)
);

genvar i2;
generate
    for( i2 = 0; i2 < CONV2_NUM_KERNELS; i2 = i2 + 1 )begin
        if( i2 == 0 )begin
            convolution
            #(
                .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
                .DATA_WIDTH(DATA_WIDTH),
                .FIXED_POINT_FRACTION_SIZE(FIXED_POINT_FRACTION_SIZE),
                .KERNEL_SIZE(KERNEL_SIZE),
                .IMAGE_WIDTH(CONV2_IMAGE_WIDTH),
                .IMAGE_HEIGHT(CONV2_IMAGE_HEIGHT),
                .DEPTH_OF_THE_KERNEL(CONV2_DEPTH_KERNEL),
                .LAYER_NUMBER(2),
                .KERNEL_NUMBER(i2 + 1)
            )
            convolution2
            (
                .clk(clk),
                .resetn(resetn),
                .biasIn(conv2_bias_in[ i2 * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ]),
                .dataIn(line_buffer2_data),
                .dataValidIn(line_buffer2_valid),
                .accumLastIn(1'b0),
                .dataOut(conv2_data[ i2 * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ]),
                .dataValidOut(conv2_valid[ i2 ]),
                .accumLastOut(conv2_accum_last[ i2 ])
            );
        end
        else begin
            convolution
            #(
                .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
                .DATA_WIDTH(DATA_WIDTH),
                .FIXED_POINT_FRACTION_SIZE(FIXED_POINT_FRACTION_SIZE),
                .KERNEL_SIZE(KERNEL_SIZE),
                .IMAGE_WIDTH(CONV2_IMAGE_WIDTH),
                .IMAGE_HEIGHT(CONV2_IMAGE_HEIGHT),
                .DEPTH_OF_THE_KERNEL(CONV2_DEPTH_KERNEL),
                .LAYER_NUMBER(2),
                .KERNEL_NUMBER(i2 + 1)
            )
            convolution2
            (
                .clk(clk),
                .resetn(resetn),
                .biasIn(conv2_bias_in[ i2 * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ]),
                .dataIn(line_buffer2_data),
                .dataValidIn(line_buffer2_valid),
                .accumLastIn(conv2_accum_last[ i2 - 1 ]),
                .dataOut(conv2_data[ i2 * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ]),
                .dataValidOut(conv2_valid[ i2 ]),
                .accumLastOut(conv2_accum_last[ i2 ])
            );
        end
    end
endgenerate

always@( posedge clk or negedge reset_wire )begin
    if( ~reset_wire )begin
        conv2_activation_counter                                                <= { CONV2_ACTIVATION_COUNTER_WIDTH { 1'b0 } };
        conv2_kernel_counter                                                    <= { CONV2_KERNEL_COUNTER_WIDTH { 1'b0 } };
    end
    else begin
        if( |conv2_valid )begin
            if( conv2_activation_counter < CONV2_NUM_ACTIVATIONS - 1'b1 )begin
                conv2_activation_counter                                        <= conv2_activation_counter + 1'b1;
            end
            else begin
                conv2_activation_counter                                        <= { CONV2_ACTIVATION_COUNTER_WIDTH { 1'b0 } };
                if( conv2_kernel_counter < CONV2_NUM_KERNELS - 1'b1 )begin
                    conv2_kernel_counter                                        <= conv2_kernel_counter + 1'b1;
                end
                else begin
                    conv2_kernel_counter                                        <= { CONV2_KERNEL_COUNTER_WIDTH { 1'b0 } };
                end
            end
        end
    end
end

always@(*)begin
    conv2_data_out                                                              <= conv2_data[ conv2_kernel_counter * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ];
    conv2_valid_out                                                             <= conv2_valid[ conv2_kernel_counter ];
end

maxpool
#(
    .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
    .DATA_WIDTH(DATA_WIDTH),
    .FIXED_POINT_FRACTION_SIZE(FIXED_POINT_FRACTION_SIZE),
    .KERNEL_SIZE(KERNEL_SIZE),
    .IMAGE_WIDTH(CONV2_IMAGE_WIDTH),
    .IMAGE_HEIGHT(CONV2_IMAGE_HEIGHT)
)
maxpool2
(
    .clk(clk),
    .resetn(resetn),
    .dataIn(conv2_data_out),
    .dataValidIn(conv2_valid_out),
    .dataOut(maxpool2_data_out),
    .dataValidOut(maxpool2_valid_out)
);

lineBuffer
#(
    .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
    .DATA_WIDTH(DATA_WIDTH),
    .FIXED_POINT_FRACTION_SIZE(FIXED_POINT_FRACTION_SIZE),
    .KERNEL_SIZE(KERNEL_SIZE),
    .IMAGE_WIDTH(CONV3_IN_IMAGE_WIDTH),
    .IMAGE_HEIGHT(CONV3_IN_IMAGE_HEIGHT)
)
lineBuffer3
(
    .clk(clk),
    .resetn(resetn),
    .dataIn(maxpool2_data_out),
    .dataValidIn(maxpool2_valid_out),
    .dataOut(line_buffer3_data),
    .dataValidOut(line_buffer3_valid)
);

conv3_bias
#(
    .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
    .NUM_OF_KERNELS(CONV3_NUM_KERNELS)
)
conv3_bias
(
    .clka(clk),
    .ena(1'b1),
    .wea(1'b0),
    .addra(2'b0),
    .dina({ CONV3_BIAS_DATA_SIZE {1'b0} }),
    .douta(conv3_bias_in)
);

genvar i3;
generate
    for( i3 = 0; i3 < CONV3_NUM_KERNELS; i3 = i3 + 1 )begin
        if( i3 == 0 )begin
            convolution
            #(
                .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
                .DATA_WIDTH(DATA_WIDTH),
                .FIXED_POINT_FRACTION_SIZE(FIXED_POINT_FRACTION_SIZE),
                .KERNEL_SIZE(KERNEL_SIZE),
                .IMAGE_WIDTH(CONV3_IMAGE_WIDTH),
                .IMAGE_HEIGHT(CONV3_IMAGE_HEIGHT),
                .DEPTH_OF_THE_KERNEL(CONV3_DEPTH_KERNEL),
                .LAYER_NUMBER(3),
                .KERNEL_NUMBER(i3 + 1)
            )
            convolution3
            (
                .clk(clk),
                .resetn(resetn),
                .biasIn(conv3_bias_in[ i3 * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ]),
                .dataIn(line_buffer3_data),
                .dataValidIn(line_buffer3_valid),
                .accumLastIn(1'b0),
                .dataOut(conv3_data[ i3 * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ]),
                .dataValidOut(conv3_valid[ i3 ]),
                .accumLastOut(conv3_accum_last[ i3 ])
            );
        end
        else begin
            convolution
            #(
                .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
                .DATA_WIDTH(DATA_WIDTH),
                .FIXED_POINT_FRACTION_SIZE(FIXED_POINT_FRACTION_SIZE),
                .KERNEL_SIZE(KERNEL_SIZE),
                .IMAGE_WIDTH(CONV3_IMAGE_WIDTH),
                .IMAGE_HEIGHT(CONV3_IMAGE_HEIGHT),
                .DEPTH_OF_THE_KERNEL(CONV3_DEPTH_KERNEL),
                .LAYER_NUMBER(3),
                .KERNEL_NUMBER(i3 + 1)
            )
            convolution3
            (
                .clk(clk),
                .resetn(resetn),
                .biasIn(conv3_bias_in[ i3 * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ]),
                .dataIn(line_buffer3_data),
                .dataValidIn(line_buffer3_valid),
                .accumLastIn(conv3_accum_last[ i3 - 1 ]),
                .dataOut(conv3_data[ i3 * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ]),
                .dataValidOut(conv3_valid[ i3 ]),
                .accumLastOut(conv3_accum_last[ i3 ])
            );
        end
    end
endgenerate

always@( posedge clk or negedge reset_wire )begin
    if( ~reset_wire )begin
        conv3_activation_counter                                                <= { CONV3_ACTIVATION_COUNTER_WIDTH { 1'b0 } };
        conv3_kernel_counter                                                    <= { CONV3_KERNEL_COUNTER_WIDTH { 1'b0 } };
    end
    else begin
        if( |conv3_valid )begin
            if( conv3_activation_counter < CONV3_NUM_ACTIVATIONS - 1'b1 )begin
                conv3_activation_counter                                        <= conv3_activation_counter + 1'b1;
            end
            else begin
                conv3_activation_counter                                        <= { CONV3_ACTIVATION_COUNTER_WIDTH { 1'b0 } };
                if( conv3_kernel_counter < CONV3_NUM_KERNELS - 1'b1 )begin
                    conv3_kernel_counter                                        <= conv3_kernel_counter + 1'b1;
                end
                else begin
                    conv3_kernel_counter                                        <= { CONV3_KERNEL_COUNTER_WIDTH { 1'b0 } };
                end
            end
        end
    end
end

always@(*)begin
    conv3_data_out                                                              <= conv3_data[ conv3_kernel_counter * FIXED_POINT_SIZE +: FIXED_POINT_SIZE ];
    conv3_valid_out                                                             <= conv3_valid[ conv3_kernel_counter ];
end

fc1_bias
#(
    .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
    .NUM_OF_NEURONES(FC1_NUM_OF_NEURONES)
)
fc1_bias
(
    .clka(clk),
    .ena(1'b1),
    .wea(1'b0),
    .addra(2'b0),
    .dina({ FC1_BIAS_DATA_SIZE { 1'b0 } }),
    .douta(fc1_bias_in)
);

fc1
#(
    .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
    .NUM_OF_NEURONES(FC1_NUM_OF_NEURONES),
    .NUM_OF_ACTIVATIONS(FC1_NUM_OF_ACTIVATIONS)
)
fc1
(
    .clk(clk),
    .resetn(resetn),
    .biasIn(fc1_bias_in),
    .dataIn(conv3_data_out),
    .dataValidIn(conv3_valid_out),
    .dataOut(fc1_data_out),
    .dataValidOut(fc1_valid_out)
);

fc2_bias
#(
    .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
    .NUM_OF_NEURONES(FC2_NUM_OF_NEURONES)
)
fc2_bias
(
    .clka(clk),
    .ena(1'b1),
    .wea(1'b0),
    .addra(2'b0),
    .dina({ FC2_BIAS_DATA_SIZE { 1'b0 } }),
    .douta(fc2_bias_in)
);

fc2
#(
    .FIXED_POINT_SIZE(FIXED_POINT_SIZE),
    .NUM_OF_NEURONES(FC2_NUM_OF_NEURONES),
    .NUM_OF_ACTIVATIONS(FC2_NUM_OF_ACTIVATIONS)
)
fc2
(
    .clk(clk),
    .resetn(resetn),
    .biasIn(fc2_bias_in),
    .dataIn(fc1_data_out),
    .dataValidIn(fc1_valid_out),
    .dataOut(dataOut),
    .dataValidOut(dataValidOut)
);

endmodule