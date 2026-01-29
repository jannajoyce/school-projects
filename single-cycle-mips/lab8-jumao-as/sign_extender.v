/*
  Description:
    Sign extension module that extends a 16-bit signed value to 32 bits.
    Used in MIPS processor to extend immediate values from I-type instructions
    to the full 32-bit datapath width while preserving the sign.
  
  Inputs:
    in[15:0]  - 16-bit input value (immediate field from instruction)
  
  Outputs:
    out[31:0] - 32-bit sign-extended output
  
  Functionality:
    - Takes the sign bit (bit 15) of the input
    - Replicates it 16 times to fill the upper 16 bits
    - Concatenates with the original 16-bit input
 
  Examples:
    in = 0x0001 (positive) → out = 0x00000001
    in = 0xFFFF (negative, -1) → out = 0xFFFFFFFF
    in = 0x7FFF (positive, 32767) → out = 0x00007FFF
    in = 0x8000 (negative, -32768) → out = 0xFFFF8000
  
  Usage in MIPS:
    Used for immediate operands in instructions like:
    - ADDI (add immediate)
    - LW/SW (load/store word with offset)
    - Branch instructions (offset calculation)
 */

module sign_extender (
    input [15:0] in,         // 16-bit input value
    output [31:0] out        // 32-bit sign-extended output
);

    // Sign extension using replication operator
    // {16{in[15]}} creates 16 copies of the sign bit
    // Concatenated with original 16-bit value
    assign out = {{16{in[15]}}, in};
    
endmodule
