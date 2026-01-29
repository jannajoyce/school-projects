`timescale 1ns / 1ps

/*
** -------------------------------------------------------------------
**  Instruction Rom for Single-Cycle MIPS Processor for Altera FPGAs
**
**  Change Log:
**  1/13/2012 - Adrian Caulfield - Initial Implementation
**
**
**  NOTE:  The Provided Modules do NOT follow the course coding standards
*/

module inst_rom(
    input clock,
    input reset,
    input [31:0] addr_in,
    output [31:0] data_out
);

    parameter ADDR_WIDTH = 5;
    parameter INIT_PROGRAM = "C:/intelFPGA_lite/18.1/quartus/181.1/lab7-jumao-as/blank.memh";

    reg [31:0] rom [0:2**ADDR_WIDTH-1];
    reg [31:0] out;

    assign data_out = {out[7:0], out[15:8], out[23:16], out[31:24]};

    initial begin
        $readmemh(INIT_PROGRAM, rom);
    end

    always @(posedge clock) begin
        if (reset)
            out <= 32'h00000000;
        else
            out <= rom[addr_in[ADDR_WIDTH+1:2]];
    end

endmodule
