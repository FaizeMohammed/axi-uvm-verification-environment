class slave_monitor extends uvm_monitor;
      `uvm_component_utils(slave_monitor)
   
      virtual axi_if.MON_MP vif;
      axi_slave_config slave_cfg;
     uvm_analysis_port#(axi_trans) monitor_port;

	axi_trans xtn, xtn1, xtn2, xtn3, xtn4;

	// Queues for channel handoff & packet reassembly
	axi_trans q1[$];      // Write Addr -> Write Data
	axi_trans q_wresp[$]; // Write Data -> Write Response
	axi_trans q2[$];      // Read Addr  -> Read Data

	semaphore sem_awdc = new();
	semaphore sem_wdrc = new();
	semaphore sem_wdc = new(1);
	semaphore sem_awc = new(1);
	semaphore sem_wrc = new(1);
	
	semaphore sem_ardc = new();
	semaphore sem_arc = new(1);
	semaphore sem_rdc = new(1);
	
      function new(string name="slave_monitor",uvm_component parent);
               super.new(name,parent);
      endfunction
  
      function void build_phase(uvm_phase phase);
		super.build_phase(phase);
	   if(!uvm_config_db#(axi_slave_config)::get(this,"","slave_config",slave_cfg))
	    `uvm_fatal("MONITOR","cannot get vif to slave_cfg")
 	
              monitor_port = new("monitor_port",this);

      endfunction
  
      function void connect_phase(uvm_phase phase);
                    super.connect_phase(phase);
 	            vif = slave_cfg.vif; 
      endfunction

	task run_phase(uvm_phase phase);
		forever
			begin
				monitor();
			end
			
	endtask

     task monitor();
	fork 
			// 1. Write Address Channel
		forever //adding forever in every thread because without it it kills other active threads
		begin
			sem_awc.get(1);
			write_addr();
			sem_awdc.put(1);		
			sem_awc.put(1);
		end
			// 2. Write Data Channel
		forever
		begin
			sem_awdc.get(1);
			sem_wdc.get(1);
			write_data(q1.pop_front());
	    		sem_wdc.put(1);
			sem_wdrc.put(1);
		end
			// 3. Write Response Channel
		forever
		begin
			sem_wdrc.get(1);
			sem_wrc.get(1);
			write_response(q_wresp.pop_front());
			sem_wrc.put(1);
		end
			// 4. Read Address Channel
		forever
		begin
			sem_arc.get(1);
			read_addr();
			sem_arc.put(1);
			sem_ardc.put(1);
		end
			// 5. Read Data Channel
		forever
		begin
			sem_ardc.get(1);
			sem_rdc.get(1);
			read_data(q2.pop_front());
			sem_rdc.put(1);
		end  

	join //changed from join_any bcs thread killing gemiini
               `uvm_info(" SLAVE MONITOR  "," THIS IS MONITOR SIDE ",UVM_HIGH);
	
    endtask		

// WRITE ADDRESS CHANNEL

	task write_addr();
	xtn = axi_trans::type_id::create("xtn");
				
		wait(vif.monitor_cb.AWVALID && vif.monitor_cb.AWREADY)
			
			xtn.AWID     = vif.monitor_cb.AWID;
			xtn.AWADDR   = vif.monitor_cb.AWADDR;
			xtn.AWLEN    = vif.monitor_cb.AWLEN;
			xtn.AWSIZE   = vif.monitor_cb.AWSIZE;
			xtn.AWBURST  = vif.monitor_cb.AWBURST;

		// Calculate beat addresses for comparison
		xtn.post_randomize();

		q1.push_back(xtn);
		@(vif.monitor_cb);
		
	endtask

// WRITE DATA CHANNEL

	task write_data(axi_trans xtn);
		
		xtn1 = xtn; // Pass forward transaction object from write_addr

            xtn.WDATA =new[xtn.AWLEN+1];
	    xtn.WSTRB =new[xtn.AWLEN+1];
		

		for(int i=0;i<(xtn.AWLEN+1);i++)
			begin
			wait(vif.monitor_cb.WVALID && vif.monitor_cb.WREADY);
                      
			xtn.WSTRB[i] =  vif.monitor_cb.WSTRB;

			if(vif.monitor_cb.WSTRB == 4'b0001)
				xtn.WDATA[i] =  vif.monitor_cb.WDATA[7:0];

		if(vif.monitor_cb.WSTRB == 4'b0010)
				xtn.WDATA[i] =  vif.monitor_cb.WDATA[15:8];

		if(vif.monitor_cb.WSTRB == 4'b0011)
				xtn.WDATA[i] =  vif.monitor_cb.WDATA[15:0];
		
		if(vif.monitor_cb.WSTRB == 4'b0100)
				xtn.WDATA[i] =  vif.monitor_cb.WDATA[23:16];

		if(vif.monitor_cb.WSTRB == 4'b1000)
				xtn.WDATA[i] =  vif.monitor_cb.WDATA[31:24];

		if(vif.monitor_cb.WSTRB == 4'b1100)
				xtn.WDATA[i] =  vif.monitor_cb.WDATA[31:16];
	
		if(vif.monitor_cb.WSTRB == 4'b1110)
				xtn.WDATA[i] =  vif.monitor_cb.WDATA[31:8];
	
		if(vif.monitor_cb.WSTRB == 4'b1111)
				xtn.WDATA[i] =  vif.monitor_cb.WDATA[31:0]; 

			xtn.WID	     =  vif.monitor_cb.WID;
			xtn1.WVALID  = vif.monitor_cb.WVALID;
			xtn.WLAST    =  vif.monitor_cb.WLAST;
			
		@(vif.monitor_cb);

			end
		q_wresp.push_back(xtn1);
		`uvm_info(get_type_name(), $sformatf("Exiting from write data \n %s SLAVE monitor:", xtn1.sprint()), UVM_MEDIUM);

	endtask


//\\//\\//\\//\\//\\//\\//\\//\\// WRITE RESPONSE CHANNEL //(Emits Full Write Transaction)\\//\\//\\//\\//\\//

	task write_response(axi_trans xtn);
		xtn2 = xtn;

		wait(vif.monitor_cb.BVALID && vif.monitor_cb.BREADY);

			xtn2.BID =vif.monitor_cb.BID;
			xtn2.BRESP =vif.monitor_cb.BRESP;

			@(vif.monitor_cb);

 `uvm_info("SLAVE MONITOR write response","COLLECTED write response task",UVM_LOW);

		// Send 1 fully assembled Write Packet to Scoreboard
		monitor_port.write(xtn2);
	endtask

// READ ADDRESS CHANNEL
	task read_addr();
			
			xtn3 = axi_trans::type_id::create("xtn3");

		wait(vif.monitor_cb.ARVALID && vif.monitor_cb.ARREADY)
		
			xtn3.ARADDR  =   vif.monitor_cb.ARADDR ; 
			xtn3.ARID    =   vif.monitor_cb.ARID;
			xtn3.ARLEN   = 	vif.monitor_cb.ARLEN;
			xtn3.ARSIZE  = 	vif.monitor_cb.ARSIZE;
			xtn3.ARBURST = 	vif.monitor_cb.ARBURST;

		// Calculate read beat addresses
			xtn3.post_randomize();

		q2.push_back(xtn3);
		@(vif.monitor_cb);			
				
	endtask

	// READ DATA CHANNEL (Emits Full Read Transaction)
	task read_data(axi_trans xtn);
		xtn4 = xtn;
		xtn.RDATA = new[xtn.ARLEN+1];
		xtn4.RRESP = new[xtn4.ARLEN + 1];

			for(int i=0;i<(xtn.ARLEN+1);i++)
			begin
			wait(vif.monitor_cb.RVALID && vif.monitor_cb.RREADY);

			xtn4.RID        = vif.monitor_cb.RID;
			xtn4.RDATA[i]   = vif.monitor_cb.RDATA;
			xtn4.RRESP[i]   = vif.monitor_cb.RRESP;
			xtn4.RLAST      = vif.monitor_cb.RLAST;
									
				@(vif.monitor_cb);
			end
// Send 1 fully assembled Read Packet to Scoreboard
		monitor_port.write(xtn4);
	 `uvm_info("slave RDATA",$sformatf("Leaving from slave monitor RDATA task\n%d", xtn.sprint()),UVM_LOW);

	endtask

endclass

