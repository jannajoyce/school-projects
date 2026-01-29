/*
  Description:
    A parameterized 2-to-1 multiplexer that selects between two inputs
    based on a select signal. The width of the data path is configurable
    via the WIDTH parameter.
  
  Parameters:
    WIDTH - Bit width of the data inputs and output (default: 32)
  
  Inputs:
    a[WIDTH-1:0] - Input selected when sel = 1
    b[WIDTH-1:0] - Input selected when sel = 0
    sel          - Control signal (1 = choose a, 0 = choose b)
  
  Outputs:
    out[WIDTH-1:0] - Selected input value
  
  Functionality:
    When sel = 1: out = a
    When sel = 0: out = b
  
  Usage Examples:
    - Write register selection: Selects between rt, rd, or $ra (WIDTH = 5)
    - ALUSrc: Selects between register data and immediate value (WIDTH = 32)
    - MemToReg: Selects between ALU result, memory data, or PC+4 (WIDTH = 32)
    - Load extender: Selects between extended and direct memory data (WIDTH = 32)
 */

module mux2 #(parameter WIDTH = 32) (
    input [WIDTH-1:0] a,    // Input a (selected when select = 1)
    input [WIDTH-1:0] b,    // Input b (selected when select = 0)
    input sel,           // Selection control signal     
    output [WIDTH-1:0] out  // Output
);

    // Combinational selection: ternary operator
    // If select is high, output a; otherwise output b
    assign out = (sel) ? a : b;  
    
endmodule