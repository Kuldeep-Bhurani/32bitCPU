`include "main.v"
`timescale 1ns/1ps

// Core-level store-word regression tests. Run from the repository root.
module sw_test;
    reg clk = 0;
    reg rst = 1;
    integer errors = 0;

    main #(.IMEM_FILE("tests/sw_program.hex"),
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
        $dumpfile("build/sw_test.vcd");
        $dumpvars(0, sw_test);
        $display("== sw_test ==");

        repeat (2) @(negedge clk);
        rst = 0;
        repeat (7) @(negedge clk);
        #1;

        check(dut.regfile_inst.registers[9],  32'h00000010, "lw setup x9 pointer");
        check(dut.regfile_inst.registers[10], 32'hAAAAAAAA, "lw setup x10");
        check(dut.regfile_inst.registers[11], 32'hCAFEF00D, "lw setup x11");
        check(dut.regfile_inst.registers[12], 32'h12345678, "lw setup x12");

        check(dut.dmem.mem[7], 32'hAAAAAAAA, "sw x10, 12(x9) writes byte address 0x1C");
        check(dut.dmem.mem[4], 32'hCAFEF00D, "sw x11, 0(x9) writes byte address 0x10");
        check(dut.regfile_inst.registers[0], 32'h00000000, "x0 remains zero");
        check(dut.pc, 32'h0000001C, "PC after 7 instructions");

        if (errors == 0) $display("sw_test: ALL TESTS PASSED");
        else             $display("sw_test: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule
