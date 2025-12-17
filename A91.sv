// Code your testbench here
// or browse Examples
`include "uvm_macros.svh"
import uvm_pkg::*;

class transaction extends uvm_sequence_item
  
  rand bit [3:0] a, b, c, d;
  rand bit [1:0] sel;
  bit [3:0] y;
  
  function new(input string path = "transaction");
    super.new(path);
  endfunction
  
  `uvm_object_utils_begin(transaction)
  `uvm_field_int(a, UVM_DEFAULT)
  `uvm_field_int(b, UVM_DEFAULT)
  `uvm_field_int(c, UVM_DEFAULT)
  `uvm_field_int(d, UVM_DEFAULT)
  `uvm_field_int(sel, UVM_DEFAULT)
  `uvm_field_int(y, UVM_DEFAULT)
  `uvm_object_utils_end
endclass

class generator extends uvm_sequence #(transaction);
  `uvm_object_utils(generator);
  
  transaction t;
  
  function new(input string path = "generator");
    super.new(path);
  endfunction
  
  virtual task send();
    t = transaction:type_id::create("t");
    
    repeat(5) begin
      start_item(t);
      t.randomize();
      `uvm_info("GEN", $sformatf("Data sent to driver: a = %0d, b = %0d, c = %0d, d = %0d, sel = %0d", t.a, t.b, t.c, t.d, t.sel), UVM_NONE);
      finish_item(t);
    end
  endtask
endclass

class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver);
  
  transaction t;
  virtual mux mux_if
  
  function new(input string path = "driver");
    super.new(path);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    t = transaction::type_id::create("t");
  endfunction
  
  if(!uvm_config_db(virtual mux)::get(this,"", mux_if, mux_if));
  `uvm_error("DRV", "unable to access uvm_config_db");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(t);
      
      mux_if.a <= t.a;
      mux_if.b <= t.b;
      mux_if.c <= t.c;
      mux_if.d <= t.d;
      mux_if.sel <= t.sel;
      
      `uvm_info("DRV", $sformatf("Trigger DUT: a= %0d, b= %0d, c= %0d, d= %0d, sel= %0d", t.a, t.b, t.c, t.d, t.sel), UVM_NONE);
      seq_item_port.item_done();
    end
  endtask
endclass

class monitor extends uvm_monitor
  `uvm_component_utils(monitor);
  
  uvm_analysis_port #(transaction) send;
  transaction t;
  virtual mux mux_if;
  
  function new(input string path = "monitor");
    super.new(path);
    send = new("send", this);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    t = transaction::type_id::create("t");
  
  if(!uvm_config_db #(virtual mux)::get(this, "", mux_if, mux_if))
    `uvm_error("MON", "Unable to access uvm_config_db");
  endfunction
  
  virtual task recv(uvm_phase phase);
    forever begin
      #10;
      t.a = mux_if.a;
      t.b = mux_if.b;
      t.c = mux_if.c;
      t.d = mux_if.d;
      t.sel = mux_if.sel;
      t.y = mux_if.y;
      `uvm_info("MON", $sformatf("Data sent to scoreboard: a= %0d, b= %0d, c= %0d, d= %0d, sel= %0d, y= %0d", t.a, t.b, t.c, t.d, t.sel, t.y));
      send.write(t);
    end
  endtask
endclass

class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard);
  
  uvm_analysis_imp #(transaction, scoreboard) recv;
  transaction t;
  
  function new(input string path = "scoreboard");
    super.new(path);
    recv = new("recv", this);
  endfunction
  
  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    t = transaction::type_id::create("t");
  endfunction
  
  virtual function void write(input transaction t1);
    t = t1;
    `uvm_info("MON", $sformatf("Data rcv from monitor: a= %0d, b= %0d, c= %0d, d= %0d, sel= %0d, y= %0d", t.a, t.b, t.c, t.d, t.sel, t.y));
    
    if ((sel == 2'b00 && t.a) | (sel == 2'b01 && t.b) | (sel == 2'b10 && t.c) | (sel == 2'b11 && t.d))
      `uvm_info("SCO", "Test Passed", UVM_NONE);
    else
      `uvm_info("SCO", "Test Failed", UVM_NONE);
  endfunction
endclass

class agent extends uvm_agent;
  `uvm_component_utils(agent);
  
  monitor m;
  driver d;
  uvm_sequencer #(transaction) seqr;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m = monitor::type_id::create("m", this);
    d = driver::type_id::create("d", this);
    seqr = uvm_sequencer #(transaction)::type_id::create("seqr", this);
  endfunction
  
  
    
                
  
     
    
    
    
                
