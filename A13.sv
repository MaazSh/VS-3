// Write a TB_TOP Code to send message with ID : CMP1 to console while blocking message with ID : CMP2. Do not change Component code.

`include "uvm_macros.svh"
import uvm_pkg::*;

class driver extends uvm_driver;
   `uvm_component_utils(driver)
  
  function new(string path , uvm_component parent);
    super.new(path, parent);
  endfunction
  
  task run();
    `uvm_info("CMP1", "Executed CMP1 Code", UVM_DEBUG);
    `uvm_info("CMP2", "Executed CMP2 Code", UVM_DEBUG);
  endtask
  
endclass

module tb;
  
  driver d;
  
  initial begin
    d = new("DRV", null);
  
    d.set_report_verbosity_level(UVM_DEBUG);
    d.set_report_id_action("CMP1", UVM_DISPLAY);
    d.set_report_id_action("CMP2", UVM_NO_ACTION);
    
    d.run();
    
  end
endmodule
