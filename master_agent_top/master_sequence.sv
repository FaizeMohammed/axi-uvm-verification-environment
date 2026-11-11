class master_sequence extends uvm_sequence#(axi_trans);
	`uvm_object_utils(master_sequence)

	function new(string name="master_sequence");
		super.new(name);
	endfunction

endclass

// Fixed Burst Sequence (AWBURST = 2'b00, ARBURST = 2'b00)
class fixed_burst_seq extends master_sequence;
	`uvm_object_utils(fixed_burst_seq)


	function new(string name="fixed_burst_seq");
		super.new(name);
	endfunction

	task body();
	repeat(5)
		begin
		req=axi_trans::type_id::create("req");
		start_item(req);
		assert(req.randomize() with {AWBURST == 2'b00; ARBURST == 2'b00;});
		finish_item(req);
		end
		#1000;
	endtask
endclass

// Increment Burst Sequence (AWBURST = 2'b01, ARBURST = 2'b01)
class increment_burst_seq extends master_sequence;
	`uvm_object_utils(increment_burst_seq)

	function new(string name="increment_burst_seq");
		super.new(name);
	endfunction

	task body();
	repeat(5)
		begin
		req=axi_trans::type_id::create("req");
		
		start_item(req);
		assert(req.randomize() with {AWBURST == 2'b01; ARBURST == 2'b01;});
		finish_item(req);

		end
		#1000;
	endtask
endclass

// Wrap Burst Sequence (AWBURST = 2'b10, ARBURST = 2'b10)
class wrap_burst_seq extends master_sequence;
	`uvm_object_utils(wrap_burst_seq)

	function new(string name="wrap_burst_seq");
		super.new(name);
	endfunction

	task body();
		repeat(5)
		 begin
		req=axi_trans::type_id::create("req");
		
		start_item(req);
		assert(req.randomize() with {AWBURST == 2'b10; ARBURST == 2'b10;});
		finish_item(req);
		end
		#1000;

	endtask
endclass

// Comprehensive Random Sequence (For Maximum Functional Coverage)
class master_seq_random extends master_sequence;
	`uvm_object_utils(master_seq_random)

	function new(string name="master_seq_random");
		super.new(name);
	endfunction

	task body();
		// 1. Fully Random Transactions
		repeat(40) begin
			req = axi_trans::type_id::create("req");
			start_item(req);
			assert(req.randomize());
			finish_item(req);
		end

		// 2. Fixed Burst Stress
		repeat(10) begin
			req = axi_trans::type_id::create("req");
			start_item(req);
			assert(req.randomize() with {
				AWBURST == 2'b00;
				ARBURST == 2'b00;
			});
			finish_item(req);
		end

		// 3. Increment Burst Stress
		repeat(10) begin
			req = axi_trans::type_id::create("req");
			start_item(req);
			assert(req.randomize() with {
				AWBURST == 2'b01;
				ARBURST == 2'b01;
			});
			finish_item(req);
		end

		// 4. Wrap Burst Stress
		repeat(10) begin
			req = axi_trans::type_id::create("req");
			start_item(req);
			assert(req.randomize() with {
				AWBURST == 2'b10;
				ARBURST == 2'b10;
			});
			finish_item(req);
		end

		// 5. Short Burst Length Corner Cases
		repeat(10) begin
			req = axi_trans::type_id::create("req");
			start_item(req);
			assert(req.randomize() with {
				AWBURST == 2'b00;
				ARBURST == 2'b00;
				AWLEN   == 4'd2;
				AWSIZE  == 3'b000; // 1-byte transfer
			});
			finish_item(req);
		end

		repeat(10) begin
			req = axi_trans::type_id::create("req");
			start_item(req);
			assert(req.randomize() with {
				AWBURST == 2'b00;
				ARBURST == 2'b00;
				AWLEN   == 4'd2;
				AWSIZE  == 3'b001; // 2-byte transfer
			});
			finish_item(req);
		end

		#1000;
	endtask
endclass

