`ifndef CONTROL_V
`define CONTROL_V
`timescale 1ns/1ps
// ---------------------------------------------------------------
// control.v : decoder / control unit (lw only for now)
//
//   instruction | reg_write imm_src alu_src mem_write result_src alu_control
//   ------------+----------------------------------------------------------
//   lw          |    1       00       1        0          1         000 (add)
//   anything    |    0       00       0        0          0         000
//   else
//
//   lw is opcode 0000011 AND funct3 010 (other funct3 = lb/lh/lbu/lhu,
//   not implemented yet, so they are treated as no-ops).
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

    reg [1:0] alu_op;                 // 00 : force ADD

    // ---- main decoder ----
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
                imm_src    = 2'b00;
                alu_src    = 1'b1;
                mem_write  = 1'b0;
                result_src = 1'b1;
                alu_op     = 2'b00;
            end
            default: ;
        endcase
    end

    // ---- ALU decoder ----
    always @(*) begin
        case (alu_op)
            2'b00:   alu_control = 3'b000;   // ADD
            default: alu_control = 3'b000;
        endcase
    end

endmodule
`endif
