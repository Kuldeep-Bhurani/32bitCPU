`ifndef DATA_MEMORY_V
`define DATA_MEMORY_V
`timescale 1ns/1ps
// ---------------------------------------------------------------
// data_memory.v : word-addressed data RAM
//   - asynchronous read
//   - synchronous write 
//   - input address is a BYTE address, the two LSBs are dropped
//   - content is loaded from a hex file (one 32-bit word per line)
// ---------------------------------------------------------------
module data_memory #(
    parameter ADDR_BITS = 6,          // 2**6 = 64 words
    parameter INIT_FILE = ""
) (
    input  wire        clk,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    input  wire        write_enable,
    output wire [31:0] read_data
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

    always @(posedge clk) begin
        if (write_enable)
            mem[address[ADDR_BITS+1:2]] <= write_data;
    end

    assign read_data = mem[address[ADDR_BITS+1:2]];

endmodule
`endif
