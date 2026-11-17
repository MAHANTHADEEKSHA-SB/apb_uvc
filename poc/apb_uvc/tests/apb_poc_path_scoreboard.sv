// -----------------------------------------------------------------------------
// apb_poc_path_scoreboard — ties the drive path to the observe path (RV-001)
//
// Test infrastructure, not part of the reusable UVC core. The fixture
// scoreboard (apb_poc_scoreboard) is fed only by the monitor, so it shows that
// the bus is self-consistent, not that the bus carried what the sequence
// asked for. This component does: every item the driver finished with status
// OK or SLVERR must be matched by exactly one observed transfer, in order,
// with the same request and response values (ADR-001 gates 2 and 3:
// per-instance isolation, no silent truncation, round-trip payload).
//
// An item that ended any other way (reset abort, timeout, rejected request,
// injected fault) did not complete on the bus, so no observation is expected
// for it. The driver and the monitor report a completion in the same time
// step in either order, so both sides are queued and matched pairwise.
// A reset in the same time step as a completion is not handled yet
// (REVIEW_FEEDBACK RV-003).
//
// Also declares the two analysis-imp flavours it uses (FILE-02 helpers).
// Included by apb_poc_test_pkg.
// -----------------------------------------------------------------------------

// Give the two exports below their own write functions: write_apb_done() for
// finished driver items and write_apb_obs() for monitor observations.
`uvm_analysis_imp_decl(_apb_done)
`uvm_analysis_imp_decl(_apb_obs)

class apb_poc_path_scoreboard extends uvm_component;
  `uvm_component_utils(apb_poc_path_scoreboard)

  uvm_analysis_imp_apb_done #(apb_transaction, apb_poc_path_scoreboard) done_export;
  uvm_analysis_imp_apb_obs  #(apb_transaction, apb_poc_path_scoreboard) obs_export;

  int unsigned num_matched;     // pairs that compared equal
  int unsigned num_mismatches;  // pairs that differ
  int unsigned num_skipped;     // finished items that did not complete on the bus

  protected apb_transaction sent_q[$];  // finished OK/SLVERR items awaiting an observation
  protected apb_transaction seen_q[$];  // observations awaiting a finished item

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // done_export connects to apb_driver.done_ap, obs_export to apb_monitor.ap.
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    done_export = new("done_export", this);
    obs_export  = new("obs_export", this);
  endfunction

  // A finished driver item. Only OK and SLVERR mean the transfer completed on the bus
  // (APB-R05); any other status is counted and expects no observation.
  virtual function void write_apb_done(apb_transaction t);
    if (!(t.status inside {APB_ST_OK, APB_ST_SLVERR})) begin
      num_skipped++;
      return;
    end
    sent_q.push_back(t);
    match();
  endfunction

  // An observed transfer from the monitor.
  virtual function void write_apb_obs(apb_transaction t);
    seen_q.push_back(t);
    match();
  endfunction

  // Compare the oldest finished item with the oldest observation while both exist.
  // compare() covers the bus-visible request and response fields with 4-state
  // equality (apb_transaction::do_compare); wait states and status are checked here.
  protected function void match();
    apb_transaction sent;
    apb_transaction seen;
    while (sent_q.size() != 0 && seen_q.size() != 0) begin
      sent = sent_q.pop_front();
      seen = seen_q.pop_front();
      if (sent.compare(seen) && sent.wait_states == seen.wait_states &&
          sent.status == seen.status) begin
        num_matched++;
      end else begin
        num_mismatches++;
        `uvm_error("APB_PATH", {get_full_name(), ": requested and observed transfers differ",
                                "\n  sent: ", sent.convert2string(),
                                "\n  seen: ", seen.convert2string()})
      end
    end
  endfunction

  // Every finished OK/SLVERR item must have been observed, and nothing may have
  // completed on the bus that the driver did not finish (ADR-001 gate 2). These use
  // their own report ID, so a test that expects APB_PATH mismatches still sees them.
  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (sent_q.size() != 0)
      `uvm_error("APB_PATH_COUNT", $sformatf("%s: %0d finished transfers were never observed",
                                             get_full_name(), sent_q.size()))
    if (seen_q.size() != 0)
      `uvm_error("APB_PATH_COUNT", $sformatf("%s: %0d observed transfers were never requested",
                                             get_full_name(), seen_q.size()))
  endfunction

  // Summary line per instance.
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("APB_PATH", $sformatf("%s: %0d matched, %0d mismatches, %0d not on the bus",
                                    get_full_name(), num_matched, num_mismatches, num_skipped),
              UVM_LOW)
  endfunction

endclass : apb_poc_path_scoreboard
