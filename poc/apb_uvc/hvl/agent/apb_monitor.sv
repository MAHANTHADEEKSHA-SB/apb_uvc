// -----------------------------------------------------------------------------
// apb_monitor — non-parameterized passive APB monitor (ADR-001 decision 3)
//
// Uses only the abstract observe capability from apb_agent_cfg. Works the
// same whether or not the agent is active, because the monitor BFM only
// reads pins (ADR-002 decision 9). Each completed transfer is published once
// on `ap`, at the completion point defined by the BFM (APB-R05).
//
// Protocol violations are counted in the BFM and reported in check_phase as
// uvm_error with ID "APB_PROTOCOL", one line per violation type. A negative
// test that expects them demotes that ID on this component and checks the
// counts through cfg.observe itself.
// Included by apb_uvc_pkg.
// -----------------------------------------------------------------------------

class apb_monitor extends uvm_monitor;
  `uvm_component_utils(apb_monitor)

  apb_agent_cfg                       cfg;  // set by apb_agent
  uvm_analysis_port #(apb_transaction) ap;
  int unsigned                        num_observed;

  protected apb_monitor_proxy_base observe;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (cfg == null)
      `uvm_fatal("APB_MON", "apb_agent_cfg not set by the agent")
    observe = cfg.observe;
    if (observe == null)
      `uvm_fatal("APB_MON", {cfg.get_name(), ": no observe proxy"})
  endfunction

  virtual function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    observe.set_verbose(cfg.monitor_verbose);
    if (!observe.configure(cfg.features))
      `uvm_fatal("APB_MON", {cfg.get_name(), ": monitor BFM rejected the feature set"})
    observe.set_publish(1'b1);
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_transaction t;
    forever begin
      observe.receive(t);
      num_observed++;
      `uvm_info("APB_MON", t.convert2string(), UVM_HIGH)
      ap.write(t);
    end
  endtask

  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    for (int c = 0; c < APB_MON_NUM_ERRORS; c++) begin
      apb_mon_error_e code = apb_mon_error_e'(c);
      int unsigned    n    = observe.get_error_count(code);
      if (n != 0)
        `uvm_error("APB_PROTOCOL", $sformatf("%s: %0d x %s", cfg.get_name(), n, code.name()))
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("APB_MON", $sformatf("%s: %0d transfers observed, %0d resets, %0d protocol errors",
                                   cfg.get_name(), num_observed, observe.get_reset_count(),
                                   observe.get_total_errors()), UVM_LOW)
  endfunction

endclass : apb_monitor
