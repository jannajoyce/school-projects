/*
 Description:
   Comprehensive testbench for the register file module.
   Verifies correct functionality of reads, writes, register $0 protection,
   and simultaneous operations.
 
 Test Coverage:
   Test 1: Write and read back from register 1
   Test 2: Verify register $0 is hardwired to zero (ignores writes)
   Test 3: Simultaneous dual reads from different registers
   Test 4: Write enable disable - ensure no writes occur
   Test 5: Simultaneous read from $0 and another register
 
 Expected Behavior:
   - Register $0 always returns 0x00000000
   - Writes only occur when reg_write_en = 1
   - Reads are asynchronous (immediate)
   - Register values persist across cycles
 */

`timescale 1ns / 1ps

module reg_file_tb;

    
    // Testbench Signals
    // Inputs (reg type for testbench control)
    reg clock;
    reg reset;
    reg reg_write_en;
    reg [4:0] read_reg1;
    reg [4:0] read_reg2;
    reg [4:0] write_reg;
    reg [31:0] write_data;

    // Outputs (wire type)
    wire [31:0] read_data1;
    wire [31:0] read_data2;

    // Device Under Test (DUT) Instantiation
    reg_file dut (
        .clock(clock),
        .reset(reset),
        .reg_write_en(reg_write_en),
        .read_reg1(read_reg1),
        .read_reg2(read_reg2),
        .write_reg(write_reg),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );


     // Clock Generation: 10 ns period (100 MHz)
     // 5 ns high, 5 ns low
    always #5 clock = ~clock;

     // Test Sequence
    initial begin
        // Initialize all inputs
        clock        = 0;
        reset        = 1;
        reg_write_en = 0;
        read_reg1    = 0;
        read_reg2    = 0;
        write_reg    = 0;
        write_data   = 0;

        // Apply reset for one clock cycle
        @(posedge clock);
        reset = 0;

        /*
          TEST 1: Write and Read Register 1
          Expected: Register 1 should contain c0dedbee
         */
        write_reg    = 5'd1;
        write_data   = 32'hc0dedbee;
        reg_write_en = 1;
        @(posedge clock);       // Wait for write to complete
        reg_write_en = 0;

        read_reg1 = 5'd1;
        #1;                     // Wait for combinational read
        $display("Test 1 - Reg1 = %h (expected c0dedbee)", read_data1);
		  
        /* 
          TEST 2: Attempt to Write to Register $0
          Expected: Register 0 should remain 0x00000000 (hardwired)
        */
        write_reg    = 5'd0;
        write_data   = 32'h85764390;
        reg_write_en = 1;
        @(posedge clock);       // Wait for attempted write
        reg_write_en = 0;

        read_reg1 = 5'd0;
        #1;                     // Wait for combinational read
        $display("Test 2 - Reg0 = %h (expected 00000000)", read_data1);

        /* 
          TEST 3: Simultaneous Asynchronous Reads
          Expected: Reg1 = c0dedbee, Reg2 = 0xACEDEED4
        */
        write_reg    = 5'd2;
        write_data   = 32'hbedfaced;
        reg_write_en = 1;
        @(posedge clock);       // Write to register 2
        reg_write_en = 0;

        read_reg1 = 5'd1;       // Read both registers simultaneously
        read_reg2 = 5'd2;
        #1;                     // Wait for combinational read
        $display("Test 3 - Reg1 = %h, Reg2 = %h (expected c0dedbee, bedfaced)",
                 read_data1, read_data2);

        /*
          TEST 4: Write Enable Disabled
          Expected: Register 3 should remain 0x00000000 (write blocked)
        */
        write_reg    = 5'd3;
        write_data   = 32'h09815323;
        reg_write_en = 0;       // Write disabled
        @(posedge clock);       // Clock edge with write disabled

        read_reg1 = 5'd3;
        #1;                     // Wait for combinational read
        $display("Test 4 - Reg3 = %h (expected 00000000)", read_data1);

        /* 
          TEST 5: Simultaneous Read of $0 and Another Register
          Expected: Reg0 = 0x00000000, Reg1 = c0dedbee
        */
        read_reg1 = 5'd0;
        read_reg2 = 5'd1;
        #1;                     // Wait for combinational read
        $display("Test 5 - Reg0 = %h, Reg1 = %h (expected 00000000, c0dedbee)",
                 read_data1, read_data2);

        //Test Completion
        $display("All register file tests completed.");
        $finish;
    end

endmodule