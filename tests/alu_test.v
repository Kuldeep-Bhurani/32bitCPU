`include "alu.v"
`timescale 1ns/1ps

module alu_test;
    reg  [31:0] a = 0, b = 0;
    reg  [2:0]  ctrl = 0;
    wire [31:0] y;
    wire        zero;
    integer errors = 0;

    alu dut (.src1(a), .src2(b), .alu_control(ctrl), .alu_result(y), .zero(zero));

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
        $dumpfile("build/alu_test.vcd");
        $dumpvars(0, alu_test);
        $display("== alu_test ==");

        ctrl = 3'b000; a = 32'h10;       b = 32'hFFFFFFFC; #1 check(y, 32'h0000000C, "ADD 0x10 + (-4)");
        a = 32'h7FFFFFFF;                b = 32'h1;        #1 check(y, 32'h80000000, "ADD overflow wrap");
        ctrl = 3'b001; a = 32'h5;        b = 32'h5;        #1 check(y, 32'h0, "SUB 5-5");
                                                              check({31'b0, zero}, 32'h1, "zero flag set");
        a = 32'h3;                       b = 32'h5;        #1 check(y, 32'hFFFFFFFE, "SUB 3-5");
                                                              check({31'b0, zero}, 32'h0, "zero flag clear");
        ctrl = 3'b010; a = 32'hF0F0F0F0; b = 32'hFF00FF00; #1 check(y, 32'hF000F000, "AND");
        ctrl = 3'b011; a = 32'hF0F0F0F0; b = 32'h0F000F00; #1 check(y, 32'hFFF0FFF0, "OR");
        ctrl = 3'b111; a = 32'h1;        b = 32'h1;        #1 check(y, 32'h0, "unknown op -> 0");

        if (errors == 0) $display("alu_test: ALL TESTS PASSED");
        else             $display("alu_test: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule
