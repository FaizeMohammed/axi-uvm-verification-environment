class test extends uvm_test;
	`uvm_component_utils(test)

	axi_env env_h; 
	env_config env_cfg;
	axi_master_config master_cfg[];
	axi_slave_config slave_cfg[];

	int no_of_master=1;
	int no_of_slave=1;

	function new(string name="test",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void config_test();
		master_cfg =new[no_of_master];
		slave_cfg =new[no_of_slave];

	foreach(master_cfg[i])
		begin
						master_cfg[i]=axi_master_config::type_id::create($sformatf("master_cfg[%0d]",i));

		if(!uvm_config_db#(virtual axi_if)::get(this,"","axi_if",master_cfg[i].vif))
	`uvm_fatal(get_type_name(),"Have u set config correctly?");

	master_cfg[i].is_active=UVM_ACTIVE;
		
		end
foreach(slave_cfg[i])
		begin
			slave_cfg[i]=axi_slave_config::type_id::create($sformatf("slave_cfg[%0d]",i));

		if(!uvm_config_db#(virtual axi_if)::get(this,"","axi_if",slave_cfg[i].vif))
	`uvm_fatal(get_type_name(),"Have u set slave config correctly?");

	slave_cfg[i].is_active=UVM_ACTIVE;
		
		end

		env_cfg.master_cfg = master_cfg;
		env_cfg.slave_cfg = slave_cfg;
		env_cfg.no_of_master = no_of_master;
		env_cfg.no_of_slave = no_of_slave;

endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
	
		
		env_cfg = env_config::type_id::create("env_cfg");
		config_test();
		
		uvm_config_db #(env_config)::set(this,"*","env_config",env_cfg);

		env_h = axi_env::type_id::create("env_h",this);

		
	endfunction

	function void end_of_elaboration_phase(uvm_phase phase);
		uvm_top.print_topology();
	endfunction

endclass

class fixed_test extends test;
	`uvm_component_utils(fixed_test)

	fixed_burst_seq fixed_seq;

	function new(string name="fixed_test",uvm_component parent);
		super.new(name,parent);
	endfunction

	task run_phase(uvm_phase phase);
		
		phase.raise_objection(this);
		fixed_seq=fixed_burst_seq::type_id::create("fixed_seq");
		fixed_seq.start(env_h.master_top.master_agt[0].seqrh);
		#10000;
		phase.drop_objection(this);		
	endtask
endclass


class incr_test extends test;
	`uvm_component_utils(incr_test)

	increment_burst_seq incr_seq;

	function new(string name="incr_test",uvm_component parent);
		super.new(name,parent);
	endfunction

	task run_phase(uvm_phase phase);
		
		phase.raise_objection(this);
		incr_seq=increment_burst_seq::type_id::create("incr_seq");
		incr_seq.start(env_h.master_top.master_agt[0].seqrh);
		#10000;
		phase.drop_objection(this);
		
	endtask
endclass

class wrap_test extends test;
	`uvm_component_utils(wrap_test)

	wrap_burst_seq wrap_seq;

	function new(string name="wrap_test",uvm_component parent);
		super.new(name,parent);
	endfunction

	task run_phase(uvm_phase phase);
		
		phase.raise_objection(this);
		wrap_seq=wrap_burst_seq::type_id::create("wrap_seq");
		wrap_seq.start(env_h.master_top.master_agt[0].seqrh);
		#10000;
		phase.drop_objection(this);
		
	endtask
endclass

// Comprehensive Random Test
class random_test extends test;
	`uvm_component_utils(random_test)

	master_seq_random rand_seq;

	function new(string name="random_test", uvm_component parent);
		super.new(name, parent);
	endfunction

	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		rand_seq = master_seq_random::type_id::create("rand_seq");
		rand_seq.start(env_h.master_top.master_agt[0].seqrh);
		#10000;
		phase.drop_objection(this);
	endtask
endclass

