`timescale 1ns / 1ps

module control (
    input [31:0] instruction,
    output reg RegDst,
    output reg ALUSrc,
    output reg MemToReg,
    output reg RegWrite,
    output reg MemRead,
    output reg MemWrite,
    output reg [5:0] ALUOp
);

    wire [5:0] opcode = instruction[31:26];
    wire [5:0] funct  = instruction[5:0];

    localparam OP_RTYPE = 6'b000000;
    localparam OP_LW    = 6'b100011;
    localparam OP_SW    = 6'b101011;
    localparam OP_ADDI  = 6'b001000;

    localparam FUNC_ADD = 6'b100000;
    localparam FUNC_SUB = 6'b100010;
    localparam FUNC_AND = 6'b100100;
    localparam FUNC_OR  = 6'b100101;
    localparam FUNC_NOR = 6'b100111;
    localparam FUNC_XOR = 6'b100110;

    always @(*) begin
        RegDst   = 0;
        ALUSrc   = 0;
        MemToReg = 0;
        RegWrite = 0;
        MemRead  = 0;
        MemWrite = 0;
        ALUOp    = 6'b000000;

        case (opcode)
            OP_LW: begin
                RegDst   = 0;
                ALUSrc   = 1;
                MemToReg = 1;
                RegWrite = 1;
                MemRead  = 1;
                MemWrite = 0;
                ALUOp    = FUNC_ADD;
            end

            OP_SW: begin
                RegDst   = 1'bx;
					 ALUSrc   = 1;
					 MemToReg = 1'bx;
                RegWrite = 0;
                MemRead  = 0;
                MemWrite = 1;
                ALUOp    = FUNC_ADD;
            end

            OP_ADDI: begin
                RegDst   = 0;
                ALUSrc   = 1;
                MemToReg = 0;
                RegWrite = 1;
                MemRead  = 0;
                MemWrite = 0;
                ALUOp    = FUNC_ADD;
            end

            OP_RTYPE: begin
                RegDst   = 1;
                ALUSrc   = 0;
                MemToReg = 0;
                RegWrite = 1;
                MemRead  = 0;
                MemWrite = 0;

                case (funct)
                    FUNC_ADD: ALUOp = FUNC_ADD;
                    FUNC_SUB: ALUOp = FUNC_SUB;
                    FUNC_AND: ALUOp = FUNC_AND;
                    FUNC_OR : ALUOp = FUNC_OR;
                    FUNC_NOR: ALUOp = FUNC_NOR;
                    FUNC_XOR: ALUOp = FUNC_XOR;
                    default : ALUOp = 6'b000000;
                endcase
            end

            default: begin
                ALUOp = 6'b000000;
            end
        endcase
    end

endmodule
