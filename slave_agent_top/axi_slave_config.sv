class axi_slave_config extends uvm_object;
	`uvm_object_utils(axi_slave_config)
	

	function new(string name="axi_slave_config");
		super.new(name);
	endfunction

	virtual axi_if vif;
	uvm_active_passive_enum is_active;
endclass

