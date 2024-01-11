class apb_transfer extends uvm_sequence_item;
  rand bit [`ADDR_WIDTH - 1 : 0] paddr;
  rand bit [`DATA_WIDTH - 1 : 0] pwdata;
  bit [`DATA_WIDTH - 1 : 0]      prdata;
  rand pwrite_e                  pwrite;
  rand apb_dly_e                 delay_kind;
  rand int unsigned              transmit_delay;
  rand bit                       pslverr;
  // Event pool
  uvm_event_pool events;

  constraint c_addr_valid { paddr[1 : 0] == 2'b00; }
  constraint c_data {(pwrite == APB_READ) -> pwdata == 0;}
  constraint c_delay { solve delay_kind before transmit_delay;
                      transmit_delay inside {[0 : 100]};
                      (delay_kind == ZERO)   -> transmit_delay == 0;
                      (delay_kind == SHORT)  -> transmit_delay inside { [1 : 10] };
                      (delay_kind == MEDIUM) -> transmit_delay inside { [11 : 29] };
                      (delay_kind == LONG)   -> transmit_delay inside { [30 : 100] };
                      (delay_kind == MAX)    -> transmit_delay == 100;
                      } 
  
  `uvm_object_utils_begin(apb_transfer)
    `uvm_field_int(paddr, UVM_DEFAULT)
    `uvm_field_int(pwdata, UVM_DEFAULT)
    `uvm_field_int(prdata, UVM_DEFAULT)
    `uvm_field_int(transmit_delay, UVM_DEFAULT | UVM_NOCOMPARE | UVM_NOPACK)
    `uvm_field_enum(pwrite_e, pwrite, UVM_DEFAULT | UVM_NOCOMPARE | UVM_NOPACK)
    `uvm_field_enum(apb_dly_e, delay_kind, UVM_DEFAULT | UVM_NOCOMPARE | UVM_NOPACK)
  `uvm_object_utils_end
  
  function new(string name = "apb_transfer");
    super.new(name);
    events = get_event_pool();
  endfunction : new
  
  // Trigger an event - called by driver
  function void trigger(string evnt);
    uvm_event e = events.get(evnt);
    e.trigger();
  endfunction: trigger
  
endclass : apb_transfer