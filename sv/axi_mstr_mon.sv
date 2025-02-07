////////////////////////////////////////////////////////////////////////////////
//
// MIT License
//
// Copyright (c) 2025 Smartfox Data Solutions Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in 
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
////////////////////////////////////////////////////////////////////////////////

class axi_mstr_mon extends uvm_monitor;
   protected virtual axi_mstr_if vif;
   protected int id;

   uvm_analysis_port #(axi_mstr_txn) item_collected_port;

   protected axi_mstr_txn txn;

   `uvm_component_utils_begin(axi_mstr_mon)
      `uvm_field_int(id, UVM_DEFAULT)
   `uvm_component_utils_end

   function new (string name, uvm_component parent);
      super.new(name, parent);
      txn = new();
      item_collected_port = new("item_collected_port", this);
   endfunction // new

   function void build_phase (uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db#(virtual axi_mstr_if)::get(this, "", "vif", vif))
	`uvm_fatal("NOVIF",
		   {"virtual interface must be set for: ",
                    get_full_name(), ".vif"});
   endfunction // build_phase

   virtual task run_phase (uvm_phase phase);
      fork
	 collect_transactions();
      join
   endtask // run_phase

   virtual protected task collect_transactions();
      bit valid_txn = 0;
      forever begin
	 txn = new();
	 if (vif.rstn == 'b0) @(posedge vif.rstn);
	 @(posedge vif.clk);

	 // axi write transaction
	 if (vif.o_awvalid) begin
	    valid_txn  = 'b1;
            txn.trans  = WRITE;
	    // get write address
	    txn.axid   = vif.o_awid;
	    txn.addr   = vif.o_awaddr;
	    txn.length = vif.o_awlen;
	    txn.bsize  = vif.o_awsize;
            case (vif.o_awburst)
              'b00: txn.btype = FIXED;
              'b01: txn.btype = INCR;
              'b10: txn.btype = WRAP;
            endcase
	    // get write data
	    @(posedge vif.o_wvalid);
	    while (vif.o_wvalid) begin
	       if (vif.i_wready) txn.data = vif.o_wdata;
	       @(posedge vif.clk);
	       if (vif.o_wlast) break;
	    end
	    // wait write response
	    while (vif.i_bvalid != 'b1 && 
                   vif.o_bready != 'b1) begin
	       @(posedge vif.clk);
	    end	    
	 end

	 // axi read transaction
	 else if (vif.o_arvalid) begin
	    valid_txn  = 'b1;
            txn.trans  = READ;
	    // get read address
	    txn.axid   = vif.o_arid;
	    txn.addr   = vif.o_araddr;
	    txn.length = vif.o_arlen;
	    txn.bsize  = vif.o_arsize;
            case (vif.o_arburst)
              'b00: txn.btype = FIXED;
              'b01: txn.btype = INCR;
              'b10: txn.btype = WRAP;
            endcase
	    // get read data
	    @(posedge vif.i_rvalid);
	    while (vif.i_rvalid) begin
	       if (vif.o_rready) txn.data = vif.i_rdata;
	       @(posedge vif.clk);
	       if (vif.i_rlast) break;
	    end
	 end
	 else begin
	    valid_txn  = 'b0;	    
	 end
	 

         if (valid_txn == 'b1 ) begin
	   `uvm_info("MON", txn.convert2string(), UVM_LOW)
	    item_collected_port.write(txn);
	 end
      end
   endtask // collect_transactions
   
endclass // axi_mstr_mon
