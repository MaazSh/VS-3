// 1) Create a class "my_object" by extending the UVM_OBJECT class. Add three logic datatype datamembers "a", "b", and "c" with sizes of 2, 4, and 8 respectively.

// 2) Create two objects of my_object class in TB Top. Generate random data for data members of one of the object and then copy the data to other object by using clone method.

// 3) Compare both objects and send the status of comparison to Console using Standard UVM reporting macro. Add User defined implementation for the copy method.

`include "uvm_macros.svh"
import uvm_pkg::*;

class my_object extends uvm_object;
  
   function new(string path = "my_object");
    super.new(path);
  endfunction
  
  rand logic [1:0] a;
  rand logic [3:0] b;
  rand logic [7:0] c;
    
  `uvm_object_utils_begin(my_object)
  `uvm_field_int(a,UVM_DEFAULT);
  `uvm_field_int(b,UVM_DEFAULT);
  `uvm_field_int(c,UVM_DEFAULT);
  `uvm_object_utils_end
  
endclass

class second extends uvm_object;
  
  my_object o;

  
  function new(string path = "second");
    super.new(path);
    o = new("my_object");
  endfunction
  
  virtual function void do_copy (uvm_object rhs);
    second rhs1;
    $cast(rhs1, rhs);
    this.o = rhs1.o;
  endfunction
  
  `uvm_object_utils_begin(second)
  `uvm_field_object(o,UVM_DEFAULT);
  `uvm_object_utils_end
endclass

module tb;
  
  second obj1, obj2;
  int status = 0;
  
  initial begin
    obj1 = new("obj1");
    obj2 = new("obj2");
    
    obj1.o.randomize();
    obj2.copy(obj1);
    $cast(obj2, obj1.clone()); // clone method
    status = obj1.compare(obj2);
    $display("status: %0d", status);
    `uvm_info("TOP", $sformatf("compare value: %0d", status), UVM_MEDIUM); // do_copy
    obj1.print();
    obj2.print();
  end
endmodule
