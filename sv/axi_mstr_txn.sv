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
typedef enum { READ, WRITE }       axi_mstr_ttyp_e;
typedef enum { FIXED, INCR, WRAP } axi_mstr_btyp_e;

class axi_mstr_txn extends uvm_sequence_item;
   rand bit [ 3:0]      axid;
   rand bit [31:0]      addr;
   rand bit [31:0]      data;
   rand axi_mstr_ttyp_e trans;
   rand bit [ 3:0]      length;
   rand bit [ 2:0]      bsize;
   rand axi_mstr_btyp_e btype;
   rand int unsigned    cycles;

   constraint c_length {
      length inside { 0, 1, 3, 7, 15 };
   }   
   constraint c_cycles { 
      cycles <= 20;
   }

   `uvm_object_utils_begin(axi_mstr_txn)
      `uvm_field_int  (axid,   UVM_DEFAULT)
      `uvm_field_int  (addr,   UVM_DEFAULT)
      `uvm_field_int  (data,   UVM_DEFAULT)
      `uvm_field_enum (axi_mstr_ttyp_e, trans, UVM_DEFAULT)
      `uvm_field_int  (length, UVM_DEFAULT)
      `uvm_field_int  (bsize,  UVM_DEFAULT)
      `uvm_field_enum (axi_mstr_btyp_e, btype, UVM_DEFAULT)
      `uvm_field_int  (cycles, UVM_DEFAULT)
   `uvm_object_utils_end

   function new (string name = "axi_mstr_txn");
      super.new(name);
   endfunction // new

   function string convert2string();
      return $sformatf("A=0x%h::%s::L=%0d::B=%0d::%s::C=%0d",
		       addr, trans, length, bsize+1, btype, cycles);
   endfunction // convert2string
   
endclass // axi_mstr_txn
