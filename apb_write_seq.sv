class apb_write_seq extends apb_base_seq;
  
  `uvm_object_utils(apb_write_seq)
  
  function new(string name = "apb_write_seq");
    super.new(name);
  endfunction : new
  
  virtual task body();
    apb_transfer trans;
    trans = apb_transfer :: type_id :: create("trans");
    start_item(trans);
    assert(trans.randomize() with {paddr == 'h5fc;
                                   pwrite == APB_WRITE;
                                   delay_kind == SHORT;
                                   pslverr == 1'b0;
                                   });
    finish_item(trans);
  endtask : body
endclass : apb_write_seq