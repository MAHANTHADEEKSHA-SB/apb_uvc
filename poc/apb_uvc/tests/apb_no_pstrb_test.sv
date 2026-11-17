// -----------------------------------------------------------------------------
// apb_no_pstrb_test — an instance without PSTRB reports full-width writes (RV-002)
//
// Reconfigures instance B as APB3 (no PSTRB, no PPROT) before its agent is
// built, then runs the apb_poc_test traffic. A write request on such an
// instance carries every lane set (IHI 0024D Table 3-1), so the monitor must
// report the same strobes: B's path scoreboard must match every transfer.
// Before the RV-002 change the monitor reported no lanes and every write
// mismatched.
//
// The example Completer on bus B is wired as APB4 without the Table 3-1
// tie-off, so with PSTRB driven LOW it ignores writes. B's fixture scoreboard
// and its read-back checks are therefore switched off here; the full APB3
// integration test with a tied-off fixture is still a known gap
// (WORK_STATUS). Instance A stays APB4 with every check on.
// Included by apb_poc_test_pkg.
// -----------------------------------------------------------------------------

class apb_no_pstrb_test extends apb_poc_test;
  `uvm_component_utils(apb_no_pstrb_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Change B's feature set before the env builds agent_b, which validates the cfg and
  // pushes it to both BFMs. The cfg object is the one the integration code registered.
  virtual function void build_phase(uvm_phase phase);
    apb_agent_cfg cfg_b;
    super.build_phase(phase);
    if (!uvm_config_db#(apb_agent_cfg)::get(this, "env.agent_b", "cfg", cfg_b))
      `uvm_fatal("APB_NO_PSTRB", "no apb_agent_cfg registered for env.agent_b")
    cfg_b.features.revision  = APB3;
    cfg_b.features.has_pstrb = 1'b0;
    cfg_b.features.has_pprot = 1'b0;
  endfunction

  // The fixture on bus B cannot model an APB3 write (see the header).
  virtual function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    env.sb_b.enabled = 1'b0;
  endfunction

  // The fixture ignores B's writes, so only A's directed sequence checks its
  // read-back data.
  protected virtual function bit checks_data(apb_agent agent);
    return agent != env.agent_b;
  endfunction

endclass : apb_no_pstrb_test
