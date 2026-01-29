/*
 Description:
    Top-level module for a single-cycle MIPS processor implementation.
    Integrates the datapath components (PC, instruction memory, register file,
    ALU, data memory) to execute instructions.
  
    NOTE: The control unit is currently commented out, so control signals
    (RegDst, ALUSrc, MemToReg, RegWrite, MemRead, MemWrite) are not driven.
    Multiplexer select lines are also left unconnected.
  
  Inputs:
    clock              - System clock
    reset              - Asynchronous reset (active high)
    serial_in[7:0]     - Serial input data (for memory-mapped I/O)
    serial_valid_in    - Serial data valid flag
    serial_ready_in    - Serial interface ready flag
  
  Outputs:
    serial_out[7:0]    - Serial output data
    serial_rden_out    - Serial read enable
    serial_wren_out    - Serial write enable
    pc_out[31:0]       - Current program counter value
    instruction_out[31:0] - Current instruction being executed
    alu_a_out[31:0]    - ALU input A (from register file)
    alu_b_out[31:0]    - ALU input B (register or immediate)
    alu_out_output[31:0] - ALU computation result
  
  Datapath Flow:
    1. PC provides instruction address
    2. Instruction memory fetches instruction
    3. Control unit decodes instruction (currently disabled)
    4. Register file reads source registers
    5. ALU performs operation
    6. Data memory performs load/store if needed
    7. Result written back to register file
    8. PC incremented by 4
 */

`timescale 1ns / 1ps

module processor (
    input clock,
    input reset,
    input [7:0] serial_in,          // Serial input
    input serial_valid_in,          // Serial valid flag
    input serial_ready_in,          // Serial ready flag
    output [7:0] serial_out,        // Serial output
    output serial_rden_out,         // Serial read enable
    output serial_wren_out,         // Serial write enable
    output [31:0] pc_out,           // Program Counter output
    output [31:0] instruction_out,  // Fetched instruction
    output [31:0] alu_a_out,        // ALU input A
    output [31:0] alu_b_out,        // ALU input B
    output [31:0] alu_out_output    // ALU result
);
	
    
    // Internal Wires
    
    wire [31:0] pc_next;         // Next PC value (PC + 4)
    wire [31:0] alu_out;         // ALU result
    wire [31:0] read_data1;      // Register file output 1 (rs)
    wire [31:0] read_data2;      // Register file output 2 (rt)
    wire [31:0] mem_data_out;    // Data memory read output
    wire [31:0] sign_ext_imm;    // Sign-extended immediate value
    wire [31:0] alu_b_in;        // ALU second operand
    wire [31:0] write_data;      // Data to write to register file
    wire [5:0] opcode;           // Instruction opcode (currently unused)
    wire [5:0] funct;            // Function field (currently unused)
    wire [5:0] alu_op;           // ALU operation code
    
    // Control signals (currently unused - control unit commented out)
    wire RegDst, ALUSrc, MemToReg, RegWrite, MemRead, MemWrite;

    // Serial interface wires
    wire [7:0] serial_out_wire;
    wire serial_wren_out_wire;
    wire serial_rden_out_wire;

    // FETCH STAGE
     

    // Adder: Calculate PC + 4 for next instruction
    adder PCAdder (
        .a(pc_out),
        .b(32'd4),
        .sum(pc_next)
    );
	 
    // Program Counter: Holds current instruction address
    program_counter PC(
        .clock(clock),
        .reset(reset),
        .pc_in(pc_next),   // Next PC value from PCAdder
        .pc_out(pc_out)    // Current PC value
    );

    // Instruction Memory: Fetches instruction at PC address
    inst_rom InstructionMemory (
        .clock(clock),
        .reset(reset),
        .addr_in(pc_out),
        .data_out(instruction_out)
    );
	 
    // DECODE STAGE
    
	 
    wire [4:0] write_reg_mux_out;
	 
    // Multiplexer: Select write register (rd or rt)
    // Note: select signal is unconnected - requires control unit
    mux2 #(5) RegDst_Mux (
        .b(instruction_out[20:16]), // rt field
        .a(instruction_out[15:11]), // rd field
        .select(),                  // TODO: Connect to RegDst control signal
        .out(write_reg_mux_out)
    );

    // Register File: 32 general-purpose registers
    reg_file RegFile (
        .clock(clock),
        .reset(reset),
        .reg_write_en(RegWrite),                // Write enable (undriven)
        .read_reg1(instruction_out[25:21]),     // rs field
        .read_reg2(instruction_out[20:16]),     // rt field
        .write_reg(write_reg_mux_out),          // Destination register
        .write_data(write_data),                // Data to write
        .read_data1(read_data1),                // Output: rs value
        .read_data2(read_data2)                 // Output: rt value
    );

    // EXECUTE STAGE

    // Sign Extender: Extends 16-bit immediate to 32 bits
    sign_extender SignExt (
        .in(instruction_out[15:0]),
        .out(sign_ext_imm)
    );
	 
    wire [31:0] alu_b_mux_out;
	 
    // Multiplexer: Select ALU second operand (register or immediate)
    // Note: select signal is unconnected - requires control unit
    mux2 #(32) ALUSrc_Mux (
        .b(read_data2),      // Register value (rt)
        .a(sign_ext_imm),    // Immediate value
        .select(),           // TODO: Connect to ALUSrc control signal
        .out(alu_b_mux_out)
    );

    // ALU: Performs arithmetic and logical operations
    alu ALU (
        .Func_in(alu_op),         // Operation selector (undriven)
        .A_in(read_data1),        // First operand (rs)
        .B_in(alu_b_mux_out),     // Second operand (rt or immediate)
        .O_out(alu_out),          // Result
        .Branch_out(),            // Branch condition (unused)
        .Jump_out()               // Jump flag (unused)
    );

    // MEMORY STAGE
	 
    // Data Memory: Handles load/store operations and memory-mapped I/O
    data_memory DataMem (
        .clock(clock),
        .reset(reset),
        .addr_in(alu_out),                  // Memory address from ALU
        .writedata_in(read_data2),          // Data to write (from rt)
        .re_in(MemRead),                    // Read enable (undriven)
        .we_in(MemWrite),                   // Write enable (undriven)
        .size_in(2'b11),                    // Word size (fixed at word)
        .readdata_out(mem_data_out),        // Data read from memory
        .serial_in(serial_in),              // Serial I/O interface
        .serial_ready_in(serial_ready_in),
        .serial_valid_in(serial_valid_in),
        .serial_out(serial_out_wire),
        .serial_rden_out(serial_rden_out_wire),
        .serial_wren_out(serial_wren_out_wire)
    );
	 
    // WRITEBACK STAGE
     
    wire [31:0] write_data_mux_out;
	 
    // Multiplexer: Select data to write back (ALU result or memory data)
    // Note: select signal is unconnected - requires control unit
    mux2 #(32) MemToReg_Mux (
        .b(alu_out),         // ALU result
        .a(mem_data_out),    // Memory data
        .select(),           // TODO: Connect to MemToReg control signal
        .out(write_data_mux_out)
    );

    // OUTPUT ASSIGNMENTS
  
    assign serial_out = serial_out_wire;
    assign serial_rden_out = serial_rden_out_wire;
    assign serial_wren_out = serial_wren_out_wire;
    assign alu_a_out = read_data1;
    assign alu_b_out = alu_b_mux_out;
    assign alu_out_output = alu_out;
    assign write_data = write_data_mux_out;

endmodule