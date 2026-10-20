`include "main.v"
`timescale 1ns/1ps

// Runs tests/lw_program.hex on the full core and checks the register file.
module main_test;
    reg clk = 0, rst = 1;
    integer errors = 0;

    main #(.IMEM_FILE("tests/lw_program.hex"),
           .DMEM_FILE("tests/lw_data.hex")) dut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;

    task check(input [31:0] actual, input [31:0] expected, input [255:0] name);
        begin
            if (actual === expected) $display("  PASS %0s = %h", name, actual);
            else begin
                $display("  FAIL %0s : got %h, expected %h", name, actual, expected);
                errors = errors + 1;
            end
        end
    endtask

    always @(posedge clk) if (!rst)
        $display("  [t=%0t] pc=%h instr=%h", $time, dut.pc, dut.instruction);

    initial begin
        $dumpfile("build/main_test.vcd");
        $dumpvars(0, main_test);
        $display("== main_test (lw) ==");

        repeat (2) @(negedge clk);
        rst = 0;
        repeat (5) @(negedge clk);
        #1;

        check(dut.regfile_inst.registers[9],  32'h00000010, "x9  <- lw x9, 8(x0)");
        check(dut.regfile_inst.registers[6],  32'hCAFEF00D, "x6  <- lw x6, -4(x9)");
        check(dut.regfile_inst.registers[7],  32'hDEADBEEF, "x7  <- lw x7, 0(x9)");
        check(dut.regfile_inst.registers[0],  32'h00000000, "x0 ignored lw x0, 0(x9)");
        check(dut.regfile_inst.registers[10], 32'h12345678, "x10 <- lw x10, 4(x9)");
        check(dut.pc,                         32'h00000014, "pc after 5 instructions");

        if (errors == 0) $display("main_test: ALL TESTS PASSED");
        else             $display("main_test: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule
