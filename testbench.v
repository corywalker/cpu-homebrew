
// ============================================================================
// TESTBENCH FOR CPU CORE
// ============================================================================

module tb ();

reg clk, rst;
wire [15:0] p1;
reg [15:0] p2;
wire [15:0] pc;

yfcpu mycpu (
	clk, rst, p1, p2, pc
);

initial begin
	$dumpvars(1, mycpu);
	clk = 1;
	rst = 1;
	p2 = 16'd0;
	#1 rst = 0;
	#1300 $finish;
end

always clk = #1 ~clk;

endmodule
