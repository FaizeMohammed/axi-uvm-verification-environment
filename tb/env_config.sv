class env_config extends uvm_object;
	`uvm_object_utils(env_config)
	
	axi_master_config master_cfg[];
	axi_slave_config slave_cfg[];
	
	int no_of_master;
	int no_of_slave;
	
function new(string name="env_config");
		super.new(name);
	endfunction

endclass

