test_bser:
	iverilog yfcpu.v testbench.v
	./a.out
	gtkwave dump.vcd
	rm -f a.out dump.vcd
