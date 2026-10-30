// -----------------------------------------------------------------------------
// apb_negative_tests — configuration and boundary negative tests
//
// apb_cfg_negative_test: apb_agent_cfg::legality_error() must reject every
//   illegal configuration of APB_PROTOCOL_CONTRACT CFG-01..06 (including
//   cross-wired adapters of different widths) and accept the legal ones.
//   Uses the fake proxies, so no bus traffic is involved.
// apb_width_negative_test: a write whose data does not fit the DW=16 bus
//   must be rejected by the drive adapter (status APB_ST_BAD_REQUEST) and
//   must never reach the bus — no silent truncation (RISK-003).
// Included by apb_poc_test_pkg.
// -----------------------------------------------------------------------------

class apb_cfg_negative_test extends apb_poc_base_test;
  `uvm_component_utils(apb_cfg_negative_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Each case builds a fresh cfg on fake proxies and checks legality_error(); no
  // fatal is raised, so every case runs and reports.
  virtual task run_phase(uvm_phase phase);
    apb_agent_cfg c;
    phase.raise_objection(this);

    // Legal widths
    c = make_cfg(32, 32, 32, 32);
    expect_verdict("APB4 DW=32", c, "");

    c = make_cfg(32, 16, 32, 16);
    expect_verdict("APB4 DW=16", c, "");

    // CFG-06: adapters bound to different bus specializations
    c = make_cfg(32, 32, 32, 16);
    expect_verdict("cross-wired DW=32/16", c, "CFG-06");

    // CFG-03 / CFG-04: widths outside IHI 0024D
    c = make_cfg(33, 32, 33, 32);
    expect_verdict("AW=33", c, "CFG-03");

    c = make_cfg(32, 24, 32, 24);
    expect_verdict("DW=24", c, "CFG-04");

    c = make_cfg(32, 64, 32, 64);
    expect_verdict("DW=64 without opt-in", c, "CFG-04");

    c = make_cfg(32, 64, 32, 64);
    c.allow_nonstandard_width = 1'b1;
    expect_verdict("DW=64 with opt-in", c, "");

    // CFG-01: PSTRB/PPROT need APB4 or later
    c = make_cfg(32, 32, 32, 32);
    c.features.revision = APB3;
    expect_verdict("APB3 with PSTRB/PPROT", c, "CFG-01");

    c = make_cfg(32, 32, 32, 32);
    c.features.revision  = APB3;
    c.features.has_pstrb = 1'b0;
    c.features.has_pprot = 1'b0;
    expect_verdict("APB3 without PSTRB/PPROT", c, "");

    c = make_cfg(32, 32, 32, 32);
    c.features.revision  = APB2;
    c.features.has_pstrb = 1'b0;
    expect_verdict("APB2 with PPROT", c, "CFG-01");

    // CFG-02: APB5-only features; M2/M3 limits
    c = make_cfg(32, 32, 32, 32);
    c.features.has_pwakeup = 1'b1;
    expect_verdict("APB4 with PWAKEUP", c, "CFG-02");

    c = make_cfg(32, 32, 32, 32);
    c.features.revision    = APB5;
    c.features.has_pwakeup = 1'b1;
    expect_verdict("APB5 PWAKEUP (M2)", c, "PWAKEUP");

    c = make_cfg(32, 32, 32, 32);
    c.features.revision   = APB5;
    c.features.check_type = APB_CHECK_ODD_PARITY_BYTE_ALL;
    expect_verdict("APB5 parity (M3)", c, "parity");

    // Capability handles
    c = make_cfg(32, 32, 32, 32);
    c.drive = null;
    expect_verdict("active without drive", c, "active agent");

    c = make_cfg(32, 32, 32, 32);
    c.drive     = null;
    c.is_active = UVM_PASSIVE;
    expect_verdict("passive without drive", c, "");

    c = make_cfg(32, 32, 32, 32);
    c.observe = null;
    expect_verdict("no observe proxy", c, "no observe");

    phase.drop_objection(this);
  endtask

  // Fresh cfg (default APB4 features) whose fake proxies report the given widths.
  protected function apb_agent_cfg make_cfg(int unsigned drive_aw, int unsigned drive_dw,
                                            int unsigned observe_aw, int unsigned observe_dw);
    apb_agent_cfg          c = apb_agent_cfg::type_id::create("cfg_under_test");
    apb_fake_drive_proxy   d = new("fake_drive");
    apb_fake_monitor_proxy m = new("fake_observe");
    d.aw = drive_aw;
    d.dw = drive_dw;
    m.aw = observe_aw;
    m.dw = observe_dw;
    c.drive   = d;
    c.observe = m;
    return c;
  endfunction

  // want == "" means legal; otherwise the verdict must start with want
  protected function void expect_verdict(string what, apb_agent_cfg c, string want);
    string got = c.legality_error();
    bit    ok  = (want == "") ? (got == "") : (got.substr(0, want.len() - 1) == want);
    if (ok)
      `uvm_info("APB_CFG_NEG", $sformatf("ok: %s -> \"%s\"", what, got), UVM_LOW)
    else
      `uvm_error("APB_CFG_NEG", $sformatf("FAIL: %s -> \"%s\", expected %s", what, got,
                                          want == "" ? "legal" : {"\"", want, "...\""}))
  endfunction

endclass : apb_cfg_negative_test


// Builds the POC env and drives one unfit write on instance B (DW=16).
class apb_width_negative_test extends apb_poc_base_test;
  `uvm_component_utils(apb_width_negative_test)

  apb_poc_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Full POC env: real adapters on the real bus.
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = apb_poc_env::type_id::create("env", this);
  endfunction

  // Pass if the adapter rejected the write (APB_ST_BAD_REQUEST) and the monitor saw
  // nothing on the bus: no silent truncation (DATA-02, RISK-003).
  virtual task run_phase(uvm_phase phase);
    apb_unfit_write_seq seq = apb_unfit_write_seq::type_id::create("unfit");
    phase.raise_objection(this);
    // The adapter's rejection is the expected outcome (reported via uvm_root)
    uvm_root::get().set_report_severity_id_override(UVM_ERROR, "APB_REQ", UVM_INFO);
    seq.start(env.agent_b.sequencer);
    #200ns;
    if (seq.result.status != APB_ST_BAD_REQUEST)
      `uvm_error("APB_WIDTH_NEG", {"unfit write was not rejected: ", seq.result.convert2string()})
    if (env.agent_b.cfg.observe.get_transfer_count() != 0)
      `uvm_error("APB_WIDTH_NEG", "unfit write reached the bus")
    phase.drop_objection(this);
  endtask

endclass : apb_width_negative_test
