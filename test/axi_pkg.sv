package axi_pkg;
	import uvm_pkg::*;

         `include  "uvm_macros.svh"

	`include "axi_trans.sv"
	`include "axi_master_config.sv"
	`include "axi_slave_config.sv"
	`include "env_config.sv"

	`include "master_driver.sv"
	`include "master_monitor.sv"
	`include "master_sequencer.sv"
	`include "master_agent.sv"
	`include "master_agent_top.sv"

	`include "master_sequence.sv"

	`include "slave_driver.sv"
	`include "slave_monitor.sv"
	`include "slave_sequencer.sv"
	`include "slave_agent.sv"
	`include "slave_agent_top.sv"
	
	`include "slave_sequence.sv"

	`include "axi_sb.sv"
	

	`include "axi_env.sv"
	

	`include "test.sv"
	
endpackage

