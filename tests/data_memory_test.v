`include "data_memory.v"
`timescale 1ns/1ps

module data_memory_test;
    reg         clk = 0, we = 0;
    reg  [31:0] address = 0, wd = 0;
    wire [31:0] rd;
    integer errors = 0;

    data_memory #(.INIT_FILE("tests/lw_data.hex")) dut (
        .clk(clk), .address(address), .write_data(wd), .write_enable(we), .read_data(rd));

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
        $dumpfile("build/data_memory_test.vcd");
        $dumpvars(0, data_memory_test);
        $display("== data_memory_test ==");

        address = 32'h0C; #1 check(rd, 32'hCAFEF00D, "read 0x0C");
        address = 32'h10; #1 check(rd, 32'hDEADBEEF, "read 0x10");
        address = 32'h14; #1 check(rd, 32'h12345678, "read 0x14");
        address = 32'h3C; #1 check(rd, 32'h00000000, "read 0x3C (unused)");

        // synchronous write, asynchronous read-back
        address = 32'h20; wd = 32'h0BADCAFE; we = 1;
        @(negedge clk);
        we = 0;
        #1 check(rd, 32'h0BADCAFE, "write then read 0x20");

        // no write while write_enable = 0
        address = 32'h24; wd = 32'hFFFFFFFF;
        @(negedge clk);
        #1 check(rd, 32'h00000000, "0x24 untouched (we=0)");

        if (errors == 0) $display("data_memory_test: ALL TESTS PASSED");
        else             $display("data_memory_test: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule
