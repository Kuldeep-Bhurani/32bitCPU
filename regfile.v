`ifndef REGFILE_V
`define REGFILE_V
`timescale 1ns/1ps
// ---------------------------------------------------------------
// regfile.v : 32 x 32-bit RISC-V register file
//   - 2 asynchronous read ports (rs1 / rs2)
//   - 1 synchronous write port (rd), written on the rising clock edge
//   - x0 is hard-wired to zero (reads 0, writes are ignored)
//   - synchronous reset clears every register
// ---------------------------------------------------------------
module regfile (
    input  wire        clk,
    input  wire        rst,
    input  wire [4:0]  address1,      // rs1
    input  wire [4:0]  address2,      // rs2
    input  wire [4:0]  address3,      // rd
    input  wire        write_enable,
    input  wire [31:0] write_data,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);

    reg [31:0] registers [0:31];
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end else if (write_enable && (address3 != 5'b0)) begin
            registers[address3] <= write_data;
        end
    end

    assign read_data1 = (address1 == 5'b0) ? 32'b0 : registers[address1];
    assign read_data2 = (address2 == 5'b0) ? 32'b0 : registers[address2];

endmodule
`endif
