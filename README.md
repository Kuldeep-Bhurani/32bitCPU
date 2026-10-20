# 8bitcpu

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
├── control.v               # decoder / control unit for lw, sw and R-type add/and/or
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
    ├── r_type_test.v        # full-core R-type add/and/or test
    ├── r_program.hex
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

## R-type instructions: `add`, `and`, `or`

R-type ops read `rs1` and `rs2`, send them to the ALU (`alu_src=0`), and write the ALU result to `rd` (`result_src=0`, `reg_write=1`). `control` now takes `funct7` (`instruction[31:25]`) and decodes only `funct7=0000000`; other encodings (e.g. `sub`) are no-ops.

| Instruction | Opcode | funct3 | funct7 | ALU control |
| --- | --- | --- | --- | --- |
| `add rd, rs1, rs2` | `0110011` | `000` | `0000000` | `000` ADD |
| `and rd, rs1, rs2` | `0110011` | `111` | `0000000` | `010` AND |
| `or rd, rs1, rs2` | `0110011` | `110` | `0000000` | `011` OR |

Encoding: `funct7 | rs2 | rs1 | funct3 | rd | 0110011`. Examples: `add x7, x5, x6` = `0x006283B3`, `and x8, x5, x6` = `0x0062F433`, `or x9, x5, x6` = `0x0062E4B3`.

Usage: put the encoded words in a hex file (one per line, first load operands with `lw`), e.g. `tests/r_program.hex`, and run `make r_type_test`. With `x5=0xAAAAAAAA`, `x6=0xCAFEF00D` it checks `x7=0x75A99AB7` (add), `x8=0x8AAAA008` (and), `x9=0xEAFEFAAF` (or), a chained `and x10,x7,x9`=`0x60A89AA7`, and that `add x0,...` leaves `x0` at 0. `alu_test` and `control_test` also cover the new paths.

## Usage: building and testing

### Requirements

[Icarus Verilog](https://steveicarus.github.io/iverilog/) (`iverilog` + `vvp`), and optionally GTKWave to view waveforms.

```bash
sudo apt install iverilog gtkwave      # Debian / Ubuntu
```

### Build and test

Run everything from the repository root (the testbenches load `tests/*.hex` relative to it):

```bash
make                    # run all 9 testbenches
make main_test          # full-core lw regression test
make sw_test            # full-core sw test
make r_type_test        # full-core add/and/or test
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

- `regfile_test`
- `instruction_memory_test`
- `data_memory_test`
- `signext_test`
- `alu_test`
- `control_test`
- `main_test`
- `sw_test`

The `sw_test` integration test specifically verifies all three `sw` instructions, including S-type immediate handling, effective-address calculation, memory writes, preservation of `x0`, and sequential PC behavior.

