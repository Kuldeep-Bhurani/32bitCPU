`ifndef MAIN_V
`define MAIN_V
// ---------------------------------------------------------------
// main.v : single-cycle RISC-V core
//
//          +----+   +--------+   +---------+   +-----+   +--------+
//   PC --->|imem|-->| decode |-->| regfile |-->| ALU |-->|  dmem  |--+
//    ^     +----+   | control|   +---------+   +-----+   +--------+  |
//    |              +--------+       ^  signext--^                    |
//    +-- pc+4                        +------ result mux <-------------+
// ---------------------------------------------------------------
`include "regfile.v"
`include "instruction_memory.v"
`include "data_memory.v"
`include "signext.v"
`include "alu.v"
`include "control.v"

`timescale 1ns/1ps

module main #(
    parameter IMEM_FILE = "",
    parameter DMEM_FILE = ""
) (
    input wire clk,
    input wire rst
);

    // ---------------- program counter ----------------
    reg  [31:0] pc;
    wire [31:0] pc_plus4 = pc + 32'd4;

    // ---------------- fetch ----------------
    wire [31:0] instruction;

    instruction_memory #(.INIT_FILE(IMEM_FILE)) imem (
        .address     (pc),
        .instruction (instruction)
    );

    // ---------------- decode ----------------
    wire [6:0] op     = instruction[6:0];
    wire [6:0] funct7 = instruction[31:25];
    wire [4:0] rd     = instruction[11:7];
    wire [2:0] funct3 = instruction[14:12];
    wire [4:0] rs1    = instruction[19:15];
    wire [4:0] rs2    = instruction[24:20];

    wire       reg_write, alu_src, mem_write, result_src, branch;
    wire [1:0] imm_src;
    wire [2:0] alu_control;

    control ctrl (
        .op          (op),
        .funct3      (funct3),
        .funct7      (funct7),
        .reg_write   (reg_write),
        .imm_src     (imm_src),
        .alu_src     (alu_src),
        .mem_write   (mem_write),
        .result_src  (result_src),
        .alu_control (alu_control),
        .branch      (branch)
    );

    wire [31:0] read_data1, read_data2, immediate;
    wire [31:0] result;               // value written back to rd

    regfile regfile_inst (
        .clk          (clk),
        .rst          (rst),
        .address1     (rs1),
        .address2     (rs2),
        .address3     (rd),
        .write_enable (reg_write),
        .write_data   (result),
        .read_data1   (read_data1),
        .read_data2   (read_data2)
    );

    signext signext_inst (
        .raw_src   (instruction[31:7]),
        .imm_src   (imm_src),
        .immediate (immediate)
    );

    // ---------------- execute ----------------
    wire [31:0] alu_src2 = alu_src ? immediate : read_data2;
    wire [31:0] alu_result;
    wire        zero;

    alu alu_inst (
        .src1        (read_data1),
        .src2        (alu_src2),
        .alu_control (alu_control),
        .alu_result  (alu_result),
        .zero        (zero)
    );

    wire [31:0] pc_next = (branch && zero) ? pc + immediate : pc_plus4;

    always @(posedge clk) begin
        if (rst) pc <= 32'b0;
        else     pc <= pc_next;
    end

    // ---------------- memory / write-back ----------------
    wire [31:0] mem_read_data;

    data_memory #(.INIT_FILE(DMEM_FILE)) dmem (
        .clk          (clk),
        .address      (alu_result),
        .write_data   (read_data2),
        .write_enable (mem_write),
        .read_data    (mem_read_data)
    );

    assign result = result_src ? mem_read_data : alu_result;

endmodule
`endif
