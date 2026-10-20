IVERILOG = iverilog -g2012 -Wall -I.
TESTS    = regfile_test instruction_memory_test data_memory_test \
           signext_test alu_test control_test main_test sw_test

.PHONY: all cpu wave clean $(TESTS)

all: $(TESTS)

build:
	mkdir -p build

cpu: build
	$(IVERILOG) -o build/cpu main.v

$(TESTS): %: build
	$(IVERILOG) -o build/$@ tests/$@.v
	vvp build/$@

wave: main_test
	gtkwave build/main_test.vcd

clean:
	rm -rf build
