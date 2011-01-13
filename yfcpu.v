module yfcpu(clk, rst, PC_out);

// our cpu core parameters
parameter im_size = 8;		// 2^n instruction word memory
parameter rf_size = 4;		// 2^n word register file

input clk;	// our system clock
output reg [ im_size-1 : 0 ] PC_out;	// our program counter
input rst;	// reset signal

// the cycle states of our cpu, i.e. the Control Unit states
parameter s_fetch = 2'b00;	// fetch next instruction from memory
parameter s_decode = 2'b01;	// decode instruction into opcode and operands
parameter s_execute = 2'b10;	// execute the instruction inside the ALU
parameter s_store = 2'b11;	// store the result back to memory

// the parts of our instruction word
parameter opcode_size = 4;		// size of opcode in bits

// our mnemonic op codes
parameter LRI  = 4'b0001;
parameter ADD  = 4'b0100;
parameter OR   = 4'b0110;
parameter XOR  = 4'b0111;
parameter HALT = 4'b0000;

// mnemonic register names
parameter PC = 4'd15;

// our memory core consisting of Instruction Memory, Register File and an ALU working (W) register
reg [ opcode_size + (rf_size*3) -1 : 0 ] IMEM[0: 2 ** im_size -1 ] ;	// instruction memory
reg [ 7:0 ] REGFILE[0: 2 ** rf_size -1 ];	// data memory
reg [ 7:0 ] W;	// working (intermediate) register

// our cpu core registers
reg [ opcode_size + (rf_size*3) -1 : 0 ] IR;	// instruction register

/* Control Unit registers
     The control unit sequencer cycles through fetching the next instruction
     from memory, decoding the instruction into the opcode and operands and
     executing the opcode in the ALU.
*/
reg [ 1:0 ] current_state;
reg [ 1:0 ] next_state;

// our instruction registers
// an opcode typically loads registers addressed from RA and RB, and stores
// the result into destination register RD. RA:RB can also be used to form
// an 8bit immediate (literal) value.
reg [ opcode_size-1 : 0 ] OPCODE;
reg [ rf_size-1 : 0 ] RA;   // left operand register address
reg [ rf_size-1 : 0 ] RB;   // right operand register address
reg [ rf_size-1 : 0 ] RD;   // destination register


// the initial cpu state bootstrap
initial begin
	REGFILE[PC] = 0;
	current_state = s_fetch;

	// initialize our instruction memory with a test program
	// IMEM[n] = { OPCODE, RA, RB, RD };
	IMEM[0] = { LRI , 4'd0, 4'd0, 4'd0 };   // clear R1, R2, R3
	IMEM[1] = { LRI , 4'd2, 4'd4, 4'd1 };   // load immediate into R1
	IMEM[2] = { LRI , 4'd1, 4'd11, 4'd2 };  // load immediate into R2
	IMEM[3] = { ADD , 4'd1, 4'd2, 4'd3 };   // add R1 + R2, into R3
	IMEM[4] = { XOR , 4'd2, 4'd3, 4'd4 };   // or R2 & R3 into R4
	IMEM[5] = { OR  , 4'd2, 4'd1, 4'd0 };   // or R2 & R1 into R0
	IMEM[6] = { LRI , 4'd0, 4'd0, 4'd15 };   // load immediate into R1
	IMEM[7] = { HALT, 12'd0 };  // end program
	end

// at each clock cycle we sequence the Control Unit, or if rst is
// asserted we keep the cpu in reset.
always @ (clk, rst)
begin
	if(rst) begin
		current_state = s_fetch;
		REGFILE[PC] = 0;
		PC_out = 0;
		end
	else
	   begin
	   // sequence our Control Unit
		case( current_state )
			s_fetch: begin
			    // fetch instruction from instruction memory
				IR = IMEM[ REGFILE[PC] ];
				next_state = s_decode;
				end

			s_decode: begin
			   // PC can be incremented as current instruction is loaded into IR
				REGFILE[PC] = REGFILE[PC] + 1;
				PC_out = REGFILE[PC];
				next_state = s_execute;
				
				// decode the opcode and register operands
				OPCODE = IR[ opcode_size + (rf_size*3) -1 : (rf_size*3) ];
				RA = IR[ (rf_size*3) -1 : (rf_size*2) ];
				RB = IR[ (rf_size*2) -1 : (rf_size  ) ];
				RD = IR[ (rf_size  ) -1 : 0 ];
				end

			s_execute: begin
			   // Execute ALU instruction, process the OPCODE
				case (OPCODE)
					LRI: begin	
					   // load register RD with immediate from RA:RB operands
					   W = {RA, RB};
					   next_state = s_store;
					   end
					   
					ADD: begin	
					   // Add RA + RB
						W = REGFILE[RA] + REGFILE[RB];
						next_state = s_store;
						end
						
					OR: begin	
					   // OR RA + RB
						W = REGFILE[RA] | REGFILE[RB];
						next_state = s_store;
						end
						
					XOR: begin	
					   // Exclusive OR RA ^ RB
						W = REGFILE[RA] ^ REGFILE[RB];
						next_state = s_store;
						end
						
					HALT: begin
					   // Halt execution, loop indefinately
						next_state = s_execute;
						end
						
					// catch all
					default: begin end
				endcase
				end
			
			s_store: begin
			   // store the ALU working register into the destination register RD
				REGFILE[RD] = W;
				next_state = s_fetch;
				end
			
         // invalid state!
			default: begin end
		endcase

      // move the control unit to the next state
		current_state = next_state;
	end
end

endmodule
