`include "regfile.v"
`timescale 1ns/1ps

module regfile_test;
    reg         clk = 0, rst = 1, we = 0;
    reg  [4:0]  a1 = 0, a2 = 0, a3 = 0;
    reg  [31:0] wd = 0;
    wire [31:0] rd1, rd2;
    integer errors = 0;

    regfile dut (.clk(clk), .rst(rst), .address1(a1), .address2(a2), .address3(a3),
                 .write_enable(we), .write_data(wd), .read_data1(rd1), .read_data2(rd2));

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
        $dumpfile("build/regfile_test.vcd");
        $dumpvars(0, regfile_test);
        $display("== regfile_test ==");

        repeat (2) @(negedge clk);
        rst = 0;

        // write x5, read it back on port 1
        a3 = 5; wd = 32'hA5A5A5A5; we = 1;
        @(negedge clk);
        we = 0; a1 = 5;
        #1 check(rd1, 32'hA5A5A5A5, "x5 on port1");

        // write x31, read both ports at once
        a3 = 31; wd = 32'h0000FFFF; we = 1;
        @(negedge clk);
        we = 0; a1 = 5; a2 = 31;
        #1 check(rd1, 32'hA5A5A5A5, "x5 on port1 (dual)");
        check(rd2, 32'h0000FFFF, "x31 on port2");

        // x0 is hard-wired to zero
        a3 = 0; wd = 32'hFFFFFFFF; we = 1;
        @(negedge clk);
        we = 0; a1 = 0; a2 = 0;
        #1 check(rd1, 32'h0, "x0 port1");
        check(rd2, 32'h0, "x0 port2");

        // write_enable low must not write
        a3 = 7; wd = 32'h12345678; we = 0;
        @(negedge clk);
        a1 = 7;
        #1 check(rd1, 32'h0, "x7 untouched (we=0)");

        // reset clears everything
        rst = 1;
        @(negedge clk);
        rst = 0; a1 = 5; a2 = 31;
        #1 check(rd1, 32'h0, "x5 after reset");
        check(rd2, 32'h0, "x31 after reset");

        if (errors == 0) $display("regfile_test: ALL TESTS PASSED");
        else             $display("regfile_test: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule
