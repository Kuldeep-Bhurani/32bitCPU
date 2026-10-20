`ifndef ALU_V
`define ALU_V
`timescale 1ns/1ps
// ---------------------------------------------------------------
// alu.v : basic ALU
//   alu_control 000 : ADD   (lw/sw address = rs1 + imm, R-type add)
//               001 : SUB
//               010 : AND  (R-type and)
//               011 : OR   (R-type or)
// ---------------------------------------------------------------
module alu (
    input  wire [31:0] src1,
    input  wire [31:0] src2,
    input  wire [2:0]  alu_control,
    output reg  [31:0] alu_result,
    output wire        zero
);

    always @(*) begin
        case (alu_control)
            3'b000:  alu_result = src1 + src2;
            3'b001:  alu_result = src1 - src2;
            3'b010:  alu_result = src1 & src2;
            3'b011:  alu_result = src1 | src2;
            default: alu_result = 32'b0;
        endcase
    end

    assign zero = (alu_result == 32'b0);

endmodule
`endif
