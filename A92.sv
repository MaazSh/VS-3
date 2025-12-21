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
    
    if (!uvm_config_db #(virtual diff_if)::get(this, "", "dff_if", dff);
        `uvm_error("DRV", "Unable to access uvm_config_db");
  endfunction

   
  task reset();
    dff.rst <= 1'b1;
    dout <= 1'b0;
      
    repeat(5) @(posedge dff.clk);
      dff.rst <= 1'b0;
      `uvm_info("DRV", "Reset done", UVM_NONE);
    end
  endtask
    
  virtual task run_phase(uvm_phase phase);
    reset();
    forever begin
      seq_item_port.get_next_item(t);
      `uvm_info("DRV", $sformatf("Trigger DUT: din= %0d", dff.din), UVM_NONE);
    end
    @(posedge dff.clk);
  endtask
                
endclass
        
class monitor extends uvm_monitor;
  `uvm_component_utils(monitor);
  
  uvm_analysis_port #(transaction) send;
  transaction t;
  virtual dff_if dff;
  
  function new(input string path = "monitor", uvm_component parent = null);
    super.new(path, parent);
    send = new("send", this);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    t = transaction::type_id::create("t");
    if(!uvm_config_db #(virtual dff_if)::get(this, "", "dff_if", dff_if) begin
      `uvm_error("MON", "Unable to access uvm_config_db") end
  endfunction
       
  virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge dff.clk);
      t.din = dff.din;
      `uvm_info("MON", $sformatf("Data sent to scoreboard: din= %0d", dff.din), UVM_NONE);
      send_write(t);
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
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    t = transaction:type_id::create("t");
  endfunction
  
  virtual function void write(transaction t1);
    t = t1;
    `uvm_info("SCO", $sformatf("Data rcv from monitor: din= %0d, dout= %0d", t1.din, t1.dout), UVM_NONE);

    if ((t.reset == 1'b1) && t.din == (t.dout != 1'b0)) begin
      `uvm_error("SCO", "Reset Failed"); 
    end else 
      if (t.dout != t.din) begin
      `uvm_error("SCO", "Different DFF values"); 
    end else begin
      `uvm_info("SCO", "Test Passed"); end



/*    if (t.reset) begin
  if (t.dout !== 1'b0)
    `uvm_error("SCO", "Reset failed");
end
else begin
  if (t.dout !== prev_din)
    `uvm_error("SCO", "DFF mismatch");
end

prev_din = t.din; */
