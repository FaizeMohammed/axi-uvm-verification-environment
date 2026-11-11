class master_agent extends uvm_agent;
	`uvm_component_utils(master_agent)
	
master_driver drv; 
master_monitor mon;
master_sequencer seqrh;
axi_master_config master_cfg;

	function new(string name="master_agent",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		mon=master_monitor::type_id::create("mon",this);

	if(!uvm_config_db#(axi_master_config)::get(this,"","master_config",master_cfg))
		`uvm_fatal(get_type_name(),"Have you set the config correctly?");

	if(master_cfg.is_active==UVM_ACTIVE)
		begin
			drv=master_driver::type_id::create("drv",this);
			seqrh=master_sequencer::type_id::create("seqrh",this);
		end
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);

		if(master_cfg.is_active==UVM_ACTIVE)
		begin
			drv.seq_item_port.connect(seqrh.seq_item_export);
		end
	endfunction
endclass


