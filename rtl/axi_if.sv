interface axi_if(input ACLK);

	logic ARESETn;

//write address channel signals

logic [3:0]AWID; 
logic [31:0]AWADDR;
logic [3:0]AWLEN;
logic [2:0]AWSIZE;
logic [1:0]AWBURST;
bit AWVALID;
bit AWREADY; //slave

//write data channel signals

logic [3:0]WID;
logic [31:0]WDATA;
logic [3:0]WSTRB;
logic WLAST;
logic WVALID;
logic WREADY; //slave

//write response channel signals

logic [3:0]BID; //slave all
logic [1:0]BRESP;
logic BVALID;
logic BREADY; //master

//Read address channel signals

logic [3:0]ARID; 
logic [31:0]ARADDR;
logic [3:0]ARLEN;
logic [2:0]ARSIZE;
logic [1:0]ARBURST;

logic ARVALID;
logic ARREADY; //slv


//Read data channel signals

logic [3:0]RID;
logic [31:0]RDATA;
logic [1:0]RRESP;
logic RLAST;
logic RVALID;
logic RREADY;//master


	clocking master_drv_cb @(posedge ACLK);
		default  input#1 output #1;
		output AWID,AWADDR,AWLEN,AWSIZE,AWBURST,AWVALID;
		output WID,WDATA,WSTRB,WLAST,WVALID;
		output BREADY;
		output ARID,ARADDR,ARLEN,ARSIZE,ARBURST,ARVALID;
		output RREADY;

		input AWREADY,WREADY,ARREADY;
		input RID,RDATA,RRESP,RLAST,RVALID; 
		input BID,BRESP,BVALID;
	endclocking 

	clocking slave_drv_cb @(posedge ACLK);
		default input #1 output #1;
	
		output AWREADY,WREADY,ARREADY;
		output BID,BRESP,BVALID;
		output RID,RDATA,RRESP,RLAST,RVALID;
		input ARID,ARADDR,ARLEN,ARSIZE,ARBURST,ARVALID;
	
		input AWID,AWADDR,AWLEN,AWSIZE,AWBURST,AWVALID;
		input WID,WDATA,WSTRB,WLAST,WVALID;
		input BREADY;
		input RREADY;

	endclocking

	clocking monitor_cb @(posedge ACLK);
		default input #1 output #1;

		input AWREADY,WREADY,ARREADY;
		input BID,BRESP,BVALID;
		input RID,RDATA,RRESP,RLAST,RVALID;
		
		input AWID,AWADDR,AWLEN,AWSIZE,AWBURST,AWVALID;
		input WID,WDATA,WSTRB,WLAST,WVALID;
		input BREADY;
		input ARID,ARADDR,ARLEN,ARSIZE,ARBURST,ARVALID;
		input RREADY;
	
	endclocking

	modport M_DRV_MP(clocking master_drv_cb);
	modport S_DRV_MP(clocking slave_drv_cb);
	modport MON_MP(clocking monitor_cb);



endinterface

