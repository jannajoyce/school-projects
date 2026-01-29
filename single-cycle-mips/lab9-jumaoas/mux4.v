`timescale 1ns / 1ps

// Description:
//   A 4-input multiplexer that selects the next Program Counter (PC) value
//   in a MIPS single-cycle processor. The selection is based on the current
//   instruction type and branch conditions.
//
// Select Signal Encoding:
//   2'b00 → Input a: PC + 4 (sequential execution)
//   2'b01 → Input b: Branch target address
//   2'b10 → Input c: Jump target address  
//   2'b11 → Input d: Register-based address
//
// Instruction Types:
//   00: Normal sequential flow (fetch next instruction)
//   01: Conditional branches (BEQ, BNE, BLTZ, BGEZ, BLEZ, BGTZ)
//   10: Unconditional jumps (J, JAL)
//   11: Register jumps (JR, JALR)
//
// Notes:
//   - Purely combinational (no clock or state)
//   - Controlled by main control unit and branch logic


module mux4 #(
    parameter WIDTH = 32    // Bus width for addresses
)(
    input  wire [WIDTH-1:0] a,    // PC + 4
    input  wire [WIDTH-1:0] b,    // Branch target
    input  wire [WIDTH-1:0] c,    // Jump target
    input  wire [WIDTH-1:0] d,    // Register address
    input  wire [1:0]       sel,  // Source select
    output reg  [WIDTH-1:0] out     // Selected PC value
);

    always @(*) begin
        case (sel)
            2'b00:   out = a;    // Sequential
            2'b01:   out = b;    // Branch
            2'b10:   out = c;    // Jump
            2'b11:   out = d;    // Register jump
            default: out = a;    // Safe default
        endcase
    end

endmodule