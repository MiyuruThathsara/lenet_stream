/////////////////////////////////////////////////////////////////////////////////////
// Parameters 
/////////////////////////////////////////////////////////////////////////////////////
parameter FIXED_POINT_SIZE                                              = 16;
parameter DATA_WIDTH                                                    = 8;
parameter FIXED_POINT_FRACTION_SIZE                                     = 8;
parameter KERNEL_SIZE                                                   = 5;
parameter IMAGE_WIDTH                                                   = 32;
parameter IMAGE_HEIGHT                                                  = 32;
parameter CONV1_IN_IMAGE_WIDTH                                          = 32;
parameter CONV1_IN_IMAGE_HEIGHT                                         = 32;
parameter CONV2_IN_IMAGE_WIDTH                                          = 14;
parameter CONV2_IN_IMAGE_HEIGHT                                         = 14;
parameter CONV3_IN_IMAGE_WIDTH                                          = 5;
parameter CONV3_IN_IMAGE_HEIGHT                                         = 5;
parameter CONV1_IMAGE_WIDTH                                             = 28;
parameter CONV1_IMAGE_HEIGHT                                            = 28;
parameter CONV2_IMAGE_WIDTH                                             = 10;
parameter CONV2_IMAGE_HEIGHT                                            = 10;
parameter CONV3_IMAGE_WIDTH                                             = 1;
parameter CONV3_IMAGE_HEIGHT                                            = 1;
parameter CONV1_NUM_KERNELS                                             = 6;
parameter CONV2_NUM_KERNELS                                             = 16;
parameter CONV3_NUM_KERNELS                                             = 120;
parameter CONV1_DEPTH_KERNEL                                            = 1;
parameter CONV2_DEPTH_KERNEL                                            = 6;
parameter CONV3_DEPTH_KERNEL                                            = 16;
parameter FC1_NUM_OF_NEURONES                                           = 84;
parameter FC2_NUM_OF_NEURONES                                           = 10;
parameter FC1_NUM_OF_ACTIVATIONS                                        = 120;
parameter FC2_NUM_OF_ACTIVATIONS                                        = 84;
/////////////////////////////////////////////////////////////////////////////////////
// Local Parameters
/////////////////////////////////////////////////////////////////////////////////////
localparam NUM_CHARS                                                    = 3;
/////////////////////////////////////////////////////////////////////////////////////
// Util Functions
/////////////////////////////////////////////////////////////////////////////////////
function integer count2width(input integer value);
    if (value <= 1) begin
	   	count2width = 1;
    end
    else begin
        value = value - 1;
        for (count2width = 0; value > 0; count2width = count2width + 1) begin
            value = value >> 1;
        end
    end
endfunction
// Int to string convert function
function [NUM_CHARS*8-1:0] convertIntToChars;
    input integer x;
    integer i;
    begin
        convertIntToChars = 0;
        if (x < 0 || x >= 10 ** NUM_CHARS) begin
            $error("invalid value for x! got: %0d", x);
        end
        for (i = 0; i < NUM_CHARS; i = i + 1) begin
            convertIntToChars [8*i +: 8] = "0" + (x / 10 ** i) % 10; 
        end
    end
endfunction