// -----------------------------------------------------------------------------
// apb_poc_env — POC environment: instances of the same APB UVC agent
//
// agent_a (DW=32) and agent_b (DW=16) always; agent_c (DW=64 extension) only
// when the integration registered a cfg for it. Each agent feeds two checkers
// of its own: the fixture scoreboard (sb_*, a model of the example Completer)
// and the path scoreboard (path_*, requested versus observed transfers).
// This env is test code, not a reusable framework.
// Included by apb_poc_test_pkg.
// -----------------------------------------------------------------------------

class apb_poc_env extends uvm_env;
  `uvm_component_utils(apb_poc_env)

  apb_agent               agent_a;
  apb_agent               agent_b;
  apb_agent               agent_c;  // null unless the DW=64 extension is bound
  apb_poc_scoreboard      sb_a;
  apb_poc_scoreboard      sb_b;
  apb_poc_scoreboard      sb_c;
  apb_poc_path_scoreboard path_a;
  apb_poc_path_scoreboard path_b;
  apb_poc_path_scoreboard path_c;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // agent_a and agent_b always; agent_c with its checkers only when the integration
  // code registered a cfg for agent_c (DW=64 extension).
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent_a = apb_agent::type_id::create("agent_a", this);
    agent_b = apb_agent::type_id::create("agent_b", this);
    sb_a    = apb_poc_scoreboard::type_id::create("sb_a", this);
    sb_b    = apb_poc_scoreboard::type_id::create("sb_b", this);
    path_a  = apb_poc_path_scoreboard::type_id::create("path_a", this);
    path_b  = apb_poc_path_scoreboard::type_id::create("path_b", this);
    if (uvm_config_db#(apb_agent_cfg)::exists(this, "agent_c", "cfg")) begin
      agent_c = apb_agent::type_id::create("agent_c", this);
      sb_c    = apb_poc_scoreboard::type_id::create("sb_c", this);
      path_c  = apb_poc_path_scoreboard::type_id::create("path_c", this);
    end
  endfunction

  // Each agent's monitor feeds its own fixture scoreboard; its driver and monitor
  // together feed its path scoreboard.
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent_a.monitor.ap.connect(sb_a.analysis_export);
    agent_b.monitor.ap.connect(sb_b.analysis_export);
    if (agent_c != null) agent_c.monitor.ap.connect(sb_c.analysis_export);
    connect_path(agent_a, path_a);
    connect_path(agent_b, path_b);
    if (agent_c != null) connect_path(agent_c, path_c);
  endfunction

  // Finished driver items and monitor observations of one agent go to one path
  // scoreboard. A passive agent has no driver: its path scoreboard stays unconnected.
  protected function void connect_path(apb_agent agent, apb_poc_path_scoreboard path);
    if (agent.driver == null) return;
    agent.driver.done_ap.connect(path.done_export);
    agent.monitor.ap.connect(path.obs_export);
  endfunction

endclass : apb_poc_env
