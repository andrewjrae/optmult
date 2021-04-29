source size.tcl
vlib work
vlog -sv optmult.sv mult_tb.sv
vlog counter.v LUT6_2.v MUXCY.v XORCY.v pipe_reg.v
# vsim -novopt -GM=$M -GN=$N dut_tb
vsim mult_tb
# log -r /*
# add wave sim:/dut_tb/systolic_dut/*
# config wave -signalnamewidth 1
run 10250 ns
