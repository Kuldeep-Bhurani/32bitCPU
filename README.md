
---

## Project layout

```
8BitCPU/
├── main.v                  # top level: `include`s every sub-module and wires the datapath
├── regfile.v               # register file (x0 hard-wired to 0)
├── instruction_memory.v    # word-addressed ROM, loaded from a hex file
├── data_memory.v           # word-addressed RAM, loaded from a hex file
├── signext.v               # immediate extractor / sign extender
├── alu.v                   # basic ALU (add / sub / and / or + zero flag)
├── control.v               # decoder / control unit
├── Makefile
└── tests/
    ├── regfile_test.v
    ├── instruction_memory_test.v
    ├── data_memory_test.v
    ├── signext_test.v
    ├── alu_test.v
    ├── control_test.v
    ├── main_test.v         # runs a real lw program on the whole core
    ├── lw_program.hex      # instruction memory image used by the tests
    └── lw_data.hex         # data memory image used by the tests
```

Every `.v` file is wrapped in an include guard, so `main.v` pulls in all sub-parts
and each testbench only includes what it tests.

## Datapath for `lw`

```
            +-----+  instr   +---------+ rs1 +----------+  src1  +-----+ addr  +------+
 PC ------->|imem |--------->| decode  |---->| regfile  |------->|     |------>| dmem |
 ^          +-----+          | control |     |          | src2   | ALU |       +------+
 |                           +---------+     +----------+   +--->|     |          |
 +-- PC + 4                    imm_src |          ^          |    +-----+          |
                                       v          |      alu_src                   |
                                  +---------+     |  (imm) --+                     |
                                  | signext |-----+--------------                  |
                                  +---------+     +---- write-back (result_src) <--+
```

Control signals generated for `lw` (opcode `0000011`, funct3 `010`):

| reg_write | imm_src | alu_src | mem_write | result_src | alu_control |
| --------- | ------- | ------- | --------- | ---------- | ----------- |
| 1         | 00 (I)  | 1 (imm) | 0         | 1 (memory) | 000 (add)   |

What happens in the single cycle for `lw x6, -4(x9)` (`0xFFC4A303`):

1. `instruction_memory` fetches the word at `pc`.
2. `control` sees `op = 0000011`, `funct3 = 010` and raises `reg_write`, `alu_src`, `result_src`.
3. `regfile` reads `x9`; `signext` turns `111111111100` into `0xFFFFFFFC` (-4).
4. `alu` adds them: `address = x9 + (-4)`.
5. `data_memory` returns the word at that address (the two low address bits are ignored, `lw` is word-aligned).
6. On the next rising clock edge the word is written into `x6` and `pc` becomes `pc + 4`.

Writes to `x0` are ignored, and loads with any other funct3 (`lb`, `lh`, `lbu`, `lhu`) are
treated as no-ops until they are implemented.

## Usage: running `lw`

### Requirements

[Icarus Verilog](https://steveicarus.github.io/iverilog/) (`iverilog` + `vvp`), and optionally GTKWave to view waveforms.

```bash
sudo apt install iverilog gtkwave      # Debian / Ubuntu
```

### Build and test

Run everything from the repository root (the testbenches load `tests/*.hex` relative to it):

```bash
make                    # run all 7 testbenches
make main_test          # full-core lw test only
make regfile_test       # or any single sub-part: alu_test, control_test, signext_test, ...
make cpu                # just compile the full core (main.v)
make wave               # run main_test and open the waveform in GTKWave
make clean
```

Without `make`:

```bash
mkdir -p build
iverilog -g2012 -Wall -I. -o build/main_test tests/main_test.v
vvp build/main_test
```

Expected `main_test` output:

```
== main_test (lw) ==
  [t=25000] pc=00000000 instr=00802483
  [t=35000] pc=00000004 instr=ffc4a303
  [t=45000] pc=00000008 instr=0004a383
  [t=55000] pc=0000000c instr=0004a003
  [t=65000] pc=00000010 instr=0044a503
  PASS x9  <- lw x9, 8(x0) = 00000010
  PASS x6  <- lw x6, -4(x9) = cafef00d
  PASS x7  <- lw x7, 0(x9) = deadbeef
  PASS x0 ignored lw x0, 0(x9) = 00000000
  PASS x10 <- lw x10, 4(x9) = 12345678
  PASS pc after 5 instructions = 00000014
main_test: ALL TESTS PASSED
```

### The test program

`tests/lw_program.hex` holds one 32-bit instruction per line (hex, `//` comments allowed):

```
00802483 // 0x00: lw x9,  8(x0)   -> x9 = mem[0x08] = 0x10 (a pointer)
FFC4A303 // 0x04: lw x6, -4(x9)   -> x6 = mem[0x0C]  (the README example)
0004A383 // 0x08: lw x7,  0(x9)   -> x7 = mem[0x10]
0004A003 // 0x0C: lw x0,  0(x9)   -> must NOT change x0
0044A503 // 0x10: lw x10, 4(x9)   -> x10 = mem[0x14]
```

`tests/lw_data.hex` is the data memory it reads from:

```
AAAAAAAA // 0x00
BBBBBBBB // 0x04
00000010 // 0x08  pointer used as base address
CAFEF00D // 0x0C
DEADBEEF // 0x10
12345678 // 0x14
```

Since `lw` is the only instruction so far, the program first loads a pointer into `x9`
and then uses it as the base register, no `addi` needed.

### Running your own `lw` program

1. Encode your instruction as I-type: `imm[11:0] | rs1 | 010 | rd | 0000011`
   (e.g. `lw x6, -4(x9)` is `111111111100 01001 010 00110 0000011` = `0xFFC4A303`).
2. Put the words in a hex file, and the data you want to read in another.
3. Point the core at them with the `IMEM_FILE` / `DMEM_FILE` parameters:

```verilog
main #(.IMEM_FILE("my_program.hex"),
       .DMEM_FILE("my_data.hex")) cpu (.clk(clk), .rst(rst));
```

4. Hold `rst` high for a couple of clock cycles, release it, and the core executes one
   instruction per clock cycle starting at address `0x0`.

Both memories are 64 words (256 bytes) by default; change the `ADDR_BITS` parameter of
`instruction_memory` / `data_memory` for more. Hex files end with an `@3F 00000000` line
only so iverilog doesn't warn about a partially filled memory.
