// -----------------------------------------------------------------------------
// apb_poc_seqs — test sequences for the POC fixture
//
// apb_poc_directed_seq: the same directed traffic as the HDL smoke test,
//   expressed in UVM: 0 and 2 wait states (PADDR[5:4]), a back-to-back
//   write->read, a PSTRB lane-0 rewrite (when PSTRB is present) and a
//   PSLVERR read beyond the fixture memory. Each read is checked here against
//   the pattern this sequence wrote (RV-001); the bus-level behaviour is
//   checked by apb_poc_scoreboard and apb_poc_path_scoreboard.
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

  bit check_data = 1'b1;  // 0: the test expects wrong data on this instance

  function new(string name = "apb_poc_directed_seq");
    super.new(name);
  endfunction

  // Data patterns are masked to the instance width, so the same sequence runs on
  // DW=16, 32 and 64. The strobed rewrite needs PSTRB and is skipped without it.
  // Every read is checked against what was written before it (check_read).
  virtual task body();
    apb_transaction        t;
    int unsigned           dw    = p_sequencer.cfg.data_width();
    logic [APB_MAX_DW-1:0] mask  = '0;
    logic [APB_MAX_SW-1:0] lane0 = 1;
    logic [APB_MAX_DW-1:0] d1, d2, d3, d4;

    for (int unsigned i = 0; i < dw; i++) mask[i] = 1'b1;
    d1 = APB_MAX_DW'(P1) & mask;
    d2 = APB_MAX_DW'(P2) & mask;
    d3 = APB_MAX_DW'(P3) & mask;
    d4 = APB_MAX_DW'(P4) & mask;

    do_write('h00, d1, t);
    do_read ('h00, t);
    check_read(t, APB_ST_OK, d1);
    do_write('h20, d2, t);                           // 2 wait states
    do_read ('h20, t);
    check_read(t, APB_ST_OK, d2);
    do_write('h04, d3, t);
    do_read ('h04, t, 0);                            // back-to-back
    check_read(t, APB_ST_OK, d3);
    do_write('h08, d4, t);
    if (p_sequencer.cfg.features.has_pstrb) begin
      do_write_strb('h08, mask, lane0, t);           // lane 0 only, data all ones
      d4[7:0] = 8'hFF;
    end
    do_read ('h08, t);
    check_read(t, APB_ST_OK, d4);
    do_read ('h100, t);                              // PSLVERR
    check_read(t, APB_ST_SLVERR, '0);
  endtask

  // Check the item the driver completed in place: its status and, for a read that
  // ended OK, its data (a read error may return anything, APB-R12). This is the only
  // check of the response a sequence gets back; skipped when check_data is 0.
  protected function void check_read(apb_transaction t, apb_bfm_status_e want_status,
                                     logic [APB_MAX_DW-1:0] want_data);
    if (!check_data) return;
    if (t.status != want_status) begin
      `uvm_error("APB_POC", $sformatf("read @%0h ended %s, expected %s",
                                      t.addr, t.status.name(), want_status.name()))
    end else if (want_status == APB_ST_OK && t.rdata !== want_data) begin
      `uvm_error("APB_POC", $sformatf("read @%0h returned %0h, expected %0h",
                                      t.addr, t.rdata, want_data))
    end
  endfunction

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
