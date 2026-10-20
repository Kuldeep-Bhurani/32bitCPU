`ifndef SIGNEXT_V
`define SIGNEXT_V
`timescale 1ns/1ps
// ---------------------------------------------------------------
// signext.v : I-type and S-type immediate extraction / sign extension
//   imm_src 2'b00 : I-type, imm[11:0] = instr[31:20]
//   imm_src 2'b01 : S-type, imm[11:5] = instr[31:25], imm[4:0] = instr[11:7]
//   imm_src 2'b10 : B-type, branch offset with implicit low zero bit
// ---------------------------------------------------------------
module signext (
    input  wire [31:7] raw_src,       // instruction[31:7]
    input  wire [1:0]  imm_src,
    output reg  [31:0] immediate
);

    always @(*) begin
        case (imm_src)
            2'b00:   immediate = {{20{raw_src[31]}}, raw_src[31:20]}; // I-type
            2'b01:   immediate = {{20{raw_src[31]}}, raw_src[31:25], raw_src[11:7]}; // S-type
            2'b10:   immediate = {{19{raw_src[31]}}, raw_src[31], raw_src[7], raw_src[30:25], raw_src[11:8], 1'b0}; // B-type
            default: immediate = 32'b0;
        endcase
    end

endmodule
`endif
