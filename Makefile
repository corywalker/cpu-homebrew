test_bser:
	iverilog yfcpu.v testbench.v
	python asm.py prog.py
	xxd -p prog.o | sed 's/..../& /g' > prog.hex
	./a.out
	gtkwave dump.vcd
	rm -f a.out dump.vcd
