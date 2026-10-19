`include "instruction_memory.v"
`timescale 1ns/1ps

module instruction_memory_test;
    reg  [31:0] address = 0;
    wire [31:0] instruction;
    integer errors = 0;

    instruction_memory #(.INIT_FILE("tests/lw_program.hex")) dut (
        .address(address), .instruction(instruction));

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
        $dumpfile("build/instruction_memory_test.vcd");
        $dumpvars(0, instruction_memory_test);
        $display("== instruction_memory_test ==");

        address = 32'h00; #1 check(instruction, 32'h00802483, "pc=0x00");
        address = 32'h04; #1 check(instruction, 32'hFFC4A303, "pc=0x04");
        address = 32'h08; #1 check(instruction, 32'h0004A383, "pc=0x08");
        address = 32'h10; #1 check(instruction, 32'h0044A503, "pc=0x10");
        address = 32'h14; #1 check(instruction, 32'h00000000, "pc=0x14 (empty)");
        address = 32'h05; #1 check(instruction, 32'hFFC4A303, "pc=0x05 (low bits ignored)");

        if (errors == 0) $display("instruction_memory_test: ALL TESTS PASSED");
        else             $display("instruction_memory_test: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule
