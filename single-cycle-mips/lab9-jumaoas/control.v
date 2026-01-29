/*
  Description:
    Main control unit for a single-cycle MIPS processor. Decodes instruction
    opcodes and function codes to generate control signals for the datapath.
    This is an EXTENDED control unit that supports a comprehensive subset of
    MIPS instructions including R-type, I-type, loads/stores, branches, and jumps.
  
  Supported Instructions:
    R-Type (opcode 000000):
      - Arithmetic: ADD, ADDU, SUB, SUBU
      - Logical: AND, OR, XOR, NOR
      - Comparison: SLT, SLTU
      - Shifts: SLL, SRL, SRA
      - Jumps: JR, JALR
    
    I-Type Arithmetic/Logical:
      - ADDI, ADDIU - Add immediate (signed/unsigned)
      - SLTI, SLTIU - Set less than immediate
      - ANDI, ORI, XORI - Bitwise operations with immediate
      - LUI - Load upper immediate
    
    Load Instructions:
      - LW  - Load word
      - LH  - Load halfword (signed)
      - LB  - Load byte (signed)
      - LHU - Load halfword unsigned
      - LBU - Load byte unsigned
    
    Store Instructions:
      - SW - Store word
      - SH - Store halfword
      - SB - Store byte
    
    Branch Instructions:
      - BEQ  - Branch if equal
      - BNE  - Branch if not equal
      - BLEZ - Branch if less than or equal to zero
      - BGTZ - Branch if greater than zero
      - BLTZ - Branch if less than zero (REGIMM opcode)
      - BGEZ - Branch if greater than or equal to zero (REGIMM opcode)
    
    Jump Instructions:
      - J   - Jump
      - JAL - Jump and link
  
  Inputs:
    instruction[31:0] - 32-bit instruction to decode
  
  Outputs:
    RegDst[1:0]  - Register destination select (00=rt, 01=rd, 10=$ra/r31)
    ALUSrc       - ALU source select (0=register, 1=immediate)
    MemToReg[1:0]- Memory to register select (00=ALU, 01=memory, 10=PC+4)
    RegWrite     - Register write enable (1=write to register file)
    MemRead      - Memory read enable (1=read from data memory)
    MemWrite     - Memory write enable (1=write to data memory)
    ALUOp[5:0]   - ALU operation code (passed to ALU)
    Branch       - Branch instruction flag
    Jump         - Jump instruction flag (J, JAL)
    JumpReg      - Register jump flag (JR, JALR)
    ZeroExtend   - Extension type (0=sign extend, 1=zero extend)
    LUI          - Load upper immediate flag
    MemSize[1:0] - Memory access size (00=byte, 01=half, 11=word)
    LoadType[1:0]- Load extension type (00=LB, 01=LH, 10=LBU, 11=LHU)
    LoadExtend   - Use load extender (1=extend byte/half to word)
    ALUShift     - Use shift amount for ALU input A (1=shamt, 0=register)
  
  Control Signal Summary:
  ┌─────────┬────────┬────────┬──────────┬──────────┬─────────┬──────────┬────────────┐
  │ Instr   │ RegDst │ ALUSrc │ MemToReg │ RegWrite │ MemRead │ MemWrite │ ALUOp      │
  ├─────────┼────────┼────────┼──────────┼──────────┼─────────┼──────────┼────────────┤
  │ R-Type  │   01   │   0    │    00    │    1     │    0    │    0     │ funct      │
  │ ADDI    │   00   │   1    │    00    │    1     │    0    │    0     │ ADD        │
  │ LW      │   00   │   1    │    01    │    1     │    1    │    0     │ ADD        │
  │ SW      │   XX   │   1    │    XX    │    0     │    0    │    1     │ ADD        │
  │ BEQ     │   XX   │   0    │    XX    │    0     │    0    │    0     │ BEQ        │
  │ J       │   XX   │   X    │    XX    │    0     │    0    │    0     │ J          │
  │ JAL     │   10   │   X    │    10    │    1     │    0    │    0     │ J          │
  └─────────┴────────┴────────┴──────────┴──────────┴─────────┴──────────┴────────────┘
  
  Note: X indicates "don't care" values
 */

`timescale 1ns / 1ps

module control (
    input [31:0] instruction,   // Complete instruction word
    output reg [1:0] RegDst,    // 00: rt, 01: rd, 10: $ra (reg 31)
    output reg ALUSrc,          // 0: Read data 2, 1: Sign-extended immediate
    output reg [1:0] MemToReg,  // 00: ALU result, 01: Memory data, 10: PC+4
    output reg RegWrite,        // 1: Enable register write
    output reg MemRead,         // 1: Enable memory read
    output reg MemWrite,        // 1: Enable memory write
    output reg [5:0] ALUOp,     // ALU operation selector
    output reg Branch,          // Branch instruction
    output reg Jump,            // J or JAL instruction
    output reg JumpReg,         // JR or JALR instruction
    output reg ZeroExtend,      // 0=sign extend, 1=zero extend
    output reg LUI,             // Load upper immediate
    output reg [1:0] MemSize,   // 00=byte, 01=half, 11=word
    output reg [1:0] LoadType,  // 00=LB, 01=LH, 10=LBU, 11=LHU
    output reg LoadExtend,      // 1=use load extender
    output reg ALUShift         // 1=use shamt for ALU input A
);

    // Instruction Field Extraction
    wire [5:0] opcode = instruction[31:26];
    wire [5:0] funct  = instruction[5:0];
    wire [4:0] rt     = instruction[20:16];

    // Opcode Definitions
    localparam OP_RTYPE  = 6'b000000;
    localparam OP_ADDI   = 6'b001000;
    localparam OP_ADDIU  = 6'b001001;
    localparam OP_SLTI   = 6'b001010;
    localparam OP_SLTIU  = 6'b001011;
    localparam OP_ANDI   = 6'b001100;
    localparam OP_ORI    = 6'b001101;
    localparam OP_XORI   = 6'b001110;
    localparam OP_LUI    = 6'b001111;
    localparam OP_LB     = 6'b100000;
    localparam OP_LH     = 6'b100001;
    localparam OP_LW     = 6'b100011;
    localparam OP_LBU    = 6'b100100;
    localparam OP_LHU    = 6'b100101;
    localparam OP_SB     = 6'b101000;
    localparam OP_SH     = 6'b101001;
    localparam OP_SW     = 6'b101011;
    localparam OP_BEQ    = 6'b000100;
    localparam OP_BNE    = 6'b000101;
    localparam OP_BLEZ   = 6'b000110;
    localparam OP_BGTZ   = 6'b000111;
    localparam OP_REGIMM = 6'b000001;
    localparam OP_J      = 6'b000010;
    localparam OP_JAL    = 6'b000011;

    // Function Codes (for R-type instructions)
    localparam FUNCT_SLL  = 6'b000000;
    localparam FUNCT_SRL  = 6'b000010;
    localparam FUNCT_SRA  = 6'b000011;
    localparam FUNCT_JR   = 6'b001000;
    localparam FUNCT_JALR = 6'b001001;
    localparam FUNCT_ADD  = 6'b100000;
    localparam FUNCT_ADDU = 6'b100001;
    localparam FUNCT_SUB  = 6'b100010;
    localparam FUNCT_SUBU = 6'b100011;
    localparam FUNCT_AND  = 6'b100100;
    localparam FUNCT_OR   = 6'b100101;
    localparam FUNCT_XOR  = 6'b100110;
    localparam FUNCT_NOR  = 6'b100111;
    localparam FUNCT_SLT  = 6'b101010;
    localparam FUNCT_SLTU = 6'b101011;

    // ALU Operation Codes (sent to ALU module)
//    localparam ALU_ADD   = 6'b100000;
//    localparam ALU_ADDU  = 6'b100001;
//    localparam ALU_SUB   = 6'b100010;
//    localparam ALU_SUBU  = 6'b100011;
//    localparam ALU_AND   = 6'b100100;
//    localparam ALU_OR    = 6'b100101;
//    localparam ALU_XOR   = 6'b100110;
//    localparam ALU_NOR   = 6'b100111;
//    localparam ALU_SLT   = 6'b101010;
//    localparam ALU_SLTU  = 6'b101011;
//    localparam ALU_BLTZ  = 6'b111000;
//    localparam ALU_BGEZ  = 6'b111001;
//    localparam ALU_J     = 6'b111010;
//    localparam ALU_JR    = 6'b111011;
//    localparam ALU_BEQ   = 6'b111100;
//    localparam ALU_BNE   = 6'b111101;
//    localparam ALU_BLEZ  = 6'b111110;
//    localparam ALU_BGTZ  = 6'b111111;

    always @(*) begin
        // Default values
        RegDst     = 2'b00;
        ALUSrc     = 1'b0;
        MemToReg   = 2'b00;
        RegWrite   = 1'b0;
        MemRead    = 1'b0;
        MemWrite   = 1'b0;
        ALUOp      = 6'b000000;
        Branch     = 1'b0;
        Jump       = 1'b0;
        JumpReg    = 1'b0;
        ZeroExtend = 1'b0;
        LUI        = 1'b0;
        MemSize    = 2'b11;
        LoadType   = 2'b00;
        LoadExtend = 1'b0;
        ALUShift   = 1'b0;

        case (opcode)
            // R-TYPE INSTRUCTIONS
            OP_RTYPE: begin
                case(funct)
                    // JR - Jump Register
                    FUNCT_JR: begin
                        RegWrite = 1'b0;
                        JumpReg  = 1'b1;
                        ALUOp    = ALU_JR;
                    end
                    
                    // JALR - Jump and Link Register
                    FUNCT_JALR: begin
                        RegWrite = 1'b1;
                        RegDst   = 2'b01;  // Write to rd
                        MemToReg = 2'b10;  // Write PC+4 to register
                        JumpReg  = 1'b1;
                        ALUOp    = ALU_JR;
                    end
                    
                    // SLL - Shift Left Logical
                    FUNCT_SLL: begin
                        RegWrite = 1'b1;
                        RegDst   = 2'b01;  // Write to rd
                        ALUSrc   = 1'b0;
                        MemToReg = 2'b00;  // Write ALU result
                        ALUOp    = funct;
                        ALUShift = 1'b1;   // Use shamt instead of rs
                    end
                    
                    // SRL - Shift Right Logical
                    FUNCT_SRL: begin
                        RegWrite = 1'b1;
                        RegDst   = 2'b01;
                        ALUSrc   = 1'b0;
                        MemToReg = 2'b00;
                        ALUOp    = funct;
                        ALUShift = 1'b1;
                    end
                    
                    // SRA - Shift Right Arithmetic
                    FUNCT_SRA: begin
                        RegWrite = 1'b1;
                        RegDst   = 2'b01;
                        ALUSrc   = 1'b0;
                        MemToReg = 2'b00;
                        ALUOp    = funct;
                        ALUShift = 1'b1;
                    end
                    
                    // All other R-type: ADD, ADDU, SUB, SUBU, AND, OR, XOR, NOR, SLT, SLTU
                    default: begin
                        RegWrite = 1'b1;
                        RegDst   = 2'b01;  // Write to rd
                        ALUSrc   = 1'b0;   // Use register for ALU input B
                        MemToReg = 2'b00;  // Write ALU result
                        ALUOp    = funct;  // Pass function code to ALU
                    end
                endcase
            end

            // I-TYPE ARITHMETIC/LOGICAL INSTRUCTIONS
            OP_ADDI: begin
                RegWrite   = 1'b1;
                RegDst     = 2'b00;  // Write to rt
                ALUSrc     = 1'b1;   // Use immediate
                MemToReg   = 2'b00;  // Write ALU result
                ALUOp      = ALU_ADD;
                ZeroExtend = 1'b0;   // Sign extend immediate
            end

            OP_ADDIU: begin
                RegWrite   = 1'b1;
                RegDst     = 2'b00;
                ALUSrc     = 1'b1;
                MemToReg   = 2'b00;
                ALUOp      = ALU_ADDU;
                ZeroExtend = 1'b0;
            end

            OP_SLTI: begin
                RegWrite   = 1'b1;
                RegDst     = 2'b00;
                ALUSrc     = 1'b1;
                MemToReg   = 2'b00;
                ALUOp      = ALU_SLT;
                ZeroExtend = 1'b0;
            end

            OP_SLTIU: begin
                RegWrite   = 1'b1;
                RegDst     = 2'b00;
                ALUSrc     = 1'b1;
                MemToReg   = 2'b00;
                ALUOp      = ALU_SLTU;
                ZeroExtend = 1'b0;
            end

            OP_ANDI: begin
                RegWrite   = 1'b1;
                RegDst     = 2'b00;
                ALUSrc     = 1'b1;
                MemToReg   = 2'b00;
                ALUOp      = ALU_AND;
                ZeroExtend = 1'b1;  // Zero extend for logical operations
            end

            OP_ORI: begin
                RegWrite   = 1'b1;
                RegDst     = 2'b00;
                ALUSrc     = 1'b1;
                MemToReg   = 2'b00;
                ALUOp      = ALU_OR;
                ZeroExtend = 1'b1;
            end

            OP_XORI: begin
                RegWrite   = 1'b1;
                RegDst     = 2'b00;
                ALUSrc     = 1'b1;
                MemToReg   = 2'b00;
                ALUOp      = ALU_XOR;
                ZeroExtend = 1'b1;
            end

            OP_LUI: begin
                RegWrite   = 1'b1;
                RegDst     = 2'b00;
                ALUSrc     = 1'b1;
                MemToReg   = 2'b00;
                ALUOp      = ALU_OR;
                ZeroExtend = 1'b1;
                LUI        = 1'b1;  // Shift immediate left by 16 bits
            end

            // LOAD INSTRUCTIONS
            OP_LW: begin
                RegWrite   = 1'b1;
                RegDst     = 2'b00;  // Write to rt
                ALUSrc     = 1'b1;   // Use offset for address calculation
                MemToReg   = 2'b01;  // Write memory data to register
                MemRead    = 1'b1;   // Enable memory read
                ALUOp      = ALU_ADD; // Calculate address (base + offset)
                MemSize    = 2'b11;  // Word access
                LoadExtend = 1'b0;   // No extension needed for word
            end

            OP_LB: begin
                RegWrite   = 1'b1;
                RegDst     = 2'b00;
                ALUSrc     = 1'b1;
                MemToReg   = 2'b01;
                MemRead    = 1'b1;
                ALUOp      = ALU_ADD;
                MemSize    = 2'b11;  // Read full word from memory
                LoadExtend = 1'b1;   // Use load extender
                LoadType   = 2'b00;  // LB (sign extend byte)
            end

            OP_LH: begin
                RegWrite   = 1'b1;
                RegDst     = 2'b00;
                ALUSrc     = 1'b1;
                MemToReg   = 2'b01;
                MemRead    = 1'b1;
                ALUOp      = ALU_ADD;
                MemSize    = 2'b11;
                LoadExtend = 1'b1;
                LoadType   = 2'b01;  // LH (sign extend halfword)
            end

            OP_LBU: begin
                RegWrite   = 1'b1;
                RegDst     = 2'b00;
                ALUSrc     = 1'b1;
                MemToReg   = 2'b01;
                MemRead    = 1'b1;
                ALUOp      = ALU_ADD;
                MemSize    = 2'b11;
                LoadExtend = 1'b1;
                LoadType   = 2'b10;  // LBU (zero extend byte)
            end

            OP_LHU: begin
                RegWrite   = 1'b1;
                RegDst     = 2'b00;
                ALUSrc     = 1'b1;
                MemToReg   = 2'b01;
                MemRead    = 1'b1;
                ALUOp      = ALU_ADD;
                MemSize    = 2'b11;
                LoadExtend = 1'b1;
                LoadType   = 2'b11;  // LHU (zero extend halfword)
            end

            // STORE INSTRUCTIONS
            OP_SW: begin
                ALUSrc   = 1'b1;     // Use offset for address calculation
                MemWrite = 1'b1;     // Enable memory write
                ALUOp    = ALU_ADD;  // Calculate address (base + offset)
                MemSize  = 2'b11;    // Word access
            end

            OP_SB: begin
                ALUSrc   = 1'b1;
                MemWrite = 1'b1;
                ALUOp    = ALU_ADD;
                MemSize  = 2'b00;    // Byte access
            end

            OP_SH: begin
                ALUSrc   = 1'b1;
                MemWrite = 1'b1;
                ALUOp    = ALU_ADD;
                MemSize  = 2'b01;    // Halfword access
            end

            // BRANCH INSTRUCTIONS
            OP_BEQ: begin
                ALUSrc = 1'b0;       // Compare two registers
                Branch = 1'b1;       // This is a branch instruction
                ALUOp  = ALU_BEQ;    // ALU checks if A == B
            end

            OP_BNE: begin
                ALUSrc = 1'b0;
                Branch = 1'b1;
                ALUOp  = ALU_BNE;    // ALU checks if A != B
            end

            OP_BLEZ: begin
                ALUSrc = 1'b0;
                Branch = 1'b1;
                ALUOp  = ALU_BLEZ;   // ALU checks if A <= 0
            end

            OP_BGTZ: begin
                ALUSrc = 1'b0;
                Branch = 1'b1;
                ALUOp  = ALU_BGTZ;   // ALU checks if A > 0
            end

            OP_REGIMM: begin
                ALUSrc = 1'b0;
                Branch = 1'b1;
                // Decode based on rt field (BLTZ or BGEZ)
                case(rt)
                    5'b00000: ALUOp = ALU_BLTZ;  // BLTZ: A < 0
                    5'b00001: ALUOp = ALU_BGEZ;  // BGEZ: A >= 0
                    default:  ALUOp = ALU_BLTZ;
                endcase
            end

            // JUMP INSTRUCTIONS
            OP_J: begin
                Jump  = 1'b1;        // Unconditional jump
                ALUOp = ALU_J;
            end

            OP_JAL: begin
                RegWrite = 1'b1;     // Write return address to $ra
                RegDst   = 2'b10;    // Write to $ra (register 31)
                MemToReg = 2'b10;    // Write PC+4 (return address)
                Jump     = 1'b1;     // Unconditional jump
                ALUOp    = ALU_J;
            end

            // DEFAULT
            default: begin
                // All signals remain at default values
            end
        endcase
    end

endmodule