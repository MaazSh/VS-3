// Design an environment consisting of a single producer class "PROD" and three subscribers viz., iz. "SUB1", "SUB2", and "SUB3". Add logic such that the producer broadcasts the name of the coder and all the subscribers are able to receive the string data sent by the producer. If Zen is writing the logic, then the producer should broadcast the string "ZEN" and all the subscribers must receive "ZEN".

`include "uvm_macros.svh"
import uvm_pkg::*;

class PROD extends uvm_component;
  `uvm_component_utils(PROD);
  
  uvm_analysis_port #(string) port;
  
  string coder = "ZEN";
  
  function new(input string path = "PROD", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    port = new("port", this);
  endfunction
  
  task main_phase(uvm_phase phase);
    phase.raise_objection(this);
    port.write(coder);
    `uvm_info("PROD", $sformatf("Coder broadcasted: %s", coder), UVM_NONE);
    phase.drop_objection(this);
  endtask
endclass

class SUB1 extends uvm_component;
  `uvm_component_utils(SUB1);
  
  uvm_analysis_imp #(string, SUB1) imp;
  
  function new(input string path = "SUB1", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imp = new("imp", this);
  endfunction
  
  function void write(string coderr);
    `uvm_info("SUB1", $sformatf("Coder recv: %s", coderr), UVM_NONE);
  endfunction
endclass

class SUB2 extends uvm_component;
  `uvm_component_utils(SUB2);
  
  uvm_analysis_imp #(string, SUB2) imp;
  
  function new(input string path = "SUB2", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imp = new("imp", this);
  endfunction
  
  function void write(string coderr);
    `uvm_info("SUB2", $sformatf("Coder recv: %s", coderr), UVM_NONE);
  endfunction
endclass

class SUB3 extends uvm_component;
  `uvm_component_utils(SUB3);
  
  uvm_analysis_imp #(string, SUB3) imp;
  
  function new(input string path = "SUB3", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imp = new("imp", this);
  endfunction
  
  function void write(string coderr);
    `uvm_info("SUB3", $sformatf("Coder recv: %s", coderr), UVM_NONE);
  endfunction
endclass

class env extends uvm_env;
  `uvm_component_utils(env);
  
  PROD p;
  SUB1 s1;
  SUB2 s2;
  SUB3 s3;
  
  function new(input string path = "env", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    p = PROD::type_id::create("p", this);
    s1 = SUB1::type_id::create("s1", this);
    s2 = SUB2::type_id::create("s2", this);
    s3 = SUB3::type_id::create("s3", this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    p.port.connect(s1.imp);
    p.port.connect(s2.imp);
    p.port.connect(s3.imp);
  endfunction
endclass

class test extends uvm_test;
  `uvm_component_utils(test);
  
  env e;
  
  function new(input string path = "test", uvm_component parent = null);
    super.new(path, parent);
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
