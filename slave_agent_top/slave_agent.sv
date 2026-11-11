class slave_agent extends uvm_agent;
	`uvm_component_utils(slave_agent)
	
slave_driver drv;
slave_monitor mon;
slave_sequencer seqrh;
axi_slave_config slave_cfg;

	function new(string name="slave_agent",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
			super.build_phase(phase);

		mon=slave_monitor::type_id::create("mon",this);

	if(!uvm_config_db#(axi_slave_config)::get(this,"","slave_config",slave_cfg))
		`uvm_fatal(get_type_name(),"Have you set the config correctly?");

	if(slave_cfg.is_active==UVM_ACTIVE)
		begin
			drv=slave_driver::type_id::create("drv",this);
			seqrh=slave_sequencer::type_id::create("seqrh",this);
		end
	endfunction

	function void connect_phase(uvm_phase phase);
			super.connect_phase(phase);

		if(slave_cfg.is_active==UVM_ACTIVE)
		begin
			drv.seq_item_port.connect(seqrh.seq_item_export);
		end
	endfunction
endclass


