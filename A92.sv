class transaction extends uvm_sequence_item;
  `uvm_object_utils(transaction);
  
  function new(input string path = "transaction");
    super.new(path);
  endfunction
  
  rand bit clk, rst, din;
  bit dout;
  
  `uvm_object_utils_begin(transaction)
  `uvm_field_int(clk, UVM_DEFAULT)
  `uvm_field_int(rst, UVM_DEFAULT)
  `uvm_field_int(din, UVM_DEFAULT)
  `uvm_field_int(dout, UVM_DEFAULT)
  `uvm_object_utils_end
  
endclass

class generator extends uvm_sequence #(transaction);
  `uvm_object_utils(generator);
  
  function new(input string path = "generator");
    super.new(path);
  endfunction
  
  virtual task body();
    t = transaction::type_id::create("t");
    
    repeat(5) begin
      start_item(t);
      t.randomize();
      finish_item(t);
      `uvm_info("GEN", $sformatf("Data sent to driver: clk= %0d, rst= %0d, din= %0d", t.clk, t.rst, t.din), UVM_NONE);
    end
  endtask
endclass
