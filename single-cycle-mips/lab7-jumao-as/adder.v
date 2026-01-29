/*
 * Description:
 *   A simple 32-bit combinational adder that adds two 32-bit inputs.
 *   This module is primarily used for PC increment operations (PC + 4)
 *   in the processor datapath.
 * 
 * Parameters:
 *   None
 * 
 * Inputs:
 *   a[31:0]   - First 32-bit operand
 *   b[31:0]   - Second 32-bit operand
 * 
 * Outputs:
 *   sum[31:0] - 32-bit sum of a + b
 * 
 * Functionality:
 *   Performs combinational addition using the '+' operator.
 *   No carry-out or overflow flags are provided.
 * 
 * Usage Example:
 *   In processor.v, this adds PC + 4 to calculate the next instruction address.
 */

module adder (
    input [31:0] a,        // First operand
    input [31:0] b,        // Second operand
    output [31:0] sum      // Result of a + b
);
    // Combinational addition
    assign sum = a + b;  
endmodule