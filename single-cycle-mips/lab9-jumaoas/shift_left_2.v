`timescale 1ns / 1ps

// Description:
//   Performs a logical left shift by 2 bit positions, effectively multiplying
//   the input by 4. This is used to convert word-aligned offsets into byte
//   addresses, since MIPS instructions and word data are always aligned to
//   4-byte boundaries.
//
// Mathematical Operation:
//   output = input × 4
//   output = input << 2
//
// Example:
//   Input:  32'h00000001 (1 word)
//   Output: 32'h00000004 (4 bytes)
//
//   Input:  32'h00000010 (16 words)
//   Output: 32'h00000040 (64 bytes)
//
// Usage in MIPS:
//   - Branch instructions: Convert signed immediate offset to byte offset
//   - Jump instructions: Convert 26-bit word address to 28-bit byte address
//   - Address calculations: Any word-to-byte conversion
//
// Implementation:
//   Hardware-wise, this is simply a rewiring of bits (no logic gates needed).
//   The two LSBs become zero, and all other bits shift left by 2 positions.
//
// Timing:
//   Combinational logic only - zero delay (aside from wire propagation)

module shift_left_2 #(
    parameter WIDTH = 32    // Data width in bits
)(
    input  wire [WIDTH-1:0] in,     // Value to shift (word offset)
    output wire [WIDTH-1:0] out     // Shifted value (byte address)
);

    // Shift implementation: drop 2 MSBs, append 2 zero LSBs
    // in[WIDTH-1:WIDTH-2] are discarded
    // in[WIDTH-3:0] become out[WIDTH-1:2]
    // out[1:0] = 2'b00
    assign out = {in[WIDTH-3:0], 2'b00};

endmodule