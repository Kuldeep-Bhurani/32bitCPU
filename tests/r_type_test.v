`include "main.v"
`timescale 1ns/1ps

// Core-level R-type (add/and/or) test; add x0,... must be ignored. Run from the repository root.
module r_type_test;
    reg clk = 0, rst = 1;
    integer errors = 0;

    main #(.IMEM_FILE("tests/r_program.hex"),
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

    initial begin
        $dumpfile("build/r_type_test.vcd");
        $dumpvars(0, r_type_test);
        $display("== r_type_test ==");

        repeat (2) @(negedge clk);
        rst = 0;
        repeat (7) @(negedge clk);
        #1;

        check(dut.regfile_inst.registers[5], 32'hAAAAAAAA, "lw x5");
        check(dut.regfile_inst.registers[6], 32'hCAFEF00D, "lw x6");
        check(dut.regfile_inst.registers[7], 32'h75A99AB7, "add x7 = x5 + x6");
        check(dut.regfile_inst.registers[8], 32'h8AAAA008, "and x8 = x5 & x6");
        check(dut.regfile_inst.registers[9], 32'hEAFEFAAF, "or  x9 = x5 | x6");
        check(dut.regfile_inst.registers[10], 32'h60A89AA7, "and x10 = x7 & x9 (chained)");
        check(dut.regfile_inst.registers[0], 32'h00000000, "x0 remains zero");
        check(dut.pc, 32'h0000001C, "PC after 7 instructions");

        if (errors == 0) $display("r_type_test: ALL TESTS PASSED");
        else             $display("r_type_test: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule
