// Purpose:
//   Extends a narrow input value to a wider output by padding the upper
//   bits with zeros. Unlike sign extension, the most significant bit (MSB)
//   of the input is not replicated.
//
// Common Uses in MIPS:
//   - Logical immediate instructions (ANDI, ORI, XORI)
//   - Load upper immediate (LUI)
//   - Unsigned load instructions (LBU, LHU)
//
// Operation:
//   Upper bits = all zeros
//   Lower bits = input value
//
// Example (16-bit to 32-bit):
//   Input:  16'h8001 (sign bit = 1)
//   Output: 32'h00008001 (upper 16 bits = 0)
//
// Implementation:
//   Purely combinational assignment using concatenation.

module zero_extender #(
    parameter IN_WIDTH  = 16,    // Input bit width
    parameter OUT_WIDTH = 32     // Output bit width
)(
    input  wire [IN_WIDTH-1:0]  in,     // Input value
    output wire [OUT_WIDTH-1:0] out     // Zero-extended output
);

    // Zero-extend by concatenating zeros with the input
    // Format: {padding_zeros, original_input}
    assign out = {{(OUT_WIDTH-IN_WIDTH){1'b0}}, in};

endmodule