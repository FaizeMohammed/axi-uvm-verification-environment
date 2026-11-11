module top;


import axi_pkg::*;
import uvm_pkg::*;

`include "uvm_macros.svh"

 bit clk;
initial begin
		clk = 0;
	end
	always #10 clk=~clk;
	
	
	axi_if in0(clk);


	initial
		begin
	
		uvm_config_db#(virtual axi_if)::set(null,"*","axi_if",in0);
	
		run_test();
		end
endmodule

