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


virtual class axi_mstr_base_seq extends uvm_sequence #(axi_mstr_txn);

   function new (string name="axi_mstr_base_seq");
      super.new(name);
   endfunction // new

endclass // axi_mstr_base_seq

class axi_mstr_no_activity_seq extends axi_mstr_base_seq;
   `uvm_object_utils(axi_mstr_no_activity_seq)
   
   function new(string name="axi_mstr_no_activity_seq");
      super.new(name);
   endfunction // new

   virtual task body();
      `uvm_info("SEQ", "executing", UVM_LOW)
   endtask // body
			    
endclass // axi_mstr_no_activity_seq

class axi_mstr_random_seq extends axi_mstr_base_seq;
   `uvm_object_utils(axi_mstr_random_seq)
   
   function new(string name="axi_mstr_random_seq");
      super.new(name);
   endfunction // new

   virtual task body();
      axi_mstr_txn item;
      int num_txn;
      bit[4:0] typ_txn;
      
      num_txn = $urandom_range(5,20);
     `uvm_info("SEQ", $psprintf("executing %0d transactions", num_txn), 
                      UVM_LOW)
      repeat(num_txn) begin
        `uvm_create(item)
         item.cycles = $urandom_range(10,20);
	 item.addr   = $urandom() & 32'hffff_fffc;
         item.data   = $urandom();
	 typ_txn     = $random();
	 item.trans  = typ_txn[0] ? WRITE : READ;
	 item.length = $urandom();
	 case (typ_txn[2:1])
            2'b00:  item.btype = FIXED;
	    2'b10:  item.btype = WRAP;
	    default:item.btype = INCR;
	 endcase // case (typ_txn[2:1])
	 // if wrapping burst
	 if (typ_txn[2:1] == 2'b10) begin
	    case (typ_txn[4:3])
	      2'b00: item.bsize = 1;
	      2'b01: item.bsize = 3;
	      2'b10: item.bsize = 7;
	      2'b11: item.bsize = 15;
	    endcase // case (typ_txn[4:3])	    
	 end
	 else begin
	    item.bsize = $urandom();
	 end
        `uvm_send(item);
      end
   endtask // body

endclass // axi_mstr_random_seq

class axi_mstr_directed_seq extends axi_mstr_base_seq;
   `uvm_object_utils(axi_mstr_directed_seq)
   
   function new(string name="axi_mstr_directed_seq");
      super.new(name);
   endfunction // new

   virtual task body();
      axi_mstr_txn item;
      int num_txn, txn_ctr;
      bit [4:0]  ttyp;
      bit [31:0] addr;
      bit [31:0] data;
      bit [ 3:0] blen;
      bit [ 2:0] bsiz;
      
      num_txn = $urandom_range(5,10) * 2;      
     `uvm_info("SEQ", $psprintf("executing %0d transactions", num_txn), 
                      UVM_LOW)

      for (txn_ctr = 0; txn_ctr < num_txn; txn_ctr ++) begin
	 // transfer type, 0: write, 1: read
	 if (~txn_ctr[0]) begin
	    addr = $urandom() & 32'hffff_fffc;
	    data = $urandom();
	    ttyp = $random();
	    blen = $urandom();
  	    // if wrapping burst
	    if (ttyp[2:1] == 2'b10) begin
	       case (ttyp[4:3])
		 2'b00: bsiz = 1;
	         2'b01: bsiz = 3;
	         2'b10: bsiz = 7;
	         2'b11: bsiz = 15;
	       endcase // case (ttyp[4:3])	    
	    end
	    else begin
	       bsiz = $urandom();
	    end
	 end

        `uvm_create(item)
         item.cycles = $urandom_range(10,20);
	 item.addr   = addr;
         item.data   = data;
	 item.trans  = txn_ctr[0] ? READ : WRITE;
	 item.length = blen;
	 case (ttyp[2:1])
            2'b00:  item.btype = FIXED;
	    2'b10:  item.btype = WRAP;
	    default:item.btype = INCR;
	 endcase // case (ttyp[2:1])
	 item.bsize  = bsiz;	 
        `uvm_send(item);

      end // repeat (txn_ctr)      
   endtask // body

endclass // axi_mstr_directed_seq
