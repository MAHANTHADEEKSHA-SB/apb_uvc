// -----------------------------------------------------------------------------
// apb_poc_env — POC environment: instances of the same APB UVC agent
//
// agent_a (DW=32) and agent_b (DW=16) always; agent_c (DW=64 extension) only
// when the integration registered a cfg for it. Each agent feeds its own
// fixture scoreboard. This env is test code, not a reusable framework.
// Included by apb_poc_test_pkg.
// -----------------------------------------------------------------------------

class apb_poc_env extends uvm_env;
  `uvm_component_utils(apb_poc_env)

  apb_agent          agent_a;
  apb_agent          agent_b;
  apb_agent          agent_c;  // null unless the DW=64 extension is bound
  apb_poc_scoreboard sb_a;
  apb_poc_scoreboard sb_b;
  apb_poc_scoreboard sb_c;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent_a = apb_agent::type_id::create("agent_a", this);
    agent_b = apb_agent::type_id::create("agent_b", this);
    sb_a    = apb_poc_scoreboard::type_id::create("sb_a", this);
    sb_b    = apb_poc_scoreboard::type_id::create("sb_b", this);
    if (uvm_config_db#(apb_agent_cfg)::exists(this, "agent_c", "cfg")) begin
      agent_c = apb_agent::type_id::create("agent_c", this);
      sb_c    = apb_poc_scoreboard::type_id::create("sb_c", this);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent_a.monitor.ap.connect(sb_a.analysis_export);
    agent_b.monitor.ap.connect(sb_b.analysis_export);
    if (agent_c != null) agent_c.monitor.ap.connect(sb_c.analysis_export);
  endfunction

endclass : apb_poc_env
