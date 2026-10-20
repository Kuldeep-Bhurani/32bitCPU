`include "main.v"
`timescale 1ns/1ps

module beq_test;
    reg clk = 0, rst = 1;
    integer errors = 0;

    main #(.IMEM_FILE("tests/beq_program.hex"),
           .DMEM_FILE("tests/beq_data.hex")) dut (.clk(clk), .rst(rst));

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
        $dumpfile("build/beq_test.vcd");
        $dumpvars(0, beq_test);
        $display("== beq_test ==");

        repeat (2) @(negedge clk);
        rst = 0;
        repeat (4) @(negedge clk);
        #1;

        check(dut.regfile_inst.registers[1], 32'd5, "lw setup x1");
        check(dut.regfile_inst.registers[2], 32'd0, "taken beq skips lw x2");
        check(dut.pc, 32'h00000014, "not-taken then taken branch PC");

        if (errors == 0) $display("beq_test: ALL TESTS PASSED");
        else begin
            $display("beq_test: %0d FAILURE(S)", errors);
            $fatal(1, "beq_test failed");
        end
        $finish;
    end
endmodule
