/*
  Description:
    Program Counter (PC) register for the MIPS processor.
    Stores the address of the current instruction being executed.
    Updates on each clock cycle with the next instruction address.
  
  Inputs:
    clock        - System clock (updates on positive edge)
    reset        - Asynchronous reset (active high)
    pc_in[31:0]  - Next program counter value
  
  Outputs:
    pc_out[31:0] - Current program counter value (registered)
  
  Functionality:
    - On reset: PC is initialized to 0x003FFFFC
      This is typically the address of the last word in instruction memory,
      or a special initialization address for the system.
    - On clock edge: PC is updated with pc_in (normally PC + 4 or branch target)
  
  Reset Value Notes:
    The reset value 0x003FFFFC = 4,194,300 decimal
    This appears to be the highest word-aligned address in a 4MB address space,
    which might be used for bootloader or initialization code location.
 */

module program_counter (
    input clock,              // System clock
    input reset,              // Asynchronous reset
    input [31:0] pc_in,       // Next PC value (from adder or branch logic)
    output reg [31:0] pc_out  // Current PC value (registered output)
);

    // Sequential Logic: Update PC on clock edge or reset
    	
    always @(posedge clock or posedge reset) begin
        if (reset)
            // Reset: Initialize PC to specific start address
            pc_out <= 32'h003FFFFC;
        else
            // Normal operation: Load next PC value
            pc_out <= pc_in;
    end

endmodule

