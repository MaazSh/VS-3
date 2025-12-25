// Verification of DFF

`include "uvm_macros.svh"
import uvm_pkg::*;

class transaction extends uvm_sequence_item;
 // `uvm_object_utils(transaction);
  
  function new(input string path = "transaction");
    super.new(path);
  endfunction
  
  rand bit din;
  bit rst, dout, clk;
  
  `uvm_object_utils_begin(transaction)
  `uvm_field_int(clk, UVM_DEFAULT)
  `uvm_field_int(rst, UVM_DEFAULT)
  `uvm_field_int(din, UVM_DEFAULT)
  `uvm_field_int(dout, UVM_DEFAULT)
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
      finish_item(t);
      `uvm_info("GEN", $sformatf("Data sent to driver: din= %0d", t.din), UVM_NONE);
    end
  endtask
endclass
  
class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver);
  
  function new(input string path, uvm_component name);
    super.new(path, name);
  endfunction
  
  transaction t;
  virtual dff_if dff;
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    t = transaction::type_id::create("t");
    
    if (!uvm_config_db #(virtual dff_if)::get(this, "", "dff", dff)) begin
      `uvm_error("DRV", "Unable to access uvm_config_db") end
  endfunction
    
  task reset();
    dff.rst <= 1'b1;
    dff.dout <= 1'b0;
      
    repeat(5) @(posedge dff.clk);
      dff.rst <= 1'b0;
      `uvm_info("DRV", "Reset done", UVM_NONE);
  endtask
    
  virtual task run_phase(uvm_phase phase);
    reset();
    forever begin
      seq_item_port.get_next_item(t);
      dff.din <= t.din;
      @(posedge dff.clk);
      seq_item_port.item_done();
      `uvm_info("DRV", $sformatf("Trigger DUT: din= %0d", t.din), UVM_NONE);
    end
    @(posedge dff.clk);
  endtask
                
endclass
        
class monitor extends uvm_monitor;
  `uvm_component_utils(monitor);
  
  uvm_analysis_port #(transaction) send;
  transaction tr;
  virtual dff_if dff;
  
  function new(input string path = "monitor", uvm_component parent = null);
    super.new(path, parent);
    send = new("send", this);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr = transaction::type_id::create("tr");
    if(!uvm_config_db #(virtual dff_if)::get(this, "", "dff", dff)) begin
      `uvm_error("MON", "Unable to access uvm_config_db") end
  endfunction
       
  virtual task run_phase(uvm_phase phase);
//    @(negedge dff.rst);
    forever begin
      @(posedge dff.clk);
      tr.din = dff.din;
      tr.dout = dff.dout;
      tr.rst = dff.rst;
      tr.clk = dff.clk;
      `uvm_info("MON", $sformatf("Data sent to scoreboard: din= %0d, dout= %0d", tr.din, tr.dout), UVM_NONE);
      send.write(tr);
    end
  endtask

 covergroup cg; // Added on to assignment
    option.per_instance = 1;
      
    din: coverpoint tr.din {bins zero = {0}; bins one = {1};}
    dout: coverpoint tr.dout {bins zero = {0}; bins one = {1};}
    rst: coverpoint tr.rst {bins low = {0}; bins high = {1};}
    
    cross din, dout {bins zero_zero = binsof(din) intersect {0} && binsof(dout) intersect {0};
                       bins one_one = binsof(dout) intersect {1} && binsof(dout) intersect {1};}
  endgroup
 
endclass
       
class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard);
  
  bit prevDin;
  uvm_analysis_imp #(transaction, scoreboard) recv;
  transaction t;
  
  function new(input string path = "scoreboard", uvm_component parent = null);
    super.new(path, parent);
    recv = new("recv", this);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    t = transaction::type_id::create("t");
  endfunction
  
  virtual function void write(transaction t1);
    t = t1;
    `uvm_info("SCO", $sformatf("Data rcv from monitor: din= %0d, dout= %0d, rst= %0d, clk= %0d", t1.din, t1.dout, t1.rst, t1.clk), UVM_NONE);
    
    if (t.rst) begin
      if(t1.dout != 1'b0)
        `uvm_error("SCO", "Reset Failed")
    end else begin
      if(t1.dout != prevDin)
        `uvm_error("SCO", "DFF values do not match")
      else
        `uvm_info("SCO", "Test Passed", UVM_NONE)
    end
    
    prevDin = t1.din;     
    
  endfunction
endclass
       
class agent extends uvm_agent;
  `uvm_component_utils(agent);
  
  monitor m;
  driver d;
  uvm_sequencer #(transaction) seq;
  
  function new(input string path = "agent", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m = monitor::type_id::create("m", this);
    d = driver::type_id::create("d", this);
    seq = uvm_sequencer #(transaction)::type_id::create("seq", this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    d.seq_item_port.connect(seq.seq_item_export);
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
  
  function new(input string path = "test", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e = env::type_id::create("e", this);
    g = generator::type_id::create("g", this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    g.start(e.a.seq);
    #10;
    e.a.d.reset(); // Test reset
    #10;
    phase.drop_objection(this);
  endtask
endclass
       
module tb;
  
  dff_if dff();
  
  initial begin
    dff.clk = 0;
    dff.rst = 0;
  end
  
  always #10 dff.clk = ~dff.clk;
  
  dff dut(.clk(dff.clk), .rst(dff.rst), .din(dff.din), .dout(dff.dout));
  
  initial begin
    uvm_config_db #(virtual dff_if)::set(null, "*", "dff", dff);
    run_test("test");
  end
endmodule

-------------------------------------------------------------------------------------------
// design

module dff
  (
    input clk, rst, din, ////din - data input, rst - active high synchronus
    output reg dout ////dout - data output
  );
  
  always@(posedge clk)
    begin
      if(rst == 1'b1) 
        dout <= 1'b0;
      else
        dout <= din;
    end
  
endmodule

interface dff_if();
  logic clk, rst, din, dout;
endinterface
