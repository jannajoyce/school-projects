`timescale 1ns/1ps

module testbench();

    reg clock;
    reg reset;

    // Serial input signals
    reg  [7:0] serial_in;
    reg        serial_valid_in;
    reg        serial_ready_in;

    // Serial outputs from DUT
    wire [7:0] serial_out;
    wire       serial_rden_out;
    wire       serial_wren_out;

    // Clock generation: 100 MHz -> period = 10 ns, half-period = 5 ns
    initial begin
        clock = 1'b0;
        forever #5 clock = ~clock;
    end

    // Reset pulse: hold reset for 200 ns
    initial begin
        reset = 1'b1;
        #200 reset = 1'b0;
    end

    // Instantiate the processor DUT (ports match your processor)
    processor dut (
	 .clock(clock),
    .reset(reset),
    .serial_in(serial_in),
    .serial_valid_in(serial_valid_in),
    .serial_ready_in(serial_ready_in),
    .serial_out(serial_out),
    .serial_rden_out(serial_rden_out),
    .serial_wren_out(serial_wren_out),
    .pc_out(),
    .instruction_out(),
    .alu_a_out(),
    .alu_b_out(),
    .alu_out_output()
    );

    // Monitor serial writes from DUT and print them
    always @(posedge clock) begin
        if (!reset && serial_wren_out) begin
            $display("[%0t ns] SERIAL OUT: %c (0x%0h)", $time, serial_out, serial_out);
        end
    end

    // Finish simulation after a timeout (adjust as needed)
    initial begin
        #10000 $finish;
    end

endmodule
