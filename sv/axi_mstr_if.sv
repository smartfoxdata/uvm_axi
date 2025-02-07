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

interface axi_mstr_if;
   logic clk;
   logic rstn;
   // write address channel
   logic [ 3:0]	    o_awid;
   logic [31:0]     o_awaddr;
   logic [ 3:0]	    o_awlen;
   logic [ 2:0]     o_awsize;
   logic [ 1:0]	    o_awburst;
   logic [ 1:0]	    o_awlock;
   logic [ 3:0]	    o_awcache;   
   logic [ 2:0]     o_awprot;
   logic            o_awqos;
   logic            o_awregion;
   logic 	    o_awvalid;
   logic 	    i_awready;
   // write data channel
   //logic [ 3:0]   o_wid;  not supported in axi4
   logic [31:0]     o_wdata;
   logic [ 3:0]     o_wstrb;
   logic            o_wlast;
   logic 	    o_wvalid;
   logic 	    i_wready;
   // write response channel
   logic [ 3:0]     i_bid;     
   logic [ 1:0]	    i_bresp;
   logic 	    i_bvalid;
   logic 	    o_bready;
   // read address channel
   logic [ 3:0]	    o_arid;
   logic [31:0]     o_araddr;
   logic [ 3:0]	    o_arlen;
   logic [ 2:0]	    o_arsize;
   logic [ 1:0]	    o_arburst;
   logic [ 1:0]	    o_arlock;
   logic [ 3:0]	    o_arcache;   
   logic [ 2:0]     o_arprot;
   logic 	    o_arqos;
   logic	    o_arregion;
   logic 	    o_arvalid;
   logic 	    i_arready;
   // read data channel
   logic [ 3:0]	    i_rid;
   logic [31:0]     i_rdata;
   logic [ 1:0]     i_rresp;
   logic            i_rlast;
   logic 	    i_rvalid;
   logic 	    o_rready;
endinterface // axi_mstr_if
