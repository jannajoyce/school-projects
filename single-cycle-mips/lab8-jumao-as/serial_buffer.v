`timescale 1ns / 1ps

/*
** -------------------------------------------------------------------
**  Serial Module for Single-Cycle MIPS Processor for Altera FPGAs
**  Implements a very simple memory mapped serial port interface
**  *Does Not* actually implement the serial communication
**
**  Change Log:
**  1/13/2012 - Adrian Caulfield - Initial Implementation
**
**
**  NOTE:  The Provided Modules do NOT follow the course coding standards
*/

module serial_buffer	(
	input	clock,
	input	reset,
		
	input [31:0] addr_in,
	output reg [31:0] data_out,
	input	re_in,
	input [31:0] data_in,
	input we_in,
		
	input	s_data_valid_in, //data to be read is available
	input [7:0] s_data_in,
	input	s_data_ready_in, //ready to recieve write data
	output reg s_rden_out,
	output reg [7:0] s_data_out,
	output reg s_wren_out
	);
	
	parameter MEM_ADDR = 16'hffff;
		
	//read values (async)
	always @(*) begin
		case(addr_in[3:2])
			2'h0:
				data_out = {31'b0, s_data_valid_in};
			2'h1:
				data_out = {24'b0, s_data_in};
			2'h2:
				data_out = {31'b0, s_data_ready_in};
			2'h3:
				data_out = {32'b0};
		endcase
	end
	
	
	
	//reg	read_en;
	//reg	write_en;
	reg [7:0] sbyte;
	
	/*assign s_rden_out = read_en;
	assign s_wren_out = write_en;
	assign s_data_out = sbyte;*/
	
	// Sequential logic for write and read enables
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            s_rden_out <= 1'b0;
            s_wren_out <= 1'b0;
            sbyte <= 8'b0;
            s_data_out <= 8'b0; // Reset serial output
        end else begin
            s_rden_out <= 1'b0; // Default to no read operation
            s_wren_out <= 1'b0; // Default to no write operation

            // Check address and perform read/write operations
            if (addr_in[31:16] == MEM_ADDR) begin
                // Read operation: Triggered on read enable and correct address
                if (re_in && (addr_in[3:2] == 2'h1)) begin
                    s_rden_out <= 1'b1;
                end

                // Write operation: Triggered on write enable and correct address
                if (we_in && (addr_in[3:2] == 2'h3)) begin
                    sbyte <= data_in[7:0]; // Capture the lower byte of input data
                    s_data_out <= data_in[7:0]; // Procedural assignment to output
                    s_wren_out <= 1'b1;    // Assert write enable
                end
            end
        end
    end
	
endmodule