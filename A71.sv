// Send transaction data from COMPA to COMPB with the help of TLM PUT PORT to PUT IMP . Transaction class code is added in Instruction tab. Use UVM core print method to print the values of data members of transaction class.

`include "uvm_macros.svh"
import uvm_pkg::*;

class transaction extends uvm_sequence_item;
 
  bit [3:0] a = 12;
  bit [4:0] b = 24;
  int c = 256;
  
  function new(string inst = "transaction");
    super.new(inst);
  endfunction
  
  
  `uvm_object_utils_begin(transaction)
  `uvm_field_int(a, UVM_DEFAULT | UVM_DEC);
  `uvm_field_int(b, UVM_DEFAULT | UVM_DEC);
  `uvm_field_int(c, UVM_DEFAULT | UVM_DEC); 
  `uvm_object_utils_end
  
  
  
endclass

class producer extends uvm_component;
  `uvm_component_utils(producer);
  
  transaction t;
  uvm_blocking_put_port #(transaction) send;
  
  function new(input string path = "producer", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    t = new();
    send = new("send", this);
  endfunction
  
  task main_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("prod", $sformatf("Sent: a = %0d, b = %0d, c = %0d", t.a, t.b, t.c), UVM_NONE);
    send.put(t);
    phase.drop_objection(this);
  endtask
endclass

class consumer extends uvm_component;
  `uvm_component_utils(consumer);
  
  uvm_blocking_put_imp #(transaction, consumer) imp;
  
  function new(input string path = "consumer", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imp = new("imp", this);
  endfunction
  
  function void put(transaction t);
    t.print();
  endfunction
  
endclass

class env extends uvm_env;
  `uvm_component_utils(env);
  
  producer p;
  consumer c;
  
  function new(input string path = "env", uvm_component c);
    super.new(path, c);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    p = producer::type_id::create("p", this);
    c = consumer::type_id::create("c", this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    p.send.connect(c.imp);
  endfunction
  
endclass

class test extends uvm_test;
  `uvm_component_utils(test);
  
  env e;
  
  function new(input string name = "test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e = env::type_id::create("e", this);
  endfunction
  
endclass

module tb;
  
  initial begin
    run_test("test");
  end
endmodule
