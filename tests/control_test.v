`include "control.v"
`timescale 1ns/1ps

module control_test;
    reg  [6:0] op = 0;
    reg  [2:0] funct3 = 0;
    wire       reg_write, alu_src, mem_write, result_src;
    wire [1:0] imm_src;
    wire [2:0] alu_control;
    integer errors = 0;

    control dut (.op(op), .funct3(funct3), .reg_write(reg_write), .imm_src(imm_src),
                 .alu_src(alu_src), .mem_write(mem_write), .result_src(result_src),
                 .alu_control(alu_control));

    task check(input [31:0] actual, input [31:0] expected, input [255:0] name);
        begin
            if (actual === expected) $display("  PASS %0s = %0d", name, actual);
            else begin
                $display("  FAIL %0s : got %0d, expected %0d", name, actual, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("build/control_test.vcd");
        $dumpvars(0, control_test);
        $display("== control_test ==");

        op = 7'b0000011; funct3 = 3'b010; #1;
        check(reg_write,   1, "lw reg_write");
        check(imm_src,     0, "lw imm_src (I-type)");
        check(alu_src,     1, "lw alu_src (imm)");
        check(mem_write,   0, "lw mem_write");
        check(result_src,  1, "lw result_src (memory)");
        check(alu_control, 0, "lw alu_control (add)");

        op = 7'b0100011; funct3 = 3'b010; #1;
        check(reg_write,   0, "sw reg_write disabled");
        check(imm_src,     1, "sw imm_src (S-type)");
        check(alu_src,     1, "sw alu_src (immediate address)");
        check(mem_write,   1, "sw mem_write");
        check(result_src,  0, "sw result_src unused");
        check(alu_control, 0, "sw alu_control (add)");

        funct3 = 3'b000; #1;
        check(reg_write, 0, "sb reg_write (not implemented)");
        check(mem_write, 0, "sb mem_write (not implemented)");

        op = 7'b1111111; funct3 = 3'b010; #1;
        check(reg_write, 0, "unknown op reg_write");
        check(mem_write, 0, "unknown op mem_write");

        if (errors == 0) $display("control_test: ALL TESTS PASSED");
        else             $display("control_test: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule
