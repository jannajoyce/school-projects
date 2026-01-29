`timescale 1ns / 1ps

// Purpose:
//   Processes data read from memory for load instructions by selecting the
//   appropriate byte or halfword from a 32-bit memory word and performing
//   sign-extension or zero-extension based on the instruction type.
//
// Supported Instructions:
//   LB  (00) - Load Byte (sign-extended)
//   LH  (01) - Load Halfword (sign-extended)
//   LBU (10) - Load Byte Unsigned (zero-extended)
//   LHU (11) - Load Halfword Unsigned (zero-extended)
//
// Operation:
//   This is a purely combinational module with no clock or state.

module load_extender (
    input  wire [31:0] mem_data,       // 32-bit word from memory
    input  wire [1:0]  byte_offset,    // Address bits [1:0] for byte/halfword selection
    input  wire [1:0]  load_type,      // Load instruction type (see above)
    output reg  [31:0] extended_data   // Final 32-bit register value
);

    // Internal signals for selected data
    reg [7:0]  selected_byte;    // Selected 8-bit byte
    reg [15:0] selected_half;    // Selected 16-bit halfword
    
    always @(*) begin
        
        // Select byte based on byte_offset (addr[1:0])
        case (byte_offset)
            2'b00: selected_byte = mem_data[7:0];    // Byte 0 (bits 7:0)
            2'b01: selected_byte = mem_data[15:8];   // Byte 1 (bits 15:8)
            2'b10: selected_byte = mem_data[23:16];  // Byte 2 (bits 23:16)
            2'b11: selected_byte = mem_data[31:24];  // Byte 3 (bits 31:24)
        endcase
        
        // Step 2: Select halfword based on addr[1]
        case (byte_offset[1])
            1'b0: selected_half = mem_data[15:0];    // Lower halfword
            1'b1: selected_half = mem_data[31:16];   // Upper halfword
        endcase
    
        // Step 3: Extend to 32 bits based on load_type
        case (load_type)
            2'b00: extended_data = {{24{selected_byte[7]}}, selected_byte};  // LB: sign-extend byte
            2'b01: extended_data = {{16{selected_half[15]}}, selected_half}; // LH: sign-extend halfword
            2'b10: extended_data = {24'b0, selected_byte};                   // LBU: zero-extend byte
            2'b11: extended_data = {16'b0, selected_half};                   // LHU: zero-extend halfword
            default: extended_data = mem_data;                               // Pass through (safety)
        endcase
    end

endmodule