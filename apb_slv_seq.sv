class apb_slave_seq extends uvm_sequence#(apb_transfer);
  `uvm_object_utils(apb_slave_seq)
  
  function new(string name = "apb_slave_seq");
    super.new(name);
  endfunction : new
  
  virtual task body();
    apb_transfer trans;
    trans = apb_transfer :: type_id :: create("trans");
    start_item(trans);
    assert(trans.randomize() with {paddr == 'h6fc;
                                   pwrite == APB_WRITE;
                                   delay_kind == ZERO;
                                   pslverr == 1'b0;
                                   });
    finish_item(trans);
  endtask : body
endclass : apb_slave_seq