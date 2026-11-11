class master_driver extends uvm_driver#(axi_trans);
	`uvm_component_utils(master_driver)

	virtual axi_if.M_DRV_MP vif;
	axi_master_config master_cfg;

// Queues for pipelined outstanding transactions
  axi_trans q_write_addr[$];
  axi_trans q_write_data[$];
  axi_trans q_write_resp[$];
  axi_trans q_read_addr[$];
  axi_trans q_read_data[$];

// Semaphores for channel synchronization
	semaphore sem_awddr;
	semaphore sem_wdata;
	semaphore sem_wresp;
	semaphore sem_rdaddr;
	semaphore sem_rd_data;

	semaphore sem_awaddr_d;
	semaphore sem_wdata_d;
	semaphore sem_araddr_d;

	 	
	function new(string name="master_driver",uvm_component parent);
           super.new(name,parent);
  	endfunction
 
	
  	function void build_phase(uvm_phase phase);
	      super.build_phase(phase);
              if(!uvm_config_db #(axi_master_config)::get(this,"","master_config",master_cfg))
	         	`uvm_fatal("CONFIG","cannot get() axi_cfg from uvm_config_db. Have you set() it?") 

		 sem_awddr    = new(1);
		 sem_wdata    = new(1);
		 sem_wresp    = new(1);

		 sem_rdaddr   = new(1);
		 sem_rd_data  = new(1);

		 sem_awaddr_d = new();
		 sem_wdata_d  = new();
		 sem_araddr_d = new();
	  endfunction

 	 function void connect_phase(uvm_phase phase);
                super.connect_phase(phase);
                
		vif = master_cfg.vif;
 	 endfunction

  	task run_phase(uvm_phase phase);
		forever
			begin
	  			seq_item_port.get_next_item(req);

			q_write_addr.push_back(req);
    		        q_write_data.push_back(req);
      			q_write_resp.push_back(req);
      			q_read_addr.push_back(req);
      			q_read_data.push_back(req);

			send_to_dut();

			seq_item_port.item_done();

 			end
	endtask

// WRITE ADDRESS CHANNEL

	task send_write_address(axi_trans xtn);
		begin

			vif.master_drv_cb.AWVALID <= 1'b1;
			vif.master_drv_cb.AWADDR  <= xtn.AWADDR;
			vif.master_drv_cb.AWID    <= xtn.AWID;
			vif.master_drv_cb.AWLEN   <= xtn.AWLEN;
			vif.master_drv_cb.AWSIZE  <= xtn.AWSIZE;
			vif.master_drv_cb.AWBURST <= xtn.AWBURST;

		@(vif.master_drv_cb); 
			wait (vif.master_drv_cb.AWREADY); //given by slave

			vif.master_drv_cb.AWVALID <=1'b0;

			repeat($urandom_range(1,5))
				@(vif.master_drv_cb);

		end

	endtask

// WRITE DATA CHANNEL

	task send_write_data(axi_trans xtn);

		for(int i=0;i<(xtn.AWLEN+1);i++)
			begin

					vif.master_drv_cb.WVALID  <= 1'b1;
					vif.master_drv_cb.WID     <= xtn.WID;
					vif.master_drv_cb.WDATA   <= xtn.WDATA[i];   //send to interface how many datas according to no of transfer
					vif.master_drv_cb.WSTRB   <= xtn.WSTRB[i];
	
				if(i== xtn.AWLEN)
				       	vif.master_drv_cb.WLAST <= 1'b1;
				else
   				        vif.master_drv_cb.WLAST <= 1'b0;
			
				@(vif.master_drv_cb);
				wait (vif.master_drv_cb.WREADY); //sent by slave


					vif.master_drv_cb.WVALID <=1'b0;
				       	vif.master_drv_cb.WLAST <= 1'b0;
	
			repeat($urandom_range(1,5))
				@(vif.master_drv_cb);
		
			end
	endtask

//\\//\\//\\//\\//\\//\\//\\//\\// WRITE RESPONSE CHANNEL //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//

	task get_write_response(axi_trans xtn);
	
		vif.master_drv_cb.BREADY <=1'b1;

			@(vif.master_drv_cb);

		wait (vif.master_drv_cb.BVALID); //sent by slave
		vif.master_drv_cb.BREADY <=0;
		
		repeat($urandom_range(1,5))
		@(vif.master_drv_cb);

	
	endtask

// READ ADDRESS CHANNEL

	task send_read_address(axi_trans xtn);

		        vif.master_drv_cb.ARVALID <= 1'b1;
			vif.master_drv_cb.ARADDR  <= xtn.ARADDR;
			vif.master_drv_cb.ARID    <= xtn.ARID;
			vif.master_drv_cb.ARLEN   <= xtn.ARLEN;
			vif.master_drv_cb.ARSIZE  <= xtn.ARSIZE;
			vif.master_drv_cb.ARBURST <= xtn.ARBURST;

			@(vif.master_drv_cb);
			wait (vif.master_drv_cb.ARREADY);

			vif.master_drv_cb.ARVALID <=1'b0;
		
	repeat($urandom_range(1,5))
		@(vif.master_drv_cb);

	endtask

// READ DATA CHANNEL

	task get_read_data(axi_trans xtn);
		
		for(int i=0;i<xtn.ARLEN+1;i++)
			begin
				vif.master_drv_cb.RREADY <=1'b1;
				
				@(vif.master_drv_cb);	
		
				wait (vif.master_drv_cb.RVALID);
				vif.master_drv_cb.RREADY <=1'b0;

          			repeat($urandom_range(1,5))
				@(vif.master_drv_cb);
			end

	endtask
	
// MAIN DRIVER FORK TASK

	task send_to_dut();
	
		fork
		
			// 1. Write Address Channel
			begin
				sem_awddr.get(1);
				send_write_address(q_write_addr.pop_front());
				sem_awddr.put(1);
				sem_awaddr_d.put(1);				
			end
			
			// 2. Write Data Channel
			begin 
				sem_awaddr_d.get(1);
				sem_wdata.get(1);
				send_write_data(q_write_data.pop_front());
				sem_wdata.put(1);
				sem_wdata_d.put(1);
			end
			
			// 3. Write Response Channel
			begin
				sem_wdata_d.get(1);
				sem_wresp.get(1);
				get_write_response(q_write_resp.pop_front());
				sem_wresp.put(1);
			end
			 
			// 4. Read Address Channel
			begin
				sem_rdaddr.get(1);
				send_read_address(q_read_addr.pop_front());
				sem_rdaddr.put(1);
				sem_araddr_d.put(1);
			end		
		
			// 5. Read Data Channel
			begin
				sem_araddr_d.get(1);
				sem_rd_data.get(1);
				get_read_data(q_read_data.pop_front());
				sem_rd_data.put(1);
			end  
		
		join_any
	endtask

endclass

