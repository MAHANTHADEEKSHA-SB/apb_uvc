// -----------------------------------------------------------------------------
// apb_base_seq — base sequence with single-transfer helpers
//
// new_item() gives every item the bus context of the agent the sequence runs
// on, so randomized values always fit that instance (lossless rule). The
// helpers randomize after start_item() and return the completed item, whose
// response fields were filled in place by apb_driver.
// Protocol-generic: no DUT register map or memory model lives here.
// Included by apb_uvc_pkg.
// -----------------------------------------------------------------------------

class apb_base_seq extends uvm_sequence #(apb_transaction);
  `uvm_object_utils(apb_base_seq)
  `uvm_declare_p_sequencer(apb_sequencer)

  function new(string name = "apb_base_seq");
    super.new(name);
  endfunction

  // New item carrying the bus context of the agent this sequence runs on (DATA-03).
  // Requires the sequence to run on an apb_sequencer (p_sequencer).
  protected function apb_transaction new_item(string name = "item");
    apb_agent_cfg   cfg = p_sequencer.cfg;
    apb_transaction t   = apb_transaction::type_id::create(name);
    t.set_bus_context(cfg.addr_width(), cfg.data_width(), cfg.num_sel(),
                      cfg.features.has_pstrb, cfg.features.has_pprot);
    return t;
  endfunction

  // Full-width write
  task do_write(input  logic [APB_MAX_AW-1:0] addr,
                input  logic [APB_MAX_DW-1:0] data,
                output apb_transaction        t,
                input  int unsigned           idle = 1);
    t = new_item("write");
    start_item(t);
    if (!t.randomize() with { dir == APB_WRITE; addr == local::addr; wdata == local::data;
                              strb == full_strb(); idle_cycles == local::idle; })
      `uvm_fatal("APB_SEQ", $sformatf("cannot randomize write @%0h", addr))
    finish_item(t);
  endtask

  // Write with explicit byte strobes (needs PSTRB on the instance)
  task do_write_strb(input  logic [APB_MAX_AW-1:0] addr,
                     input  logic [APB_MAX_DW-1:0] data,
                     input  logic [APB_MAX_SW-1:0] strb,
                     output apb_transaction        t,
                     input  int unsigned           idle = 1);
    t = new_item("write_strb");
    start_item(t);
    if (!t.randomize() with { dir == APB_WRITE; addr == local::addr; wdata == local::data;
                              strb == local::strb; idle_cycles == local::idle; })
      `uvm_fatal("APB_SEQ", $sformatf("cannot randomize strobed write @%0h strb=%0h", addr, strb))
    finish_item(t);
  endtask

  // Read; on return the item holds rdata, slverr, wait_states and status.
  task do_read(input  logic [APB_MAX_AW-1:0] addr,
               output apb_transaction        t,
               input  int unsigned           idle = 1);
    t = new_item("read");
    start_item(t);
    if (!t.randomize() with { dir == APB_READ; addr == local::addr; idle_cycles == local::idle; })
      `uvm_fatal("APB_SEQ", $sformatf("cannot randomize read @%0h", addr))
    finish_item(t);
  endtask

endclass : apb_base_seq
