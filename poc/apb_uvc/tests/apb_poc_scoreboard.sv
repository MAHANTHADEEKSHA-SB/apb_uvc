// -----------------------------------------------------------------------------
// apb_poc_scoreboard — reference model of examples/apb_example_slave
//
// Test infrastructure, not part of the reusable UVC core (contract: no
// DUT-specific scoreboards in the core). It models the fixture's documented
// behaviour for one instance:
//   * byte memory of mem_bytes bytes; PSTRB byte-lane writes; reads return
//     the aligned word; unwritten bytes read 0
//   * wait states = PADDR[5:4]
//   * PSLVERR for addresses >= mem_bytes; such writes change nothing
// It also counts back-to-back transfers (SETUP right after a completion).
// Included by apb_poc_test_pkg.
// -----------------------------------------------------------------------------

class apb_poc_scoreboard extends uvm_subscriber #(apb_transaction);
  `uvm_component_utils(apb_poc_scoreboard)

  int unsigned mem_bytes = 256;   // must match apb_example_slave MEM_BYTES
  bit          enabled   = 1'b1;  // a fault-injection test turns checking off

  int unsigned num_checked;
  int unsigned num_mismatches;
  int unsigned num_b2b;

  protected byte unsigned     mem[int unsigned];
  protected longint unsigned  prev_end;
  protected bit               has_prev;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void write(apb_transaction t);
    int unsigned nbytes    = t.bus_data_width / 8;
    int unsigned a         = t.addr;
    int unsigned base      = a - (a % nbytes);
    bit          exp_err   = (a >= mem_bytes);
    int unsigned exp_waits = (a >> 4) & 3;

    if (has_prev && t.start_cycle == prev_end + 1) num_b2b++;
    prev_end = t.end_cycle;
    has_prev = 1'b1;
    if (!enabled) return;

    num_checked++;
    if (t.slverr !== exp_err)
      mismatch(t, $sformatf("slverr %b, expected %b", t.slverr, exp_err));
    if (t.wait_states != exp_waits)
      mismatch(t, $sformatf("%0d wait states, expected %0d", t.wait_states, exp_waits));
    if (exp_err) return;

    if (t.dir == APB_WRITE) begin
      for (int unsigned i = 0; i < nbytes; i++)
        if (t.strb[i] === 1'b1) mem[base + i] = t.wdata[8*i +: 8];
    end else begin
      logic [APB_MAX_DW-1:0] expected = '0;
      for (int unsigned i = 0; i < nbytes; i++)
        expected[8*i +: 8] = mem.exists(base + i) ? mem[base + i] : 8'h00;
      if (t.rdata !== expected)
        mismatch(t, $sformatf("rdata %0h, expected %0h", t.rdata, expected));
    end
  endfunction

  protected function void mismatch(apb_transaction t, string what);
    num_mismatches++;
    `uvm_error("APB_SB", {get_full_name(), ": ", what, " | ", t.convert2string()})
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("APB_SB", $sformatf("%s: %0d checked, %0d mismatches, %0d back-to-back",
                                  get_full_name(), num_checked, num_mismatches, num_b2b), UVM_LOW)
  endfunction

endclass : apb_poc_scoreboard
