-- Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
-- Date        : Wed Apr  7 20:13:17 2021
-- Host        : DESKTOP-QFCM39A running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub {d:/Vivado/Vivado_Projects/Verilog
--               Projects/lenet_stream/lenet_stream.srcs/sources_1/ip/weights_kernel/weights_kernel_stub.vhdl}
-- Design      : weights_kernel
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xczu9eg-ffvb1156-2-e
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity weights_kernel is
  Port ( 
    clka : in STD_LOGIC;
    ena : in STD_LOGIC;
    wea : in STD_LOGIC_VECTOR ( 0 to 0 );
    addra : in STD_LOGIC_VECTOR ( 1 downto 0 );
    dina : in STD_LOGIC_VECTOR ( 399 downto 0 );
    douta : out STD_LOGIC_VECTOR ( 399 downto 0 )
  );

end weights_kernel;

architecture stub of weights_kernel is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clka,ena,wea[0:0],addra[1:0],dina[399:0],douta[399:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "blk_mem_gen_v8_4_4,Vivado 2019.2";
begin
end;
