/*
  Description:
    A parameterized 2-to-1 multiplexer that selects between two inputs
    based on a select signal. The width of the data path is configurable
    via the WIDTH parameter.
  
  Parameters:
    WIDTH - Bit width of the data inputs and output (default: 32)
  
  Inputs:
    a[WIDTH-1:0] - Input selected when select = 1
    b[WIDTH-1:0] - Input selected when select = 0
    select       - Control signal (1 = choose a, 0 = choose b)
  
  Outputs:
    out[WIDTH-1:0] - Selected input value
  
  Functionality:
    When select = 1: out = a
    When select = 0: out = b
  
  Usage Examples:
    - RegDst_Mux: Selects between rt and rd as write register (WIDTH = 5)
    - ALUSrc_Mux: Selects between register data and immediate value (WIDTH = 32)
    - MemToReg_Mux: Selects between memory data and ALU result (WIDTH = 32)
 */

module mux2 #(parameter WIDTH = 32) (
    input [WIDTH-1:0] a,    // Input a (selected when select = 1)
    input [WIDTH-1:0] b,    // Input b (selected when select = 0)
    input select,           // Selection control signal     
    output [WIDTH-1:0] out  // Output
);

    // Combinational selection: ternary operator
    // If select is high, output a; otherwise output b
    assign out = (select) ? a : b;  
    
endmodule