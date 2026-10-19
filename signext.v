`ifndef SIGNEXT_V
`define SIGNEXT_V
`timescale 1ns/1ps
// ---------------------------------------------------------------
// signext.v : immediate extractor / sign extender
//   imm_src 2'b00 : I-type  imm[11:0] = instr[31:20]
//   (other encodings are reserved for S/B/J/U types later on)
// ---------------------------------------------------------------
module signext (
    input  wire [31:7] raw_src,       // instruction[31:7]
    input  wire [1:0]  imm_src,
    output reg  [31:0] immediate
);

    always @(*) begin
        case (imm_src)
            2'b00:   immediate = {{20{raw_src[31]}}, raw_src[31:20]};  // I-type
            default: immediate = 32'b0;
        endcase
    end

endmodule
`endif
