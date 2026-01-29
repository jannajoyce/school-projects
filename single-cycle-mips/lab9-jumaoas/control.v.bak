/*
  Description:
    Main control unit for a single-cycle MIPS processor. Decodes instruction
    opcodes and function codes to generate control signals for the datapath.
    Implements a subset of MIPS instructions including R-type arithmetic/logic
    operations and I-type memory/immediate operations.
  
  Supported Instructions:
    R-Type (opcode 000000):
      - ADD  (funct 100000): Add
      - SUB  (funct 100010): Subtract
      - AND  (funct 100100): Bitwise AND
      - OR   (funct 100101): Bitwise OR
      - XOR  (funct 100110): Bitwise XOR
      - NOR  (funct 100111): Bitwise NOR
    
    I-Type:
      - LW   (opcode 100011): Load Word
      - SW   (opcode 101011): Store Word
      - ADDI (opcode 001000): Add Immediate
  
  Inputs:
    instruction[31:0] - 32-bit instruction to decode
  
  Outputs:
    RegDst      - Register destination select (0=rt, 1=rd)
    ALUSrc      - ALU source select (0=register, 1=immediate)
    MemToReg    - Memory to register select (0=ALU result, 1=memory data)
    RegWrite    - Register write enable (1=write to register file)
    MemRead     - Memory read enable (1=read from data memory)
    MemWrite    - Memory write enable (1=write to data memory)
    ALUOp[5:0]  - ALU operation code (passed to ALU)
  
  Control Signal Truth Table:
  ┌─────────┬────────┬────────┬──────────┬──────────┬─────────┬──────────┬─────────┐
  │ Instr   │ RegDst │ ALUSrc │ MemToReg │ RegWrite │ MemRead │ MemWrite │ ALUOp   │
  ├─────────┼────────┼────────┼──────────┼──────────┼─────────┼──────────┼─────────┤
  │ R-Type  │   1    │   0    │    0     │    1     │    0    │    0     │ funct   │
  │ LW      │   0    │   1    │    1     │    1     │    1    │    0     │ ADD     │
  │ SW      │   X    │   1    │    X     │    0     │    0    │    1     │ ADD     │
  │ ADDI    │   0    │   1    │    0     │    1     │    0    │    0     │ ADD     │
  └─────────┴────────┴────────┴──────────┴──────────┴─────────┴──────────┴─────────┘
  
  Note: X indicates "don't care" values
 */

`timescale 1ns / 1ps

module control (
    input [31:0] instruction,   // Complete instruction word
    output reg RegDst,          // 0: rt (I-type), 1: rd (R-type)
    output reg ALUSrc,          // 0: Read data 2, 1: Sign-extended immediate
    output reg MemToReg,        // 0: ALU result, 1: Memory data
    output reg RegWrite,        // 1: Enable register write
    output reg MemRead,         // 1: Enable memory read
    output reg MemWrite,        // 1: Enable memory write
    output reg [5:0] ALUOp      // ALU operation selector
);

    // Instruction Field Extraction
     
    wire [5:0] opcode = instruction[31:26];  // Instruction opcode (bits 31-26)
    wire [5:0] funct  = instruction[5:0];    // Function code for R-type (bits 5-0)

    // Opcode Definitions (I-Type Instructions)
    
    localparam OP_RTYPE = 6'b000000;  // R-type instructions
    localparam OP_LW    = 6'b100011;  // Load Word
    localparam OP_SW    = 6'b101011;  // Store Word
    localparam OP_ADDI  = 6'b001000;  // Add Immediate

    // Function Code Definitions (R-Type Instructions)

    localparam FUNC_ADD = 6'b100000;  // Add
    localparam FUNC_SUB = 6'b100010;  // Subtract
    localparam FUNC_AND = 6'b100100;  // Bitwise AND
    localparam FUNC_OR  = 6'b100101;  // Bitwise OR
    localparam FUNC_NOR = 6'b100111;  // Bitwise NOR
    localparam FUNC_XOR = 6'b100110;  // Bitwise XOR

    // Control Signal Generation (Combinational Logic)

    always @(*) begin
        // Default values: All control signals off
        RegDst   = 0;
        ALUSrc   = 0;
        MemToReg = 0;
        RegWrite = 0;
        MemRead  = 0;
        MemWrite = 0;
        ALUOp    = 6'b000000;

        case (opcode)
            /* 
              LW (Load Word): I-type instruction
              Format: LW rt, offset(rs)
              Operation: rt = Memory[rs + offset]
           */
            OP_LW: begin
                RegDst   = 0;  // Write to rt (instruction[20:16])
                ALUSrc   = 1;  // Use immediate (offset)
                MemToReg = 1;  // Write memory data to register
                RegWrite = 1;  // Enable register write
                MemRead  = 1;  // Enable memory read
                MemWrite = 0;  // Disable memory write
                ALUOp    = FUNC_ADD;  // ALU performs address calculation (rs + offset)
            end

            /*
              SW (Store Word): I-type instruction
              Format: SW rt, offset(rs)
              Operation: Memory[rs + offset] = rt
            */
            OP_SW: begin
                RegDst   = 1'bx;  // Don't care (no register write)
                ALUSrc   = 1;     // Use immediate (offset)
                MemToReg = 1'bx;  // Don't care (no register write)
                RegWrite = 0;     // Disable register write
                MemRead  = 0;     // Disable memory read
                MemWrite = 1;     // Enable memory write
                ALUOp    = FUNC_ADD;  // ALU performs address calculation (rs + offset)
            end

            /* 
              ADDI (Add Immediate): I-type instruction
              Format: ADDI rt, rs, immediate
              Operation: rt = rs + immediate
           */
            OP_ADDI: begin
                RegDst   = 0;  // Write to rt (instruction[20:16])
                ALUSrc   = 1;  // Use sign-extended immediate
                MemToReg = 0;  // Write ALU result to register
                RegWrite = 1;  // Enable register write
                MemRead  = 0;  // Disable memory read
                MemWrite = 0;  // Disable memory write
                ALUOp    = FUNC_ADD;  // ALU performs addition
            end

            /* 
              R-Type Instructions
              Format: FUNC rd, rs, rt (most common format)
              Operation: rd = rs FUNC rt
            */
            OP_RTYPE: begin
                RegDst   = 1;  // Write to rd (instruction[15:11])
                ALUSrc   = 0;  // Use register rt value
                MemToReg = 0;  // Write ALU result to register
                RegWrite = 1;  // Enable register write
                MemRead  = 0;  // Disable memory read
                MemWrite = 0;  // Disable memory write

                // Decode function field for specific R-type operation
                case (funct)
                    FUNC_ADD: ALUOp = FUNC_ADD;  // ADD: rd = rs + rt
                    FUNC_SUB: ALUOp = FUNC_SUB;  // SUB: rd = rs - rt
                    FUNC_AND: ALUOp = FUNC_AND;  // AND: rd = rs & rt
                    FUNC_OR : ALUOp = FUNC_OR;   // OR:  rd = rs | rt
                    FUNC_NOR: ALUOp = FUNC_NOR;  // NOR: rd = ~(rs | rt)
                    FUNC_XOR: ALUOp = FUNC_XOR;  // XOR: rd = rs ^ rt
                    default : ALUOp = 6'b000000; // Unknown function
                endcase
            end

            /*
              Default Case: Unrecognized Opcode
              All control signals remain at default (off) values
            */
            default: begin
                ALUOp = 6'b000000;
            end
        endcase
    end

endmodule