---

## Project layout

```
8BitCPU/
├── main.v                  # top level: includes sub-modules and wires the datapath
├── regfile.v               # register file (x0 hard-wired to 0)
├── instruction_memory.v    # word-addressed ROM, loaded from a hex file
├── data_memory.v           # word-addressed RAM, loaded from a hex file
├── signext.v               # I-type and S-type immediate extractor / sign extender
├── alu.v                   # basic ALU (add / sub / and / or + zero flag)
├── control.v               # decoder / control unit for lw and sw
├── Makefile
└── tests/
    ├── regfile_test.v
    ├── instruction_memory_test.v
    ├── data_memory_test.v
    ├── signext_test.v
    ├── alu_test.v
    ├── control_test.v
    ├── main_test.v          # full-core lw regression test
    ├── sw_test.v            # full-core sw integration test
    ├── lw_program.hex
    ├── sw_program.hex
    └── lw_data.hex
```

Every `.v` file is wrapped in an include guard, so `main.v` pulls in the sub-parts and each testbench includes the module it tests.

## Datapath for `lw` and `sw`

For both instructions, the ALU calculates the effective address, `registers[rs1] + sign_extended_immediate`. For `lw`, data memory's asynchronous read feeds the write-back mux and the destination register is written on the rising clock edge. For `sw`, the register file's second read port supplies `registers[rs2]` to the data-memory write port, and the memory write enable is asserted on the rising clock edge.

Control signals:

| Instruction | Opcode | funct3 | reg_write | imm_src | alu_src | mem_write | result_src | ALU |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `lw` | `0000011` | `010` | 1 | `00` (I-type) | 1 (imm) | 0 | 1 (memory) | ADD |
| `sw` | `0100011` | `010` | 0 | `01` (S-type) | 1 (imm) | 1 | 0 (unused) | ADD |
| Unsupported instruction | — | — | 0 | `00` | 0 | 0 | 0 | ADD/default |

### `lw` behavior

For `lw x6, -4(x9)` (`0xFFC4A303`):

1. `instruction_memory` fetches the instruction from the current PC.
2. `control` recognizes opcode `0000011` with `funct3=010` and selects I-type immediate extraction.
3. `signext` sign-extends the 12-bit immediate `-4`.
4. The ALU adds the contents of `x9` and `-4` to form the byte address.
5. `data_memory` returns the addressed 32-bit word.
6. On the rising clock edge, the result is written to `x6` and the PC advances by four.

### `sw` behavior

For `sw x10, 12(x9)` (`0x00A4A623`):

1. `control` recognizes opcode `0100011` with `funct3=010` and selects the S-type immediate.
2. `signext` reconstructs the split immediate from `instruction[31:25]` and `instruction[11:7]`, then sign-extends it.
3. The ALU computes the byte address `x9 + 12`.
4. The value from register `x10` is placed on `data_memory.write_data`.
5. At the rising clock edge, the word is stored in data memory. No register is written (`reg_write=0`).

The two low address bits are ignored for memory indexing, so the current core supports aligned word accesses. Other load/store widths such as `lb`, `lh`, `sb`, and `sh` are not implemented and are treated as no-ops.

## Usage: building and testing

### Requirements

[Icarus Verilog](https://steveicarus.github.io/iverilog/) (`iverilog` + `vvp`), and optionally GTKWave to view waveforms.

```bash
sudo apt install iverilog gtkwave      # Debian / Ubuntu
```

### Build and test

Run everything from the repository root (the testbenches load `tests/*.hex` relative to it):

```bash
make                    # run all 8 testbenches
make main_test          # full-core lw regression test
make sw_test            # full-core sw test
make regfile_test       # or a single sub-part test
make cpu                # compile the full core (main.v)
make wave               # run main_test and open the waveform in GTKWave
make clean
```

Without `make`:

```bash
mkdir -p build
iverilog -g2012 -Wall -I. -o build/sw_test tests/sw_test.v
vvp build/sw_test
```

### Test program for `lw`

`tests/lw_program.hex` holds one 32-bit instruction per line. It checks positive and negative offsets, normal register writes, and that writes to `x0` are ignored. `tests/lw_data.hex` initializes data memory with known values for these cases.

### Test program for `sw`

`tests/sw_program.hex` exercises both positive-offset stores and a zero-offset store, with data loaded into source registers first. The integration test checks the stored words directly in the data-memory array after execution and confirms the PC advances as expected.

For `sw rs2, imm(rs1)`, the S-type encoding is:

```text
imm[11:5] | rs2 | rs1 | 010 | imm[4:0] | 0100011
```

Example: `sw x10, 12(x9)` encodes as `0x00A4A623`. Use byte addresses; the low two address bits are ignored for word indexing. Memory writes are synchronous, so check stored values after the relevant rising clock edge.

Both memories are 64 words (256 bytes) by default. Hex files are read from the current working directory, so run the commands above from the repository root.

## Validation note

The RTL and instruction encodings were validated with Icarus Verilog 11.0.

The full regression suite was run locally on Windows using Icarus Verilog and VVP. All 8 testbenches passed:

- `regfile_test`
- `instruction_memory_test`
- `data_memory_test`
- `signext_test`
- `alu_test`
- `control_test`
- `main_test`
- `sw_test`

The `sw_test` integration test specifically verifies all three `sw` instructions, including S-type immediate handling, effective-address calculation, memory writes, preservation of `x0`, and sequential PC behavior.

