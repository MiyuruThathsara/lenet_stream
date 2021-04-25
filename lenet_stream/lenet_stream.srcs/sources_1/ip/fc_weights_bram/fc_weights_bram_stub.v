// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Sat Apr 17 19:34:51 2021
// Host        : DESKTOP-QFCM39A running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub {d:/Vivado/Vivado_Projects/Verilog
//               Projects/lenet_stream/lenet_stream.srcs/sources_1/ip/fc_weights_bram/fc_weights_bram_stub.v}
// Design      : fc_weights_bram
// Purpose     : Stub declaration of top-level module interface
// Device      : xczu9eg-ffvb1156-2-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2019.2" *)
module fc_weights_bram(clka, ena, wea, addra, dina, douta)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,wea[0:0],addra[6:0],dina[1343:0],douta[1343:0]" */;
  input clka;
  input ena;
  input [0:0]wea;
  input [6:0]addra;
  input [1343:0]dina;
  output [1343:0]douta;
endmodule
