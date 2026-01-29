transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as/sign_extender.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as/serial_buffer.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as/reg_file.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as/program_counter.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as/processor.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as/mux2.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as/inst_rom.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as/data_memory.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as/async_memory.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as/alu.v}
vlog -vlog01compat -work work +incdir+C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as {C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as/adder.v}

