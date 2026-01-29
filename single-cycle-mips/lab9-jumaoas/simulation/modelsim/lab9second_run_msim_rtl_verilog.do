transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as/sign_extender.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as/serial_buffer.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as/reg_file.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as/program_counter.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as/processor.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as/mux2.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as/inst_rom.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as/data_memory.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as/control.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as/async_memory.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as/alu.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as/adder.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as/load_extender.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as/shift_left_2.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as/mux4.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/Lab9-Jumao-as/zero_extender.v}

