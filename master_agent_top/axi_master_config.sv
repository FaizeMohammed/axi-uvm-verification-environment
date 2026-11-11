class axi_master_config extends uvm_object;
	`uvm_object_utils(axi_master_config)
	
	function new(string name="axi_master_config");
		super.new(name);
	endfunction
  
	virtual axi_if vif;
	uvm_active_passive_enum is_active;
endclass

