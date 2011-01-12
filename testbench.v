
// ============================================================================
// TESTBENCH FOR CPU CORE
// ============================================================================

module tb ();

reg clk, rst;
wire [7:0] pc;

yfcpu mycpu (
	clk, rst, pc
);

initial begin
	clk = 1;
	rst = 1;
	#1 rst = 0;
	#1300 rst = 0;
	$stop;
end

always clk = #1 ~clk;

endmodule
