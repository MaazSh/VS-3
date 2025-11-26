// Write a code to change the verbosity of the entire verification environment to UVM_DEBUG. To demonstrate successful configuration, print the value of the verbosity level on the console.

`include "uvm_macros.svh"
import uvm_pkg::*;

class driver extends uvm_driver;
  `uvm_component_utils(driver)
  
  function new(string path , uvm_component parent);
    super.new(path, parent);
  endfunction
  
  task run();
    `uvm_info("DRV", "Warning",UVM_MEDIUM);
    `uvm_info("DRV", "Warning2",UVM_DEBUG);
    `uvm_info("TEST", $sformatf("Verbosity level: %0d", this.get_report_verbosity_level()), UVM_NONE);
  endtask
endclass

module tb;
  driver d;
  
  initial begin
    d = new("DRV", null);
    
    d.set_report_verbosity_level(UVM_DEBUG);
   
    d.run();
  
  end
endmodule
