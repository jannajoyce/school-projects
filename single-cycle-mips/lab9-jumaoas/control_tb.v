/*
  Description:
    Comprehensive testbench for the control unit module. Tests all supported
    instruction types and verifies that correct control signals are generated
    for each instruction.
  
  Test Coverage:
    R-Type Instructions:
      - ADD (Add)
      - SUB (Subtract)
      - AND (Bitwise AND)
      - OR  (Bitwise OR)
      - NOR (Bitwise NOR)
    
    I-Type Instructions:
      - ADDI (Add Immediate)
      - LW   (Load Word)
      - SW   (Store Word)
  
  Test Methodology:
    1. Apply instruction pattern to control unit
    2. Wait 10 time units
    3. Monitor outputs via $monitor statement
    4. Verify control signals match expected values
  
  Expected Outputs (Summary):
    - R-type: RegDst=1, ALUSrc=0, MemToReg=0, RegWrite=1, MemRead=0, MemWrite=0
    - ADDI:   RegDst=0, ALUSrc=1, MemToReg=0, RegWrite=1, MemRead=0, MemWrite=0
    - LW:     RegDst=0, ALUSrc=1, MemToReg=1, RegWrite=1, MemRead=1, MemWrite=0
    - SW:     RegDst=X, ALUSrc=1, MemToReg=X, RegWrite=0, MemRead=0, MemWrite=1
  
  Monitor Output Format:
    Displays time, instruction binary, instruction name, and all control signals
 */

`timescale 1ns / 1ps

module control_tb;

    // Testbench Signals
 
    // Input (reg type for testbench control)
    reg [31:0] instruction;      // Instruction to test
    
    // Outputs (wire type)
    wire RegDst;                 // Register destination select
    wire ALUSrc;                 // ALU source select
    wire MemToReg;               // Memory to register select
    wire RegWrite;               // Register write enable
    wire MemRead;                // Memory read enable
    wire MemWrite;               // Memory write enable
    wire [5:0] ALUOp;            // ALU operation code
    
    // Helper signal for displaying instruction names
    reg [80*8:0] instr_name;     // String to store instruction name (80 chars)

    // Device Under Test (DUT) Instantiation
    
    control uut (
        .instruction(instruction),
        .RegDst(RegDst),
        .ALUSrc(ALUSrc),
        .MemToReg(MemToReg),
        .RegWrite(RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .ALUOp(ALUOp)
    );

    // Monitor: Display control signals for each test
     
    initial begin
        $monitor("Time: %0t | Instr: %b | instr_name: %-15s | RegDst; %b | ALUSrc: %b | MemToReg: %b | RegWrite: %b | MemRead: %b | MemWrite: %b | ALUOp: %b",
                 $time, instruction, instr_name, RegDst, ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, ALUOp);
    end

    // Test Sequence
     
    initial begin
        
        /* 
          TEST 1: R-type ADD instruction
          Format: 000000 | rs | rt | rd | shamt | 100000
          Expected: RegDst=1, ALUSrc=0, MemToReg=0, RegWrite=1, ALUOp=100000
        */
        instruction = 32'b00000000000000000000000000100000; // ADD (funct=100000)
        instr_name = "R-type (ADD)";
        #10;

        /* 
          TEST 2: I-type ADDI instruction
          Format: 001000 | rs | rt | immediate
          Expected: RegDst=0, ALUSrc=1, MemToReg=0, RegWrite=1, ALUOp=100000
        */
        instruction = 32'b00100000000000000000000000000000; // ADDI (opcode=001000)
        instr_name = "I-type (ADDI)";
        #10;
		  
        /* 
          TEST 3: R-type SUB instruction
          Format: 000000 | rs | rt | rd | shamt | 100010
          Expected: RegDst=1, ALUSrc=0, MemToReg=0, RegWrite=1, ALUOp=100010
       */
        instruction = 32'b00000000000000000000000000100010; // SUB (funct=100010)
        instr_name = "R-type (SUB)";
        #10;

        /* 
          TEST 4: R-type AND instruction
          Format: 000000 | rs | rt | rd | shamt | 100100
          Expected: RegDst=1, ALUSrc=0, MemToReg=0, RegWrite=1, ALUOp=100100
       */
        instruction = 32'b00000000000000000000000000100100; // AND (funct=100100)
        instr_name = "R-type (AND)";
        #10;

        /* 
          TEST 5: R-type OR instruction
          Format: 000000 | rs | rt | rd | shamt | 100101
          Expected: RegDst=1, ALUSrc=0, MemToReg=0, RegWrite=1, ALUOp=100101
        */
        instruction = 32'b00000000000000000000000000100101; // OR (funct=100101)
        instr_name = "R-type (OR)";
        #10;
		  
        /* 
          TEST 6: R-type NOR instruction
          Format: 000000 | rs | rt | rd | shamt | 100111
          Expected: RegDst=1, ALUSrc=0, MemToReg=0, RegWrite=1, ALUOp=100111
       */
        instruction = 32'b00000000000000000000000000100111; // NOR (funct=100111)
        instr_name = "R-type (NOR)";
        #10;

        /*
          TEST 7: I-type LW (Load Word) instruction
          Format: 100011 | rs | rt | offset
          Expected: RegDst=0, ALUSrc=1, MemToReg=1, RegWrite=1, MemRead=1, ALUOp=100000
        */
        instruction = 32'b10001100000000000000000000000000; // LW (opcode=100011)
        instr_name = "I-type (LW)";
        #10;

        /* 
          TEST 8: I-type SW (Store Word) instruction
          Format: 101011 | rs | rt | offset
          Expected: ALUSrc=1, RegWrite=0, MemWrite=1, ALUOp=100000
                    RegDst=X, MemToReg=X (don't care)
        */
        instruction = 32'b10101100000000000000000000000000; // SW (opcode=101011)
        instr_name = "I-type (SW)";
        #10;

        // Test Completion
         
        $stop;  // Stop simulation (allows continuation in some simulators)
    end
    
endmodule