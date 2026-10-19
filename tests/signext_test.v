`include "signext.v"
`timescale 1ns/1ps

module signext_test;
    reg  [31:0] instr = 0;
    reg  [1:0]  imm_src = 2'b00;
    wire [31:0] imm;
    integer errors = 0;

    signext dut (.raw_src(instr[31:7]), .imm_src(imm_src), .immediate(imm));

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
        $dumpfile("build/signext_test.vcd");
        $dumpvars(0, signext_test);
        $display("== signext_test ==");

        instr = 32'hFFC4A303; #1 check(imm, 32'hFFFFFFFC, "imm = -4");
        instr = 32'h00802483; #1 check(imm, 32'h00000008, "imm = +8");
        instr = 32'h7FF4A303; #1 check(imm, 32'h000007FF, "imm = +2047 (max)");
        instr = 32'h8004A303; #1 check(imm, 32'hFFFFF800, "imm = -2048 (min)");
        instr = 32'h0004A303; #1 check(imm, 32'h00000000, "imm = 0");

        if (errors == 0) $display("signext_test: ALL TESTS PASSED");
        else             $display("signext_test: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule
