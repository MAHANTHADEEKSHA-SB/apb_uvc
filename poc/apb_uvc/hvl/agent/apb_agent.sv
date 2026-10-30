// -----------------------------------------------------------------------------
// apb_agent — non-parameterized APB UVC agent (ADR-001 decision 3)
//
// Retrieves its apb_agent_cfg ONCE from uvm_config_db (field "cfg", exact
// agent path) and passes it to its children (ADR-002 configuration flow,
// step 4). The monitor and optional coverage are always built; the sequencer
// and driver only when cfg.is_active == UVM_ACTIVE. Passive mode is a
// runtime choice and does not change what is compiled (ADR-002 decision 9).
// Included by apb_uvc_pkg.
// -----------------------------------------------------------------------------

class apb_agent extends uvm_agent;
  `uvm_component_utils(apb_agent)

  apb_agent_cfg                        cfg;
  apb_sequencer                        sequencer;
  apb_driver                           driver;
  apb_monitor                          monitor;
  apb_coverage                         coverage;
  uvm_analysis_port #(apb_transaction) ap;  // the monitor's port, re-exported

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Get this instance's cfg once (ADR-002 flow, step 4) and validate it. Build the
  // monitor (and coverage) always; the sequencer and driver only when active. The
  // children get the cfg handle directly and never query uvm_config_db (UVM-06).
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(apb_agent_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal("APB_AGENT", {"no apb_agent_cfg registered for ", get_full_name()})
    cfg.validate();
    `uvm_info("APB_AGENT", cfg.convert2string(), UVM_LOW)

    monitor     = apb_monitor::type_id::create("monitor", this);
    monitor.cfg = cfg;
    if (cfg.enable_coverage) begin
      coverage     = apb_coverage::type_id::create("coverage", this);
      coverage.cfg = cfg;
    end
    if (cfg.is_active == UVM_ACTIVE) begin
      sequencer     = apb_sequencer::type_id::create("sequencer", this);
      sequencer.cfg = cfg;
      driver        = apb_driver::type_id::create("driver", this);
      driver.cfg    = cfg;
    end
  endfunction

  // Re-export the monitor's port as ap, feed coverage, connect driver and sequencer.
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ap = monitor.ap;
    if (coverage != null) monitor.ap.connect(coverage.analysis_export);
    if (driver != null)   driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass : apb_agent
