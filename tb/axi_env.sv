class axi_env extends uvm_env;
	`uvm_component_utils(axi_env)
	
	master_agent_top master_top;
	slave_agent_top slave_top;
	axi_sb sb;
	env_config env_cfg;

	function new(string name="axi_env",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
	
	if(!uvm_config_db#(env_config)::get(this,"","env_config",env_cfg))
	`uvm_fatal(get_type_name(),"Have you set the config correctly?");

master_top=master_agent_top::type_id::create("master_top",this);
slave_top=slave_agent_top::type_id::create("slave_top",this);
	
		sb=axi_sb::type_id::create("sb",this);
	
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);

		foreach(master_top.master_agt[i])
			master_top.master_agt[i].mon.monitor_port.connect(sb.fifo_master_m[i].analysis_export);


		foreach(slave_top.slave_agt[i])
			slave_top.slave_agt[i].mon.monitor_port.connect(sb.fifo_slave_m[i].analysis_export);

	endfunction	

endclass

