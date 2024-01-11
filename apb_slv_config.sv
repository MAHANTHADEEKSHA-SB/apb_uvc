class apb_slave_config extends uvm_object;
   uvm_active_passive_enum is_active = UVM_ACTIVE;
  
  int wait_cycles = 0;
  bit[`ADDR_WIDTH - 1 : 0] start_addr,end_addr;
  
  `uvm_object_utils_begin(apb_slave_config)
  `uvm_field_int(start_addr, UVM_DEFAULT)
  `uvm_field_int(end_addr, UVM_DEFAULT)
  `uvm_field_int(wait_cycles,UVM_DEFAULT)
  `uvm_field_enum(uvm_active_passive_enum, is_active,UVM_DEFAULT)
  `uvm_object_utils_end
  
  function new(string name = "apb_slave_config");
    super.new(name);
  endfunction : new
  
endclass : apb_slave_config