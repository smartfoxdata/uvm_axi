////////////////////////////////////////////////////////////////////////////////
//
// MIT License
//
// Copyright (c) 2017 Smartfox Data Solutions Inc.
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


class axi_mstr_drv extends uvm_driver #(axi_mstr_txn);
   protected virtual axi_mstr_if vif;
   protected int id;

   `uvm_component_utils_begin(axi_mstr_drv)
      `uvm_field_int(id, UVM_DEFAULT)
   `uvm_component_utils_end

   function new (string name, uvm_component parent);
      super.new(name, parent);
   endfunction // new

   function void build_phase (uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual axi_mstr_if)::get(this, "", "vif", vif))
	`uvm_fatal("NOVIF", {"virtual interface must be set for: ",
			     get_full_name(), ".vif"});
   endfunction // build_phase

   virtual task run_phase (uvm_phase phase);
      fork
	 get_and_drive();
	 reset_signals();
      join
   endtask // run_phase

   virtual protected task get_and_drive();
      forever begin
	 @(posedge vif.clk);
	 if (vif.rstn == 1'b0) begin
	   @(posedge vif.rstn);
 	   @(posedge vif.clk);
	 end
	 seq_item_port.get_next_item(req);
	 `uvm_info("DRV", req.convert2string(), UVM_LOW)

	 repeat(req.cycles) begin
	    @(posedge vif.clk);
	 end
         drive_transfer(req);
	 seq_item_port.item_done();
      end
   endtask // get_and_drive

   virtual protected task reset_signals();
      forever begin
	 @(negedge vif.rstn);
	 vif.o_awid      <= 'b0;
	 vif.o_awaddr    <= 'h0;
	 vif.o_awlen     <= 'h0;
         vif.o_awsize    <= 'h0;
         vif.o_awburst   <= 'h0;
         vif.o_awlock    <= 'h0;
         vif.o_awcache   <= 'h0;   
         vif.o_awprot    <= 'h0;
         vif.o_awqos     <= 'h0;
         vif.o_awregion  <= 'h0;
         vif.o_awvalid   <= 'h0;
         //vif.o_wid     <= 'h0; not supported in axi4
	 vif.o_wdata     <= 'h0;
         vif.o_wstrb     <= 'h0;
         vif.o_wlast     <= 'h0;
         vif.o_wvalid    <= 'h0;
	 vif.o_bready    <= 'h0;
	 vif.o_arid      <= 'h0;
         vif.o_araddr    <= 'h0;
         vif.o_arlen     <= 'h0;
         vif.o_arsize    <= 'h0;
         vif.o_arburst   <= 'h0;
         vif.o_arlock    <= 'h0;
         vif.o_arcache   <= 'h0;
         vif.o_arprot    <= 'h0;
         vif.o_arqos     <= 'h0;
         vif.o_arregion  <= 'h0;
         vif.o_arvalid   <= 'h0;
	 vif.o_rready    <= 'h0;
      end
   endtask // reset_signals

   // drive_transfer
   virtual protected task drive_transfer (axi_mstr_txn txn);
      case (txn.trans)
        WRITE: do_wr_trans(txn);
	READ : do_rd_trans(txn);
      endcase // case (txn.trans)      
   endtask : drive_transfer

   // do write transfer
   virtual protected task do_wr_trans (axi_mstr_txn txn);
      bit werr;
     `uvm_info("DRV", "do_wr_trans", UVM_LOW)
      drv_wr_chan(txn, werr);
      if (~werr) drv_wr_data(txn, werr);
      if (~werr) get_wr_resp(txn, werr);
   endtask: do_wr_trans

   // drive write address channel
   virtual protected task drv_wr_chan (axi_mstr_txn txn,
                                       output bit tout);
      int to_ctr;
      @(posedge vif.clk);
      vif.o_awid    <= txn.axid;
      vif.o_awaddr  <= txn.addr;
      vif.o_awlen   <= txn.length;
      vif.o_awsize  <= 'b10; //txn.bsize;
      case (txn.btype)
         FIXED: vif.o_awburst <= 'b00;
         INCR : vif.o_awburst <= 'b01;
         WRAP : vif.o_awburst <= 'b10;
      endcase
      vif.o_awprot  <= 'h0;
      vif.o_awvalid <= 'b1;
      for(to_ctr = 0; to_ctr <= 31; to_ctr++) begin
         @(posedge vif.clk);
         if (vif.i_awready) break;
      end
      if (to_ctr == 31) `uvm_error("DRV","AWREADY timeout");
      tout = (to_ctr == 31) ? 1 : 0;
      vif.o_awvalid <= 'b0;    
   endtask: drv_wr_chan

   // drive write data channel
   virtual protected task drv_wr_data (axi_mstr_txn txn,
                                       output bit tout);
      int to_ctr, b_ctr;
      bit[31:0] dt_seed, wr_data;

      dt_seed = txn.addr; //txn.data;
      wr_data = $random(dt_seed);
      @(posedge vif.clk);

      // send data
      for(b_ctr = 0; b_ctr < txn.length; b_ctr++) begin
         vif.o_wvalid <= 'b1;
         vif.o_wstrb  <= 'hf;
	 vif.o_wdata  <= wr_data;
         for(to_ctr = 0; to_ctr <= 31; to_ctr++) begin
            @(posedge vif.clk);
            if (vif.i_wready) break;
         end
         if (to_ctr == 31) begin
           `uvm_error("DRV","WREADY timeout");
	    tout = 1;
	    break;	    
	 end
	 else tout = 0;
	 dt_seed = dt_seed + 4; //wr_data;
	 wr_data = $random(dt_seed);
      end // for (b_ctr = 0; b_ctr <= txn.length; b_ctr++)
      // send last data
      if (~tout) begin
	 vif.o_wdata <= wr_data; //txn.data;
	 vif.o_wlast <= 'b1;
	 @(posedge vif.clk);
      end
      vif.o_wlast  <= 'b0;
      vif.o_wvalid <= 'b0;
      vif.o_wstrb  <= 'h0;
      vif.o_wdata  <= 'h0;
   endtask: drv_wr_data

   // check write response
   virtual protected task get_wr_resp (axi_mstr_txn txn,
                                       output bit werr);
      int to_ctr;
      @(posedge vif.clk);

      vif.o_bready <= 'b1;
      for(to_ctr = 0; to_ctr <= 31; to_ctr++) begin
         @(posedge vif.clk);
         if (vif.i_bvalid) break;
      end
      if (to_ctr == 31) begin
         `uvm_error("DRV","BVALID timeout");
      end
      else begin
	 if (vif.i_bid != txn.axid) `uvm_error("DRV","BID mismatched");
	 if (vif.i_bresp != 'h0) `uvm_error("DRV","ERROR write response");
      end
      if (to_ctr == 31 || vif.i_bid != txn.axid || vif.i_bresp != 'h0)
	   werr = 'b1;
      else werr = 'b0;
      vif.o_bready <= 'b0;
   endtask: get_wr_resp

   // do read transfer
   virtual protected task do_rd_trans (axi_mstr_txn txn);
      bit rerr;
     `uvm_info("DRV", "do_rd_trans", UVM_LOW)
      drv_rd_chan(txn, rerr);
      if (~rerr) get_rd_data(txn, rerr);
   endtask: do_rd_trans

   // drive read address channel
   virtual protected task drv_rd_chan (axi_mstr_txn txn,
                                       output bit tout);
      int to_ctr;
      @(posedge vif.clk);
      vif.o_arid    <= txn.axid;
      vif.o_araddr  <= txn.addr;
      vif.o_arlen   <= txn.length;
      vif.o_arsize  <= 'b10;  //txn.bsize;
      case (txn.btype)
         FIXED: vif.o_arburst <= 'b00;
         INCR : vif.o_arburst <= 'b01;
         WRAP : vif.o_arburst <= 'b10;
      endcase
      vif.o_arprot  <= 'h0;
      vif.o_arvalid <= 'b1;
      for(to_ctr = 0; to_ctr <= 31; to_ctr++) begin
         @(posedge vif.clk);
         if (vif.i_arready) break;
      end
      if (to_ctr == 31) `uvm_error("DRV","ARREADY timeout");
      tout = (to_ctr == 31) ? 1 : 0;
      vif.o_arvalid <= 'b0;    
   endtask: drv_rd_chan

   // get read data
   virtual protected task get_rd_data (axi_mstr_txn txn,
                                       output bit rerr);
      int to_ctr, d_ctr;
      bit tout;      
      @(posedge vif.clk);

      vif.o_rready <= 'b1;

      // receive data
      for(d_ctr = 0; d_ctr <= txn.length; d_ctr++) begin
         for(to_ctr = 0; to_ctr <= 31; to_ctr++) begin
            @(posedge vif.clk);
            if (vif.i_rvalid) break;
         end
	 tout = (to_ctr == 31) ? 1 : 0;
         if (to_ctr == 31) break;
      end // for (d_ctr = 0; d_ctr <= txn.length; d_ctr++)
      if (vif.i_rlast != 'b1) `uvm_error("DRV","RLAST not asserted");

      if (tout == 1) begin
        `uvm_error("DRV","RVALID timeout");
      end
      else begin
	 if (vif.i_rid != txn.axid) `uvm_error("DRV","RID mismatched");
	 if (vif.i_rresp != 'h0) `uvm_error("DRV","ERROR read response");
      end

      if (tout == 1 || vif.i_rid != txn.axid || vif.i_rresp != 'h0)
	   rerr = 'b1;
      else rerr = 'b0;

      vif.o_rready <= 'b0;
   endtask: get_rd_data

endclass // axi_mstr_drv
