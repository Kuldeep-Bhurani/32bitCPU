`ifndef CONTROL_V
`define CONTROL_V
`timescale 1ns/1ps
// ---------------------------------------------------------------
// control.v : decoder for lw, sw, beq and R-type add / and / or
//
// Instruction | reg_write imm_src alu_src mem_write result_src alu_control
// ------------+----------------------------------------------------------
// lw          |    1       00(I)     1        0          1         000 ADD
// sw          |    0       01(S)     1        1          0         000 ADD
// add/and/or  |    1       00        0        0          0         000/010/011 (funct3 000/111/110, funct7=0)
// unsupported |    0       00        0        0          0         000
// ---------------------------------------------------------------
module control (
    input  wire [6:0] op,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg        reg_write,
    output reg  [1:0] imm_src,
    output reg        alu_src,        // 0: rs2, 1: immediate
    output reg        mem_write,
    output reg        result_src,     // 0: ALU result, 1: data memory
    output reg  [2:0] alu_control,
    output reg        branch
);

    localparam OP_LW = 7'b0000011;
    localparam OP_SW = 7'b0100011;
    localparam OP_R  = 7'b0110011;
    localparam OP_B  = 7'b1100011;

    reg [1:0] alu_op;                 // 00 : force ADD, 10 : R-type (decode funct3)

    // Main decoder: safe defaults make unsupported instructions no-ops.
    always @(*) begin
        reg_write  = 1'b0;
        imm_src    = 2'b00;
        alu_src    = 1'b0;
        mem_write  = 1'b0;
        result_src = 1'b0;
        branch     = 1'b0;
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
            OP_R: if (funct7 == 7'b0000000) begin
                reg_write  = 1'b1;
                alu_src    = 1'b0;    // rs2
                result_src = 1'b0;    // ALU result
                alu_op     = 2'b10;
            end
            OP_B: if (funct3 == 3'b000) begin
                imm_src    = 2'b10;   // B-type
                alu_src    = 1'b0;    // compare rs1 with rs2
                branch     = 1'b1;
            end
            default: ;
        endcase
    end

    // alu_op 00: ADD; 10: R-type selected by funct3; beq: SUB.
    always @(*) begin
        case (alu_op)
            2'b00:   alu_control = (op == OP_B && funct3 == 3'b000) ? 3'b001 : 3'b000;
            2'b10:   case (funct3)
                3'b000:  alu_control = 3'b000;   // add
                3'b111:  alu_control = 3'b010;   // and
                3'b110:  alu_control = 3'b011;   // or
                default: alu_control = 3'b000;
            endcase
            default: alu_control = 3'b000;
        endcase
    end

endmodule
`endif
