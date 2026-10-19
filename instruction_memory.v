`ifndef INSTRUCTION_MEMORY_V
`define INSTRUCTION_MEMORY_V
`timescale 1ns/1ps
// ---------------------------------------------------------------
// instruction_memory.v : word-addressed, read-only instruction ROM
//   - the input address is a BYTE address (the PC); the two LSBs are
//     dropped because instructions are 32-bit aligned
//   - content is loaded from a hex file (one 32-bit word per line)
//   - unused locations read as 0
// ---------------------------------------------------------------
module instruction_memory #(
    parameter ADDR_BITS = 6,          // 2**6 = 64 words
    parameter INIT_FILE = ""
) (
    input  wire [31:0] address,
    output wire [31:0] instruction
);

    localparam WORDS = 1 << ADDR_BITS;
    reg [31:0] mem [0:WORDS-1];
    integer i;

    initial begin
        for (i = 0; i < WORDS; i = i + 1)
            mem[i] = 32'b0;
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, mem);
    end

    assign instruction = mem[address[ADDR_BITS+1:2]];

endmodule
`endif
