`timescale 1ns / 1ps

/*

  Description:
    Top-level module implementing a single-cycle MIPS processor with
    extended instruction support. This processor executes each instruction
    in a single clock cycle, with separate instruction and data memories.

  Supported Instructions:
    - R-type: ADD, ADDU, SUB, SUBU, AND, OR, XOR, NOR, SLT, SLTU
    - Shifts: SLL, SRL, SRA
    - I-type: ADDI, ADDIU, SLTI, SLTIU, ANDI, ORI, XORI, LUI
    - Loads: LW, LH, LB, LHU, LBU
    - Stores: SW, SH, SB
    - Branches: BEQ, BNE, BLEZ, BGTZ, BLTZ, BGEZ
    - Jumps: J, JAL, JR, JALR

  Architecture:
    Five-stage datapath (executed in one cycle):
    1. Fetch: PC → Instruction Memory
    2. Decode: Control Unit + Register File
    3. Execute: ALU operations
    4. Memory: Data Memory access
    5. Writeback: Write to Register File

  Inputs:
    clock            - System clock
    reset            - Asynchronous reset (active high)
    serial_in[7:0]   - Serial port input data
    serial_valid_in  - Serial input data valid
    serial_ready_in  - Serial port ready for output

  Outputs:
    serial_out[7:0]   - Serial port output data
    serial_rden_out   - Serial read enable
    serial_wren_out   - Serial write enable
    pc_out[31:0]      - Current program counter (for debugging)
    instruction_out[31:0] - Current instruction (for debugging)
    alu_a_out[31:0]   - ALU input A (for debugging)
    alu_b_out[31:0]   - ALU input B (for debugging)
    alu_out_output[31:0] - ALU result (for debugging)

  Memory Map:
    0x00400000 - Instruction memory (ROM)
    0x10000000 - Data memory (4KB)
    0x7FFF0000 - Stack memory (4KB)
    0xFFFF0000 - Serial I/O port
*/

module processor (
    input clock,
    input reset,
    input [7:0] serial_in,
    input serial_valid_in,
    input serial_ready_in,
    output [7:0] serial_out,
    output serial_rden_out,
    output serial_wren_out,
    output [31:0] pc_out,
    output [31:0] instruction_out,
    output [31:0] alu_a_out,
    output [31:0] alu_b_out,
    output [31:0] alu_out_output
);

    // WIRE DECLARATIONS
    
    // PC and branch/jump control wires
    wire [31:0] pc_plus4;               // PC + 4 (next sequential instruction)
    wire [31:0] branch_offset_shifted;  // Branch offset << 2
    wire [31:0] branch_target;          // Branch target address
    wire [31:0] jump_target;            // Jump target address
    wire [1:0] pc_src;                  // PC source selector
    wire [31:0] next_pc;                // Next PC value
    wire branch_taken;                  // Branch condition met
    
    // Control signals from control unit
    wire [1:0] RegDst;      // Register destination selector
    wire ALUSrc;            // ALU source B selector
    wire [1:0] MemToReg;    // Write data source selector
    wire RegWrite;          // Register write enable
    wire MemRead;           // Memory read enable
    wire MemWrite;          // Memory write enable
    wire [5:0] ALUOp;       // ALU operation code
    wire Branch;            // Branch instruction flag
    wire Jump;              // Jump instruction flag
    wire JumpReg;           // Register jump flag
    wire ZeroExtend;        // Extension type (0=sign, 1=zero)
    wire LUI;               // Load upper immediate flag
    wire [1:0] MemSize;     // Memory access size
    wire [1:0] LoadType;    // Load extension type
    wire LoadExtend;        // Use load extender
    wire ALUShift;          // Use shamt for ALU input A
    
    // Register file wires
    wire [4:0] write_reg;           // Destination register address
    wire [31:0] read_data1;         // Register rs data
    wire [31:0] read_data2;         // Register rt data
    wire [31:0] write_data;         // Data to write to register
    
    // Extension and immediate wires
    wire [31:0] sign_extended;      // Sign-extended immediate
    wire [31:0] zero_extended;      // Zero-extended immediate
    wire [31:0] extended_immediate; // Selected extended immediate
    wire [31:0] lui_shifted;        // LUI shifted immediate (imm << 16)
    wire [31:0] final_immediate;    // Final immediate value
    wire [31:0] shamt_extended;     // Zero-extended shift amount
    
    // ALU wires
    wire [31:0] alu_input_a;        // ALU input A (rs or shamt)
    wire [31:0] alu_input_b;        // ALU input B (rt or immediate)
    wire [31:0] alu_result;         // ALU computation result
    wire alu_branch_signal;         // Branch condition from ALU
    wire alu_jump_signal;           // Jump signal from ALU
    
    // Memory wires
    wire [31:0] mem_read_data;      // Raw data from memory
    wire [31:0] load_extended_data; // Extended load data (for LB/LH/LBU/LHU)
    wire [31:0] final_mem_data;     // Final memory data to register
    
    // Serial port wires
    wire [7:0] serial_out_wire;
    wire serial_wren_out_wire;
    wire serial_rden_out_wire;

    // STAGE 1: INSTRUCTION FETCH
    
    // PC Adder: Calculate next sequential address (PC + 4)
    adder PCAdder (
        .a(pc_out),
        .b(32'd4),
        .sum(pc_plus4)
    );
    
    // Branch Target Calculation
    // Shift sign-extended offset left by 2 bits (word-aligned addresses)
    shift_left_2 #(.WIDTH(32)) branch_shift (
        .in(sign_extended),
        .out(branch_offset_shifted)
    );
    
    // Add shifted offset to PC+4 to get branch target
    adder branch_adder (
        .a(pc_plus4),
        .b(branch_offset_shifted),
        .sum(branch_target)
    );
    
    // Jump Target Address Calculation
    // Jump address = {PC+4[31:28], instruction[25:0], 2'b00}
    assign jump_target = {pc_plus4[31:28], instruction_out[25:0], 2'b00};
    
    // PC Source Selection Logic
    // Determine next PC based on instruction type
    assign branch_taken = Branch & alu_branch_signal;  // Branch if condition met
    assign pc_src = JumpReg      ? 2'b11 :  // JR/JALR: use register value
                    Jump         ? 2'b10 :  // J/JAL: use jump target
                    branch_taken ? 2'b01 :  // Branch: use branch target
                                   2'b00;   // Default: PC + 4
    
    // PC Source Multiplexer (4-to-1)
    mux4 #(.WIDTH(32)) pc_mux (
        .a(pc_plus4),       // Normal: PC + 4
        .b(branch_target),  // Branch target
        .c(jump_target),    // Jump target
        .d(read_data1),     // Register jump (JR/JALR uses rs)
        .sel(pc_src),
        .out(next_pc)
    );
    
    // Program Counter Register
    program_counter PC (
        .clock(clock),
        .reset(reset),
        .pc_in(next_pc),
        .pc_out(pc_out)
    );
    
    // Instruction Memory (ROM)
    inst_rom InstructionMemory (
        .clock(clock),
        .reset(reset),
        .addr_in(pc_out),
        .data_out(instruction_out)
    );

    // STAGE 2: INSTRUCTION DECODE & REGISTER READ
    
    // Control Unit - Generates all control signals
    control Control (
        .instruction(instruction_out),
        .RegDst(RegDst),
        .ALUSrc(ALUSrc),
        .MemToReg(MemToReg),
        .RegWrite(RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .ALUOp(ALUOp),
        .Branch(Branch),
        .Jump(Jump),
        .JumpReg(JumpReg),
        .ZeroExtend(ZeroExtend),
        .LUI(LUI),
        .MemSize(MemSize),
        .LoadType(LoadType),
        .LoadExtend(LoadExtend),
        .ALUShift(ALUShift)
    );
    
    // Write Register Selection (3-way mux using two 2-to-1 muxes)
    // First mux: select between rt (I-type) and rd (R-type)
    wire [4:0] write_reg_rd_or_rt;
    
    mux2 #(.WIDTH(5)) write_reg_mux_rt_rd (
        .a(instruction_out[15:11]),         // rd - R-type destination
        .b(instruction_out[20:16]),         // rt - I-type destination
        .sel(RegDst[0]),         // 0=rt, 1=rd
        .out(write_reg_rd_or_rt)
    );
    
    // Second mux: select between rd/rt and $ra (register 31)
    mux2 #(.WIDTH(5)) write_reg_mux_ra (
        .a(5'd31),               // $ra - for JAL/JALR
        .b(write_reg_rd_or_rt),  // rd or rt
        .sel(RegDst[1]),         // 0=rd/rt, 1=$ra
        .out(write_reg)
    );
    
    // Register File (32 registers, dual read ports, single write port)
    reg_file RegFile (
        .clock(clock),
        .reset(reset),
        .reg_write_en(RegWrite),
        .read_reg1(instruction_out[25:21]),  // rs
        .read_reg2(instruction_out[20:16]),  // rt
        .write_reg(write_reg),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // STAGE 3: EXECUTE (ALU Operation)
    
    // Sign Extension (for I-type immediates)
    sign_extender SignExt (
        .in(instruction_out[15:0]),
        .out(sign_extended)
    );
    
    // Zero Extension (for logical immediates and unsigned operations)
    zero_extender #(.IN_WIDTH(16), .OUT_WIDTH(32)) ZeroExt (
        .in(instruction_out[15:0]),
        .out(zero_extended)
    );
    
    // Extension Type Selection
    // Select between sign extension and zero extension based on control signal
    mux2 #(.WIDTH(32)) extend_mux (
        .a(zero_extended),       // Zero extend (for ANDI, ORI, XORI)
        .b(sign_extended),       // Sign extend (for ADDI, LW, SW, etc.)
        .sel(ZeroExtend),        // Control selects extension type
        .out(extended_immediate)
    );
    
    // LUI: Load Upper Immediate (shift immediate left by 16 bits)
    assign lui_shifted = {instruction_out[15:0], 16'b0};
    
    // LUI Selection
    mux2 #(.WIDTH(32)) lui_mux (
        .a(lui_shifted),          // LUI: immediate << 16
        .b(extended_immediate),   // Normal immediate
        .sel(LUI),
        .out(final_immediate)
    );
    
    // Shift Amount Extension (for shift instructions: SLL, SRL, SRA)
    // Extend 5-bit shamt to 32 bits
    assign shamt_extended = {27'b0, instruction_out[10:6]};
    
    // ALU Input A Selection
    // For shift instructions, use shamt; for others, use register rs
    mux2 #(.WIDTH(32)) alu_a_mux (
        .a(shamt_extended),       // Shift amount (for SLL/SRL/SRA)
        .b(read_data1),           // Register rs
        .sel(ALUShift),           // Control selects source
        .out(alu_input_a)
    );
    
    // ALU Input B Selection
    // Select between register rt and immediate value
    mux2 #(.WIDTH(32)) alu_b_mux (
        .a(final_immediate),      // Immediate value
        .b(read_data2),           // Register rt
        .sel(ALUSrc),             // 0=register, 1=immediate
        .out(alu_input_b)
    );
    
    // ALU (Arithmetic Logic Unit)
    // Performs all computational operations
    alu ALU (
        .Func_in(ALUOp),
        .A_in(alu_input_a),
        .B_in(alu_input_b),
        .O_out(alu_result),
        .Branch_out(alu_branch_signal),  // Branch condition result
        .Jump_out(alu_jump_signal)       // Jump signal (unused in current design)
    );

    // STAGE 4: MEMORY ACCESS
    
    // Data Memory
    // Handles loads, stores, and serial I/O
    data_memory DataMem (
        .clock(clock),
        .reset(reset),
        .addr_in(alu_result),        // Address from ALU (base + offset)
        .writedata_in(read_data2),   // Data to write (from rt)
        .re_in(MemRead),
        .we_in(MemWrite),
        .size_in(MemSize),           // Byte, halfword, or word access
        .readdata_out(mem_read_data),
        .serial_in(serial_in),
        .serial_ready_in(serial_ready_in),
        .serial_valid_in(serial_valid_in),
        .serial_out(serial_out_wire),
        .serial_rden_out(serial_rden_out_wire),
        .serial_wren_out(serial_wren_out_wire)
    );
    
    // Load Extender
    // Handles byte and halfword loads with sign/zero extension
    // (LB, LH, LBU, LHU)
    load_extender LoadExt (
        .mem_data(mem_read_data),
        .byte_offset(alu_result[1:0]),  // Lower 2 bits select byte/half
        .load_type(LoadType),            // Determines extension type
        .extended_data(load_extended_data)
    );
    
    // Load Extension Selection
    // For LW: use direct memory data
    // For LB/LH/LBU/LHU: use extended data
    mux2 #(.WIDTH(32)) load_select_mux (
        .a(load_extended_data),   // Extended byte/halfword
        .b(mem_read_data),        // Direct word from memory
        .sel(LoadExtend),         // Control selects source
        .out(final_mem_data)
    );

    // STAGE 5: WRITEBACK
    
    // Writeback Data Selection (3-way mux using two 2-to-1 muxes)
    // First mux: select between ALU result and memory data
    wire [31:0] write_data_alu_or_mem;
    
    mux2 #(.WIDTH(32)) mem_to_reg_mux (
        .a(final_mem_data),       // Memory data (loads)
        .b(alu_result),           // ALU result (arithmetic/logic)
        .sel(MemToReg[0]),        // 0=ALU, 1=memory
        .out(write_data_alu_or_mem)
    );
    
    // Second mux: select between ALU/memory and PC+4
    mux2 #(.WIDTH(32)) pc_to_reg_mux (
        .a(pc_plus4),              // PC+4 (for JAL/JALR return address)
        .b(write_data_alu_or_mem), // ALU result or memory data
        .sel(MemToReg[1]),         // 0=ALU/mem, 1=PC+4
        .out(write_data)
    );

    // OUTPUT ASSIGNMENTS
    
    assign serial_out = serial_out_wire;
    assign serial_rden_out = serial_rden_out_wire;
    assign serial_wren_out = serial_wren_out_wire;
    assign alu_a_out = alu_input_a;
    assign alu_b_out = alu_input_b;
    assign alu_out_output = alu_result;

endmodule