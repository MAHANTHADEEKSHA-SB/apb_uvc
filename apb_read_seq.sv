class apb_read_seq extends apb_base_seq;
  `uvm_object_utils(apb_read_seq)
  function new(string name = "apb_read_seq");
    super.new(name);
  endfunction : new
  
  task body();
    apb_transfer trans;
    trans = apb_transfer :: type_id :: create("trans");
    start_item(trans);
    assert(trans.randomize() with {paddr == 'h5fc;
                                   pwrite == APB_READ;
                                   delay_kind == SHORT;
                                   });
    finish_item(trans);
  endtask : body
endclass : apb_read_seq