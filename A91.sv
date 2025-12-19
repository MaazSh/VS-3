// Verification of Mux 4:1

`include "uvm_macros.svh"
import uvm_pkg::*;

class transaction extends uvm_sequence_item;
  
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
  
  virtual task body();
    t = transaction::type_id::create("t");
    
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
  virtual mux_if mux_if;
  
  function new(input string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    t = transaction::type_id::create("t");
  
  
    if(!uvm_config_db#(virtual mux_if)::get(this,"", "mux_if", mux_if)) begin
      `uvm_error("DRV", "unable to access uvm_config_db"); 
    end
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
      seq_item_port.item_done(); #10;
    end
  endtask
endclass

class monitor extends uvm_monitor;
  `uvm_component_utils(monitor);
  
  uvm_analysis_port #(transaction) send;
  transaction t;
  virtual mux_if mux_if;
  
  function new(input string path = "monitor", uvm_component parent = null);
    super.new(path, parent);
    send = new("send", this);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    t = transaction::type_id::create("t");
  
    if(!uvm_config_db #(virtual mux_if)::get(this, "", "mux_if", mux_if))
    `uvm_error("MON", "Unable to access uvm_config_db");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      #10;
      t.a = mux_if.a;
      t.b = mux_if.b;
      t.c = mux_if.c;
      t.d = mux_if.d;
      t.sel = mux_if.sel;
      t.y = mux_if.y;
      `uvm_info("MON", $sformatf("Data sent to scoreboard: a= %0d, b= %0d, c= %0d, d= %0d, sel= %0d, y= %0d", t.a, t.b, t.c, t.d, t.sel, t.y), UVM_NONE);
      send.write(t);
    end
  endtask
endclass

class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard);
  
  uvm_analysis_imp #(transaction, scoreboard) recv;
  transaction t;
  
  function new(input string path = "scoreboard", uvm_component parent = null);
    super.new(path, parent);
    recv = new("recv", this);
  endfunction
  
  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    t = transaction::type_id::create("t");
  endfunction
  
  virtual function void write(input transaction t1);
    t = t1;
    `uvm_info("MON", $sformatf("Data rcv from monitor: a= %0d, b= %0d, c= %0d, d= %0d, sel= %0d, y= %0d", t.a, t.b, t.c, t.d, t.sel, t.y), UVM_NONE);
    
    if ((t.sel == 2'b00 && t.y == t.a) || (t.sel == 2'b01 && t.y == t.b) || (t.sel == 2'b10 && t.y == t.c) || (t.sel == 2'b11 && t.y == t.d)) begin
      `uvm_info("SCO", "Test Passed", UVM_NONE)
      end else begin
        `uvm_info("SCO", "Test Failed", UVM_NONE) end
  endfunction
endclass

class agent extends uvm_agent;
  `uvm_component_utils(agent);
  
  monitor m;
  driver d;
  uvm_sequencer #(transaction) seqr;
  
  function new(input string path = "agent", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m = monitor::type_id::create("m", this);
    d = driver::type_id::create("d", this);
    seqr = uvm_sequencer #(transaction)::type_id::create("seqr", this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    d.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass

class env extends uvm_env;
  `uvm_component_utils(env);
  
  agent a;
  scoreboard s;
  
  function new(input string path = "env", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a = agent::type_id::create("a", this);
    s = scoreboard::type_id::create("s", this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    a.m.send.connect(s.recv);
  endfunction
endclass

class test extends uvm_test;
  `uvm_component_utils(test);
  
  env e;
  generator g;
  
  function new(input string path = "env", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e = env::type_id::create("env", this);
    g = generator::type_id::create("g", this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    g.start(e.a.seqr);
    #10;
    phase.drop_objection(this);
  endtask
endclass

module tb;
  
  mux_if mux_if();
  
  mux dut(.a(mux_if.a), .b(mux_if.b), .c(mux_if.c), .d(mux_if.d), .sel(mux_if.sel), .y(mux_if.y));
  
  initial begin
    uvm_config_db #(virtual mux_if)::set(null,"*", "mux_if", mux_if);
    run_test("test");
  end
endmodule
    
  --------------------------------------------------------------------------------------------------
// design

  module mux
  (
    input [3:0] a,b,c,d, ////input data port have size of 4-bit
    input [1:0] sel,     ////control port have size of 2-bit
    output reg [3:0] y 
  );
  
  always@(*)
    begin
      case(sel)
        2'b00: y = a;
        2'b01: y = b;
        2'b10: y = c;
        2'b11: y = d;
      endcase
    end
endmodule

interface mux_if();
  logic [3:0] a, b, c, d, y;
  logic [1:0] sel;
endinterface
    
                
  
     
    
    
    
                
