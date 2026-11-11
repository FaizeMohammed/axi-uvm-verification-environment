
 class axi_sb extends uvm_scoreboard;
    `uvm_component_utils(axi_sb)

  uvm_tlm_analysis_fifo#(axi_trans) fifo_master_m[];
  uvm_tlm_analysis_fifo#(axi_trans) fifo_slave_m[];

	env_config env_cfg;

    axi_trans master_data,slave_data ;
    axi_trans m_cov, s_cov;

// WRITE COVERGROUPS
   	covergroup write_cg;
		option.per_instance = 1;
		AWADDR_CP: coverpoint m_cov.AWADDR{
						bins awaddr_bin = {[0:4095]};}
		AWBURST_CP: coverpoint m_cov.AWBURST{
						bins awburst_bin[] = {[0:2]};}
		AWSIZE_CP: coverpoint m_cov.AWSIZE{
						bins awsize_bin[] = {[0:2]};}
		AWLEN_CP: coverpoint m_cov.AWLEN{
						bins awlen = {[0:11]};}
		BRESP_CP: coverpoint m_cov.BRESP{bins bresp_bin = {0};}
		
		WRITE_ADDR_CROSS: cross AWBURST_CP, AWSIZE_CP, AWLEN_CP;
	endgroup
	

	covergroup write_cg1 with function sample(int i);
		option.per_instance = 1;
		WSTRB_CP: coverpoint m_cov.WSTRB[i]{
			bins wstrb0 = {4'b1111};
			bins wstrb1 = {4'b1100};
	        	bins wstrb2 = {4'b0011};
			bins wstrb3 = {4'b1000};
			bins wstrb4 = {4'b0100};
			bins wstrb5 = {4'b0010};
			bins wstrb6 = {4'b0001};
			bins wstrb7 = {4'b1110};
		}
	endgroup
	
// READ COVERGROUPS
	covergroup read_cg;
		option.per_instance = 1;
		ARADDR_CP: coverpoint s_cov.ARADDR{
						bins araddr_bin = {[0:4095]};}
		ARBURST_CP: coverpoint s_cov.ARBURST{
						bins arburst_bin[] = {[0:2]};}
		ARSIZE_CP: coverpoint s_cov.ARSIZE{
						bins arsize_bin[] = {[0:2]};}
		ARLEN_CP: coverpoint s_cov.ARLEN{bins arlen_bin = {[0:11]};}
	
		READ_ADDR_CROSS: cross ARBURST_CP, ARSIZE_CP, ARLEN_CP;
	endgroup
	

	covergroup read_cg1 with function sample(int i);
		option.per_instance = 1;
		RRESP_CP: coverpoint s_cov.RRESP[i]{
							bins rresp_bin = {0};}
	endgroup



  	function new(string name = "axi_sb",uvm_component parent);
  		super.new(name,parent);
		write_cg  = new();
		write_cg1 = new();
		read_cg   = new();
		read_cg1 = new();
			
  	endfunction

  function void build_phase(uvm_phase phase);
     super.build_phase(phase);
 
       if(!uvm_config_db#(env_config)::get(this,"","env_config",env_cfg))
          `uvm_fatal(get_type_name(),"Did you get the config")
             fifo_master_m = new[env_cfg.no_of_master];
         
             fifo_slave_m = new [env_cfg.no_of_slave];
         
      foreach(fifo_master_m[i])
                begin
                   fifo_master_m[i] = new($sformatf("fifo_master_m[%0d]",i),this);
                end

      foreach(fifo_slave_m[i])
                begin
                   fifo_slave_m[i] = new($sformatf("fifo_slave_m[%0d]",i),this);
                end
   
  endfunction
      

   task run_phase(uvm_phase phase);
       forever
               begin

                    fifo_master_m[0].get(master_data);
                  
                    fifo_slave_m[0].get(slave_data);

                 if(master_data.compare(slave_data))
                        begin
                             `uvm_info("SCOREBOARD", "******************* COMPARISON SUCCESSFUL **************************", UVM_LOW)
			
			// Check if transaction is a WRITE
				if (master_data.WDATA.size() > 0) begin
					m_cov = master_data;
					write_cg.sample();

					foreach (master_data.WDATA[i]) begin
						write_cg1.sample(i);
					end
				end	

			// Check if transaction is a READ
				if (master_data.RDATA.size() > 0) begin
					s_cov = slave_data;
					read_cg.sample();

					foreach (master_data.RDATA[i]) begin
						read_cg1.sample(i);
					end
				end

			end else begin
				`uvm_info("SCOREBOARD", "******************* COMPARISON FAILED **************************", UVM_LOW)
				`uvm_info("SCOREBOARD", $sformatf("Master Packet:\n%s", master_data.sprint()), UVM_LOW)
				`uvm_info("SCOREBOARD", $sformatf("Slave Packet:\n%s", slave_data.sprint()), UVM_LOW)
			end
		end	 
         endtask
                    
 endclass


