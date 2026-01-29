/*
  Description:
    32-register general-purpose register file for MIPS processor.
    Provides dual read ports (asynchronous) and one write port (synchronous).
    Register $0 is hardwired to zero and cannot be modified.
  
  Inputs:
    clock             - System clock (writes occur on positive edge)
    reset             - Asynchronous reset (active high)
    reg_write_en      - Write enable (1 = write to register on clock edge)
    read_reg1[4:0]    - Address of first register to read (rs)
    read_reg2[4:0]    - Address of second register to read (rt)
    write_reg[4:0]    - Address of register to write (rd)
    write_data[31:0]  - Data to write to register
  
  Outputs:
    read_data1[31:0]  - Data from register at read_reg1 (combinational)
    read_data2[31:0]  - Data from register at read_reg2 (combinational)
  
  Register Convention:
    $0 (register 0) - Always returns 0, writes are ignored
    $1-$31          - General purpose registers
  
  Functionality:
    - Reads: Asynchronous (combinational), can read two registers simultaneously
    - Writes: Synchronous on clock rising edge when reg_write_en is high
    - Reset: All registers cleared to 0
    - Register $0 protection: Always reads as 0, writes are blocked
 */

module reg_file (
    input clock,                  // System clock
    input reset,                  // Asynchronous reset
    input reg_write_en,           // Write enable signal
    input [4:0] read_reg1,        // Read port 1 address (rs)
    input [4:0] read_reg2,        // Read port 2 address (rt)
    input [4:0] write_reg,        // Write port address (rd)
    input [31:0] write_data,      // Data to write
    output [31:0] read_data1,     // Read port 1 data output
    output [31:0] read_data2      // Read port 2 data output
);

  
     // Register Array: 32 registers × 32 bits
    reg [31:0] registers [0:31];  // 32 registers, each 32 bits wide
    integer i;                    // Loop variable for reset

    /* 
      Asynchronous Read Logic
      Special case: Register 0 always returns 0
    */
    assign read_data1 = (read_reg1 == 0) ? 32'b0 : registers[read_reg1];
    assign read_data2 = (read_reg2 == 0) ? 32'b0 : registers[read_reg2];

    /*
	   Synchronous Write Logic
      Executes on positive clock edge or reset
    */
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // Reset: Clear all registers to 0
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end
        else begin
            // Write operation: Only if enabled and not writing to $0
            if (reg_write_en && (write_reg != 5'b0)) begin
                registers[write_reg] <= write_data;
            end
        end
    end
    
endmodule