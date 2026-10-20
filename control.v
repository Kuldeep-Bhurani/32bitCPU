`ifndef CONTROL_V
`define CONTROL_V
`timescale 1ns/1ps
// ---------------------------------------------------------------
// control.v : decoder for the implemented lw and sw instructions
//
// Instruction | reg_write imm_src alu_src mem_write result_src alu_control
// ------------+----------------------------------------------------------
// lw          |    1       00(I)     1        0          1         000 ADD
// sw          |    0       01(S)     1        1          0         000 ADD
// unsupported |    0       00        0        0          0         000
// ---------------------------------------------------------------
module control (
    input  wire [6:0] op,
    input  wire [2:0] funct3,
    output reg        reg_write,
    output reg  [1:0] imm_src,
    output reg        alu_src,        // 0: rs2, 1: immediate
    output reg        mem_write,
    output reg        result_src,     // 0: ALU result, 1: data memory
    output reg  [2:0] alu_control
);

    localparam OP_LW = 7'b0000011;
    localparam OP_SW = 7'b0100011;

    reg [1:0] alu_op;                 // 00 : force ADD

    // Main decoder: safe defaults make unsupported instructions no-ops.
    always @(*) begin
        reg_write  = 1'b0;
        imm_src    = 2'b00;
        alu_src    = 1'b0;
        mem_write  = 1'b0;
        result_src = 1'b0;
        alu_op     = 2'b00;

        case (op)
            OP_LW: if (funct3 == 3'b010) begin
                reg_write  = 1'b1;
                imm_src    = 2'b00;   // I-type
                alu_src    = 1'b1;
                result_src = 1'b1;
            end
            OP_SW: if (funct3 == 3'b010) begin
                reg_write  = 1'b0;
                imm_src    = 2'b01;   // S-type
                alu_src    = 1'b1;
                mem_write  = 1'b1;
                result_src = 1'b0;
            end
            default: ;
        endcase
    end

    // lw/sw effective addresses use ADD.
    always @(*) begin
        case (alu_op)
            2'b00:   alu_control = 3'b000;   // ADD
            default: alu_control = 3'b000;
        endcase
    end

endmodule
`endif
