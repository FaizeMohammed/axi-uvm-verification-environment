class slave_driver extends uvm_driver#(axi_trans);
`uvm_component_utils(slave_driver)

	virtual axi_if.S_DRV_MP vif;
	axi_slave_config slave_cfg;

// Separate write and read transaction handles to handle full-duplex parallel transfers
	axi_trans write_xtn;
	axi_trans read_xtn;

// Queues for passing transactions between channel tasks
	axi_trans q_write_data[$];
	axi_trans q_write_resp[$];
	axi_trans q_read_data[$];

	axi_trans q4[$];//y not these 2 queuse
	axi_trans q5[$];

	int mem[int];

// Semaphores for task synchronization
	semaphore sem_awddr;
	semaphore sem_wdata;
	semaphore sem_wresp;
	semaphore sem_rdaddr;
	semaphore sem_rd_data;
	semaphore sem_awaddr_d;
	semaphore sem_wdata_d;
	semaphore sem_raddr_d;

function new(string name="slave_driver",uvm_component parent);
           super.new(name,parent);
  endfunction
 
  function void build_phase(uvm_phase phase);
	super.build_phase(phase);
                if(!uvm_config_db #(axi_slave_config)::get(this,"","slave_config",slave_cfg))
	         `uvm_fatal("CONFIG","cannot get() slave_cfg from uvm_config_db. Have you set() it?") 

		 sem_awddr=new(1);
		 sem_wdata=new(1);
		 sem_wresp=new(1);

		 sem_rdaddr=new(1);
		 sem_rd_data=new(1);
	
		 sem_awaddr_d = new();
		 sem_wdata_d = new();
		 sem_raddr_d = new();


  endfunction

  function void connect_phase(uvm_phase phase);
                super.connect_phase(phase);
                vif = slave_cfg.vif;
   endfunction


	task run_phase(uvm_phase phase);
		forever
			begin
	
				got_to_slave();
			end
	endtask

task got_to_slave();
	
		fork
			// 1. Write Address Channel
			begin
				sem_awddr.get(1);
				drive_write_address();
				sem_awddr.put(1);
				sem_awaddr_d.put(1);			
			end

			// 2. Write Data Channel
			begin 
				sem_awaddr_d.get(1);
				sem_wdata.get(1);
				drive_write_data(q_write_data.pop_front());
				sem_wdata.put(1);
				sem_wdata_d.put(1);

			end
			
			// 3. Write Response Channel
			begin
				sem_wdata_d.get(1);			
												drive_write_response(q_write_resp.pop_front());
				sem_wresp.put(1);
			end
			 
			// 4. Read Address Channel
			begin
				sem_rdaddr.get(1);
				drive_read_address();
				sem_rd_data.put(1);
				sem_raddr_d.put(1);
			
			end		
		
			// 5. Read Data Channel
			begin
				sem_raddr_d.get(1);
				sem_rd_data.get(1);
				drive_read_data(q_read_data.pop_front());
				sem_rd_data.put(1);
			end 	     
		
		join_any
	
	endtask


//write address channel

	task drive_write_address();
		begin
		
			write_xtn=axi_trans::type_id::create("write_xtn"); //creating for the sampling only for AWLEN

			vif.slave_drv_cb.AWREADY <=1'b1;
			@(vif.slave_drv_cb);

			wait (vif.slave_drv_cb.AWVALID);
					
			write_xtn.AWADDR  = vif.slave_drv_cb.AWADDR;
			write_xtn.AWID    = vif.slave_drv_cb.AWID;
			write_xtn.AWLEN   = vif.slave_drv_cb.AWLEN;
			write_xtn.AWSIZE  = vif.slave_drv_cb.AWSIZE;
			write_xtn.AWBURST = vif.slave_drv_cb.AWBURST;
			write_xtn.BID     = write_xtn.AWID;

		// Calculate waddr[] array for each beat in the burst
  			  write_xtn.post_randomize();
			
			vif.slave_drv_cb.AWREADY <=1'b0;
			q_write_data.push_back(write_xtn);


			repeat($urandom_range(1,5)) 
				@(vif.slave_drv_cb);

	end
endtask

// WRITE DATA CHANNEL (Stores WDATA into Memory)

	task drive_write_data(axi_trans xtn);

		 //to keep wready high continously(stable) during burst,earlier both wready was inside for loop so wready gets toggled after every data

		for(int i=0;i<(xtn.AWLEN+1);i++)
			begin
				vif.slave_drv_cb.WREADY <=1'b1;	
				@(vif.slave_drv_cb);
	
				wait (vif.slave_drv_cb.WVALID);

	// Store incoming WDATA into associative memory based on WSTRB
      if (vif.slave_drv_cb.WSTRB == 4'b1111)
        mem[xtn.waddr[i]] = vif.slave_drv_cb.WDATA;
      else if (vif.slave_drv_cb.WSTRB == 4'b0001)
        mem[xtn.waddr[i]] = vif.slave_drv_cb.WDATA[7:0];
      else if (vif.slave_drv_cb.WSTRB == 4'b0010)
        mem[xtn.waddr[i]] = vif.slave_drv_cb.WDATA[15:8];
      else if (vif.slave_drv_cb.WSTRB == 4'b0100)
        mem[xtn.waddr[i]] = vif.slave_drv_cb.WDATA[23:16];
      else if (vif.slave_drv_cb.WSTRB == 4'b1000)
        mem[xtn.waddr[i]] = vif.slave_drv_cb.WDATA[31:24];
      else
        mem[xtn.waddr[i]] = vif.slave_drv_cb.WDATA; // Default fallback

				vif.slave_drv_cb.WREADY <=1'b0;	

			repeat($urandom_range(1,5))
				@(vif.slave_drv_cb);
			end
			
		q_write_resp.push_back(xtn);	            	
      
	endtask

//write response channel

	task drive_write_response(axi_trans xtn);
	
		vif.slave_drv_cb.BVALID <=1'b1;

		vif.slave_drv_cb.BID <=xtn.BID;  //line 202 in trans written constraint then y =STILL NEED FOR IT TO GO TO INTERFACE changed from WID TO BID
		vif.slave_drv_cb.BRESP <=2'b00; // OKAY response
			
			@(vif.slave_drv_cb);
		wait(vif.slave_drv_cb.BREADY);

		vif.slave_drv_cb.BVALID <=1'b0;

	
		repeat($urandom_range(1,5))
		@(vif.slave_drv_cb);
	endtask

//read address channel

	task drive_read_address();
		
	read_xtn = axi_trans::type_id::create("read_xtn");			vif.slave_drv_cb.ARREADY <=1'b1;
							@(vif.slave_drv_cb);

	wait (vif.slave_drv_cb.ARVALID);


			read_xtn.ARID     = vif.slave_drv_cb.ARID;   
			read_xtn.ARADDR   = vif.slave_drv_cb.ARADDR;
	
			read_xtn.ARLEN    = vif.slave_drv_cb.ARLEN;
			read_xtn.ARSIZE   = vif.slave_drv_cb.ARSIZE;
			read_xtn.ARBURST  = vif.slave_drv_cb.ARBURST;
			  read_xtn.RID    =read_xtn.ARID;	

		// Calculate raddr[] array for each beat in the burst
    		read_xtn.post_randomize();

		vif.slave_drv_cb.ARREADY <=1'b0;
		q_read_data.push_back(read_xtn);		
	
		repeat($urandom_range(1,5))
		@(vif.slave_drv_cb);

	endtask

// READ DATA CHANNEL (Fetches Stored Memory)

	task drive_read_data(axi_trans xtn);
		`uvm_info(get_type_name(), "READ START", UVM_MEDIUM);	

		for(int i=0;i< (xtn.ARLEN+1);i++)
			begin

				vif.slave_drv_cb.RVALID <=1'b1;

// Fetch stored data from memory model; fallback to random if address was never written
      if (mem.exists(xtn.raddr[i]))
        vif.slave_drv_cb.RDATA <= mem[xtn.raddr[i]];
      else
	vif.slave_drv_cb.RDATA <= $urandom_range(1, 100);         

		vif.slave_drv_cb.RRESP <=2'b00;// OKAY response
		  vif.slave_drv_cb.RID <=  xtn.ARID;
	
			         			
			if(i == xtn.ARLEN)
				       	vif.slave_drv_cb.RLAST <= 1'b1;
			else
				       	vif.slave_drv_cb.RLAST <= 1'b0;
				
			@(vif.slave_drv_cb);
			wait (vif.slave_drv_cb.RREADY);

			vif.slave_drv_cb.RLAST <= 1'b0;
			vif.slave_drv_cb.RVALID <=1'b0;
	
    		        repeat($urandom_range(1,5))
				@(vif.slave_drv_cb);
		end
	endtask	

endclass

