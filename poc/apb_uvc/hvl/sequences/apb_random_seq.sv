// -----------------------------------------------------------------------------
// apb_random_seq — constrained-random APB transfers in an address window
//
// Direction, data, strobes (when PSTRB is present), PPROT (when present) and
// the IDLE gap are randomized within the item constraints, so back-to-back
// transfers (idle_cycles == 0) occur naturally.
// Included by apb_uvc_pkg.
// -----------------------------------------------------------------------------

class apb_random_seq extends apb_base_seq;
  `uvm_object_utils(apb_random_seq)

  rand int unsigned      num_items;
  logic [APB_MAX_AW-1:0] addr_min = '0;
  logic [APB_MAX_AW-1:0] addr_max = 'hFF;

  constraint c_num_items { soft num_items inside {[1:50]}; }

  function new(string name = "apb_random_seq");
    super.new(name);
    num_items = 20;
  endfunction

  virtual task body();
    apb_transaction t;
    repeat (num_items) begin
      t = new_item("random");
      start_item(t);
      if (!t.randomize() with { addr inside {[local::addr_min:local::addr_max]}; })
        `uvm_fatal("APB_SEQ", $sformatf("cannot randomize in [%0h:%0h]", addr_min, addr_max))
      finish_item(t);
    end
  endtask

endclass : apb_random_seq
