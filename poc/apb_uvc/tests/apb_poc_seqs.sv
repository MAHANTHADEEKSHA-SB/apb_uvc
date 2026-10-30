// -----------------------------------------------------------------------------
// apb_poc_seqs — test sequences for the POC fixture
//
// apb_poc_directed_seq: the same directed traffic as the HDL smoke test,
//   expressed in UVM: 0 and 2 wait states (PADDR[5:4]), a back-to-back
//   write->read, a PSTRB lane-0 rewrite (when PSTRB is present) and a
//   PSLVERR read beyond the fixture memory. Data is checked by
//   apb_poc_scoreboard.
// apb_unfit_write_seq: a write whose data does not fit the bus, to prove
//   the drive adapter rejects it instead of truncating (RISK-003).
// Included by apb_poc_test_pkg.
// -----------------------------------------------------------------------------

class apb_poc_directed_seq extends apb_base_seq;
  `uvm_object_utils(apb_poc_directed_seq)

  localparam logic [63:0] P1 = 64'hA5A5_5A5A_DEAD_BEEF;
  localparam logic [63:0] P2 = 64'h0123_4567_89AB_CDEF;
  localparam logic [63:0] P3 = 64'hFEDC_BA98_7654_3210;
  localparam logic [63:0] P4 = 64'h1357_9BDF_2468_ACE0;

  function new(string name = "apb_poc_directed_seq");
    super.new(name);
  endfunction

  // Data patterns are masked to the instance width, so the same sequence runs on
  // DW=16, 32 and 64. The strobed rewrite needs PSTRB and is skipped without it.
  virtual task body();
    apb_transaction        t;
    int unsigned           dw    = p_sequencer.cfg.data_width();
    logic [APB_MAX_DW-1:0] mask  = '0;
    logic [APB_MAX_SW-1:0] lane0 = 1;

    for (int unsigned i = 0; i < dw; i++) mask[i] = 1'b1;

    do_write('h00, APB_MAX_DW'(P1) & mask, t);
    do_read ('h00, t);
    do_write('h20, APB_MAX_DW'(P2) & mask, t);      // 2 wait states
    do_read ('h20, t);
    do_write('h04, APB_MAX_DW'(P3) & mask, t);
    do_read ('h04, t, 0);                            // back-to-back
    do_write('h08, APB_MAX_DW'(P4) & mask, t);
    if (p_sequencer.cfg.features.has_pstrb)
      do_write_strb('h08, mask, lane0, t);           // lane 0 only
    do_read ('h08, t);
    do_read ('h100, t);                              // PSLVERR
  endtask

endclass : apb_poc_directed_seq


// Negative-test helper: one write whose data is wider than the bus.
class apb_unfit_write_seq extends apb_base_seq;
  `uvm_object_utils(apb_unfit_write_seq)

  apb_transaction result;

  function new(string name = "apb_unfit_write_seq");
    super.new(name);
  endfunction

  // The completed item is kept in result for the test to inspect.
  virtual task body();
    apb_transaction t = new_item("unfit");
    start_item(t);
    t.c_fit_bus.constraint_mode(0);
    // Only the data is out of range; everything else stays legal
    if (!t.randomize() with { dir == APB_WRITE; addr == 'h10; wdata == 'hDEAD_BEEF;
                              sel == 0; idle_cycles == 1; })
      `uvm_fatal("APB_SEQ", "cannot randomize the unfit write")
    finish_item(t);
    result = t;
  endtask

endclass : apb_unfit_write_seq
