// -----------------------------------------------------------------------------
// apb_poc_base_test / apb_poc_test — POC acceptance test (step 6)
//
// apb_poc_base_test: common timeout and the result line
//   "TEST_RESULT: PASS|FAIL (<n> errors) <test>" from the report server.
// apb_poc_test: the DW=32 and DW=16 instances run concurrently with the same
//   non-parameterized agent classes (ADR-001 gate 1): directed traffic, then
//   constrained-random traffic across in-range and PSLVERR addresses.
//   Passes when both scoreboards checked traffic with no mismatch, each saw
//   a back-to-back transfer, and no monitor reported a protocol error.
// Included by apb_poc_test_pkg.
// -----------------------------------------------------------------------------

class apb_poc_base_test extends uvm_test;
  `uvm_component_utils(apb_poc_base_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Global watchdog: the test fails instead of hanging.
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_root::get().set_timeout(1ms, 1);
  endfunction

  // One machine-readable result line from the report server's error and fatal
  // counts; the only $display in UVM code (UVM-09).
  virtual function void report_phase(uvm_phase phase);
    uvm_report_server server = uvm_report_server::get_server();
    int errors = server.get_severity_count(UVM_ERROR) + server.get_severity_count(UVM_FATAL);
    super.report_phase(phase);
    $display("TEST_RESULT: %s (%0d errors) %s", errors == 0 ? "PASS" : "FAIL", errors,
             get_type_name());
  endfunction

endclass : apb_poc_base_test


// The same agent classes drive DW=32 and DW=16 at once (ADR-001 gate 1).
class apb_poc_test extends apb_poc_base_test;
  `uvm_component_utils(apb_poc_test)

  apb_poc_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // The env builds agent_c only if the DW=64 extension registered a cfg for it.
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = apb_poc_env::type_id::create("env", this);
  endfunction

  // All instances run concurrently; the drain time lets each monitor publish the
  // last transfer before the run phase ends.
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    phase.get_objection().set_drain_time(this, 200ns);  // let monitors publish the last transfer
    fork
      run_traffic(env.agent_a);
      run_traffic(env.agent_b);
      if (env.agent_c != null) run_traffic(env.agent_c);
    join
    phase.drop_objection(this);
  endtask

  // Directed traffic, then 30 random transfers including PSLVERR addresses (>= 0x100).
  protected task run_traffic(apb_agent agent);
    apb_poc_directed_seq directed = apb_poc_directed_seq::type_id::create("directed");
    apb_random_seq       rand_seq = apb_random_seq::type_id::create("rand_seq");
    directed.start(agent.sequencer);
    if (!rand_seq.randomize() with { num_items == 30; })
      `uvm_fatal("APB_POC", "cannot randomize apb_random_seq")
    rand_seq.addr_max = 'h1FF;  // upper half is beyond the fixture memory: PSLVERR
    rand_seq.start(agent.sequencer);
  endtask

  // Every scoreboard must have checked traffic and seen a back-to-back transfer.
  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    check_traffic(env.sb_a);
    check_traffic(env.sb_b);
    if (env.sb_c != null) check_traffic(env.sb_c);
  endfunction

  // Errors, not fatals: every instance is checked and reported.
  protected function void check_traffic(apb_poc_scoreboard sb);
    if (sb.num_checked == 0)
      `uvm_error("APB_POC", {sb.get_full_name(), ": no transfers checked"})
    if (sb.num_b2b == 0)
      `uvm_error("APB_POC", {sb.get_full_name(), ": no back-to-back transfer observed"})
  endfunction

endclass : apb_poc_test
