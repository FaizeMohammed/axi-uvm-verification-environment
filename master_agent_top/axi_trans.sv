class axi_trans extends uvm_sequence_item;
	`uvm_object_utils(axi_trans)

	//Write Address Channel
	rand bit [3:0] AWID;
	rand bit [31:0] AWADDR;
//control signals
	rand bit [3:0] AWLEN; //Burst length. The burst length gives the exact number of transfers in a burst
	rand bit [2:0] AWSIZE;//Burst size. This signal indicates the size of each transfer in the burst. Byte lane strobes indicate exactly which byte lanes to update

	rand bit [1:0] AWBURST;
	bit AWVALID;
	bit AWREADY;

	//Write Data Channel
	rand bit [3:0] WID;
	rand bit [31:0] WDATA[]; //no of data=no of transfer
	bit [3:0] WSTRB[];//no of strobe =no of transfer //how many write strobes needed it depebds on no of transfers which depend on lengtth+1
	bit WLAST;
	bit WVALID;
	bit WREADY;

	//Write Response Channel
	rand bit [3:0] BID;
	bit [1:0] BRESP;//logic bcs initialy we dont know so unknown x,i changed to bit
	bit BVALID;
	bit BREADY;
	
	//Read Address Channel
	rand bit [3:0] ARID;
	rand bit [31:0] ARADDR;
	rand bit [3:0] ARLEN;

	rand bit [2:0] ARSIZE;
	rand bit [1:0] ARBURST;
	bit ARVALID;
	bit ARREADY;
	
	//Read Data Channel
	rand bit [3:0] RID;
	rand bit [31:0] RDATA[];
	bit [1:0] RRESP[]; 
	bit RLAST;
	bit RREADY;
	bit RVALID;

	bit[31:0] waddr [];  //no of transfer in a burst same thing as WDATA here we said that its  limited to 32 bit in 1 transfer,calculated addresses for write beats

	int no_of_wbytes; //no of bytes in one transfer ,written constrain to limit till 4bytes
	int aligned_waddr;
	int start_waddr;

	
	bit[31:0] raddr[];// calculated addresses for read beats
	int no_of_rbytes;// bytes per read transfer
	int aligned_raddr;
	int start_raddr;
	
	int w_burst_len; //equal to no of transfer // AWLEN + 1
	int r_burst_len;	// ARLEN + 1

	function void post_randomize();

		no_of_wbytes = 2**AWSIZE; //no of bytes in row,horizontal limited to awsize=2 then we get 4bytes which is 4*8=32bits //also bytes*no of transfer
		start_waddr = AWADDR; //start address
		aligned_waddr = (int'(AWADDR/no_of_wbytes))*no_of_wbytes;
		w_burst_len = AWLEN + 1;
		WSTRB = new[w_burst_len]; //no of transfer = no of strobe we need to calculate
	
		cal_addr_w(); //calculate address after 1st transfer
		strb_cal_w(); //calculate strobe 

		no_of_rbytes = 2**ARSIZE;
		start_raddr = ARADDR;
		aligned_raddr = (int'(ARADDR/no_of_rbytes))*no_of_rbytes;
              r_burst_len = ARLEN + 1;	
		RRESP       = new[r_burst_len];

		cal_addr_r();

//	$display("next address locations for write operation waddr %p",waddr);
//	$display("aligned_ address locations for write operation aligned_waddr %d",aligned_waddr);

//	$display("next address locations for read operation raddr %p",raddr);
//	$display("aligned_ address locations for read operation aligned_raddr %d",aligned_raddr);

	
	endfunction

	function void cal_addr_w();

		bit wb; //just flag to check if boundary is set
		int wrap_boundary;
		int addr_n;

 		w_burst_len = AWLEN+1; //no of transfers

		wrap_boundary = (int'(start_waddr/(no_of_wbytes * w_burst_len)) * (no_of_wbytes * w_burst_len));//depending on start address this equation which boundary we find out
		addr_n = wrap_boundary + (no_of_wbytes*w_burst_len); //bottom boundary

		waddr = new[w_burst_len]; //no of address locations there is

		waddr[0] = AWADDR;

	for(int i = 2; i <= w_burst_len; i++) 
		begin
			if(AWBURST == 0) //FIXED
				waddr[i-1] = AWADDR;
			if(AWBURST == 1) //INCR
				waddr[i-1] = aligned_waddr + ((i-1) * no_of_wbytes);
			if(AWBURST == 2) //WRAP
				 begin
					if(wb == 0)
						begin
							waddr[i-1] = aligned_waddr + ((i-1) * no_of_wbytes);
						
							if(waddr[i-1] ==  addr_n)
								begin
									waddr[i-1] = wrap_boundary;
									wb++;
								end
						end
					else
						waddr[i-1] = start_waddr + ((i-1) * no_of_wbytes) - (no_of_wbytes * w_burst_len);
				end
		end
	//	$display("wrap boundary first location %d",wrap_boundary);
	//	$display("wrap boundary bottom/last wrap  location %d",addr_n);

	endfunction



	function void strb_cal_w();
               
		int data_bus_bytes = 4; //it can be 1,2,4 bcs 2^awsize limited to 4 same as no_of_wbytes
		int lower_byte_lane, upper_byte_lane;
	
		int lower_byte_lane0 = start_waddr - ((int'(start_waddr / data_bus_bytes)) * data_bus_bytes);
		int upper_byte_lane0 = aligned_waddr +(no_of_wbytes -1)-((int'(start_waddr/data_bus_bytes))*data_bus_bytes);

		  for(int j=lower_byte_lane0;j<=upper_byte_lane0;j++)begin
		   WSTRB[0][j]=1'b1;
                  end

		for(int i=1;i<w_burst_len;i++)
			begin
				lower_byte_lane=waddr[i] -((int'(waddr[i]/data_bus_bytes))*data_bus_bytes);
				upper_byte_lane=lower_byte_lane + no_of_wbytes -1;
				 for(int j=lower_byte_lane;j<=upper_byte_lane;j++)begin
                                     WSTRB[i][j]=1'b1;

				  end
                      	end	 	
		
//one dataData is transferred on:DATA[(8 x Upper_Byte_Lane ) + 7 : (8 x Lower_Byte_Lane )].

		foreach(WSTRB[i])
			$display("WSTRB[%0d] = %b", i, WSTRB[i]);

	endfunction

	
		function void cal_addr_r(); 

		bit rb;
		int wrap_boundary;
		int addr_n;

		 r_burst_len = ARLEN+1;

	wrap_boundary = (int'(start_raddr/(no_of_rbytes * r_burst_len))) * (no_of_rbytes * r_burst_len);

	addr_n = wrap_boundary + (no_of_rbytes*r_burst_len);

		raddr = new[r_burst_len];

		raddr[0] = ARADDR;

		for(int i = 2; i <= r_burst_len; i++) begin
			if(ARBURST == 0)
				raddr[i-1] = ARADDR;
			if(ARBURST == 1)
				raddr[i-1] = aligned_raddr + ((i-1) * no_of_rbytes);
			if(ARBURST == 2) begin
				if(rb == 0)begin
					raddr[i-1] = aligned_raddr + ((i-1) * no_of_rbytes);
					if(raddr[i-1] ==  addr_n)begin
						raddr[i-1] = wrap_boundary;
						rb++;
					end
				end
				else
					raddr[i-1] = start_raddr + ((i-1) * no_of_rbytes) - (no_of_rbytes * r_burst_len);
			end
		end
	//	$display("wrap boundary read first location %d",wrap_boundary);
	//	$display("wrap boundary read bottom/last wrap  location %d",addr_n);


	endfunction

	

	function new(string name = "axi_trans");
		super.new(name);
	endfunction

//Constraints
	constraint wr_id {WID == AWID; BID == AWID;}
	constraint rd_id {RID == ARID;}

	constraint awlen {if (AWBURST == 2'b10) (AWLEN + 1) inside {2,4,8,16};}
	constraint arlen {if (ARBURST == 2'b10) (ARLEN + 1) inside {2,4,8,16};}

	constraint awsize {AWSIZE inside{0, 1, 2};}
	constraint arsize {ARSIZE inside{0, 1, 2};}

	constraint w_data {WDATA.size() == (AWLEN + 1);}
	constraint r_data {RDATA.size() == (ARLEN + 1);}

	
	constraint w_len {AWLEN inside {[0:15]};}
	constraint r_len {ARLEN inside {[0:15]};}
	
	//aligned address constraint
	constraint araddr {ARADDR < 4096;
				(ARBURST == 2 || ARBURST == 0) && (ARSIZE == 1) -> ARADDR % 2 == 0;
				(ARBURST == 2 || ARBURST == 0) && (ARSIZE == 2) -> ARADDR % 4 == 0;}

	constraint awaddr {AWADDR < 4096;
				(AWBURST  == 2 || AWBURST == 0) && (AWSIZE == 1) -> AWADDR % 2 == 0;
				(AWBURST == 2 || AWBURST == 0) && (AWSIZE == 2) -> AWADDR % 4 == 0;}

	constraint awburst {AWBURST dist{0:=10, 1:=10, 2:=10};}
	constraint arburst {ARBURST dist{0:=10, 1:=10, 2:=10};}

	constraint max_boundary_w {(AWLEN+1) * (2**AWSIZE) < 4096;}
	constraint max_boundary_r {(ARLEN+1) * (2**ARSIZE) < 4096;}

	

	 function void do_print(uvm_printer printer);
	super.do_print(printer);

	//                   srting name   	bitstream value     size       radix for printing
   	printer.print_field( "AWID", 		this.AWID, 	    4,		 UVM_DEC		);
  	printer.print_field( "AWADDR", 		this.AWADDR, 	    32,		 UVM_DEC		);
    	printer.print_field( "AWLEN", 		this.AWLEN, 	    4,		 UVM_DEC		);    	
        printer.print_field( "AWSIZE", 		this.AWSIZE, 	    3,		 UVM_DEC		);
    	printer.print_field( "AWBURST", 	this.AWBURST, 	    2,		 UVM_DEC		);
	printer.print_field( "AWVALID", 	this.AWVALID, 	    1,		 UVM_DEC		);
	printer.print_field( "AWREADY", 	this.AWREADY, 	    1,		 UVM_DEC		);

	printer.print_field( "WID", 		this.WID, 	    4,		 UVM_DEC		);

 foreach(WDATA[i])
       begin
	printer.print_field($sformatf("WDATA[%0d]",i),	this.WDATA[i],	$bits(WDATA[i]),	UVM_HEX);
       end


      foreach(WSTRB[i])
       begin
	printer.print_field($sformatf("WSTRB[%0d]",i),	this.WSTRB[i],	$bits(WSTRB[i]),	UVM_BIN);
       end
             

        printer.print_field( "WLAST", 		this.WLAST, 	    1,		 UVM_DEC		);
	printer.print_field( "WVALID", 		this.WVALID, 	    1,		 UVM_DEC		);
	printer.print_field( "WREADY",            this.WREADY, 	    1,		 UVM_DEC		);

	printer.print_field( "BID",             this.BID, 	    4,		 UVM_DEC		);
	printer.print_field( "BRESP", 		this.BRESP, 	    2,		 UVM_DEC		);
    	printer.print_field( "BVALID", 		this.BVALID, 	    1,		 UVM_DEC		);
    	printer.print_field( "BREADY", 	        this.BREADY, 	    1,		 UVM_DEC		);

	printer.print_field( "ARID", 	        this.ARID, 	    4,		 UVM_DEC		);
	
        printer.print_field( "ARADDR", 		this.ARADDR, 	    32,		 UVM_DEC		);
        printer.print_field( "ARLEN", 		this.ARLEN, 	    4,		 UVM_DEC		);
	printer.print_field( "ARSIZE", 	        this.ARSIZE, 	    3,		 UVM_DEC		); 
	printer.print_field( "ARBURST",    	this.ARBURST, 	    2,		 UVM_DEC		);
  	printer.print_field( "ARVALID", 	this.ARVALID, 	    1,		 UVM_DEC		);
    	printer.print_field( "ARREADY", 	this.ARREADY, 	    1,		 UVM_DEC		);   
 	
        printer.print_field( "RID", 		this.RID, 	    4,		 UVM_DEC		);
     foreach(RDATA[i])
       begin
	printer.print_field($sformatf("RDATA[%0d]",i),	this.RDATA[i],	$bits(RDATA[i]),	UVM_HEX);
	printer.print_field("RRESP", 		 this.RRESP[i],     2	,	UVM_DEC			);

       end

	printer.print_field( "RLAST", 		this.RLAST, 	    1,		 UVM_DEC		);
	printer.print_field( "RVALID", 		this.RVALID, 	    1,		 UVM_DEC		);
	printer.print_field( "RREADY", 		this.RREADY, 	    1,		 UVM_DEC		);

                  
      
      endfunction

	function void do_copy(uvm_object rhs);
		axi_trans rhs_;

		if(!$cast(rhs_, rhs))
			`uvm_fatal("do_copy", "cannot cast rhs in do_copy")

		super.do_copy(rhs);

		this.AWID = rhs_.AWID;
		this.AWADDR = rhs_.AWADDR;
		this.AWLEN = rhs_.AWLEN;
		this.AWSIZE = rhs_.AWSIZE;
		this.AWBURST = rhs_.AWBURST;
		this.AWVALID = rhs_.AWVALID;
		this.AWREADY = rhs_.AWREADY;

	//Write Data Channel
		this.WID = rhs_.WID;
		this.WDATA = rhs_.WDATA;
		this.WSTRB = rhs_.WSTRB;
		this.WLAST = rhs_.WLAST;
		this.WVALID = rhs_.WVALID;
		this.WREADY = rhs_.WREADY;

	//Write Response Channel
		this.BID = rhs_.BID;
		this.BRESP = rhs_.BRESP;
		this.BVALID = rhs_.BVALID;
		this.BREADY = rhs_.BREADY;
	
	//Read Address Channel
		this.ARID = rhs_.ARID;
		this.ARADDR = rhs_.ARADDR;
		this.ARLEN = rhs_.ARLEN;
		this.ARSIZE = rhs_.ARSIZE;
		this.ARBURST = rhs_.ARBURST;
		this.ARVALID = rhs_.ARVALID;
		this.ARREADY = rhs_.ARREADY;
	
	//Read Data Channel
		this.RID = rhs_.RID;
		this.RDATA = rhs_.RDATA;
		this.RRESP = rhs_.RRESP;
		this.RLAST = rhs_.RLAST;
		this.RREADY = rhs_.RREADY;

		endfunction

	function bit do_compare(uvm_object rhs, uvm_comparer comparer);
		axi_trans rhs_;

		if(!$cast(rhs_, rhs))
		     begin	
			`uvm_fatal(get_type_name(), "cannot cast rhs in do_compare")
                	 return 0;
		     end
		
		return super.do_compare(rhs, comparer)&&

		 // Handshake signals (VALID/READY) are excluded from TLM packet comparison as they are transient bus signals.
		this.AWID == rhs_.AWID &&
		this.AWADDR == rhs_.AWADDR &&
		this.AWLEN == rhs_.AWLEN &&
		this.AWSIZE == rhs_.AWSIZE &&
		this.AWBURST == rhs_.AWBURST &&
	//	this.AWVALID == rhs_.AWVALID && 
	//	this.AWREADY == rhs_.AWREADY &&

	//Write Data Channel
		this.WID == rhs_.WID &&
		this.WDATA == rhs_.WDATA &&
		this.WSTRB == rhs_.WSTRB &&
		this.WLAST == rhs_.WLAST &&
		//this.WVALID == rhs_.WVALID &&
		//this.WREADY == rhs_.WREADY &&

	//Write Response Channel
		this.BID == rhs_.BID &&
		this.BRESP == rhs_.BRESP &&
		//this.BVALID == rhs_.BVALID &&
		//this.BREADY == rhs_.BREADY &&
	
	//Read Address Channel
		this.ARID == rhs_.ARID &&
		this.ARADDR == rhs_.ARADDR &&
		this.ARLEN == rhs_.ARLEN &&
		this.ARSIZE == rhs_.ARSIZE &&
		this.ARBURST == rhs_.ARBURST &&
		//this.ARVALID == rhs_.ARVALID &&
		//this.ARREADY == rhs_.ARREADY &&
	
	//Read Data Channel
		this.RID == rhs_.RID &&
		this.RDATA == rhs_.RDATA &&
		this.RRESP == rhs_.RRESP ;
	//	this.RLAST == rhs_.RLAST &&
	//	this.RREADY == rhs_.RREADY;

		
	endfunction
		
endclass

