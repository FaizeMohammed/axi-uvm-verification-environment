class slave_agent_top extends uvm_env;
	`uvm_component_utils(slave_agent_top)

	env_config env_cfg;
	slave_agent slave_agt[];

	function new(string name="slave_agent_top", uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		if(! uvm_config_db #(env_config)::get(this,"","env_config",env_cfg))
		`uvm_fatal(get_type_name(),"Have you set the config correctly?");

	slave_agt=new[env_cfg.no_of_slave];

	foreach(slave_agt[i])
		begin
		slave_agt[i]=slave_agent::type_id::create($sformatf("slave_agt[%0d]",i),this);
	uvm_config_db #(axi_slave_config)::set(this,$sformatf("slave_agt[%0d]*",i),"slave_config",env_cfg.slave_cfg[i]);
		end
	

	endfunction

	
		
endclass





