// -----------------------------------------------------------------------------
// apb_fault_injection_test — negative test: injected faults must be detected
//
// Runs the apb_poc_test traffic with a driver-BFM fault on instance A only
// (+APB_FAULT=<n>, apb_fault_e; default 1 = PADDR changed in a wait state).
// Instance A's monitor errors (ID "APB_PROTOCOL") are expected, so they are
// demoted to info and its scoreboard is disabled. The test passes only if
//   * A's monitor counted the violation that matches the fault, and
//   * instance B stayed clean (isolation): its scoreboard and monitor report
//     nothing and it still saw back-to-back traffic.
// Included by apb_poc_test_pkg.
// -----------------------------------------------------------------------------

class apb_fault_injection_test extends apb_poc_test;
  `uvm_component_utils(apb_fault_injection_test)

  apb_fault_e fault = APB_FAULT_PADDR_UNSTABLE;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void start_of_simulation_phase(uvm_phase phase);
    int unsigned arg;
    super.start_of_simulation_phase(phase);
    if ($value$plusargs("APB_FAULT=%d", arg)) fault = apb_fault_e'(arg);
    if (fault == APB_FAULT_NONE)
      `uvm_fatal("APB_FAULT", "+APB_FAULT=0 selects no fault")
    env.agent_a.cfg.drive.set_fault(fault);
    env.agent_a.monitor.set_report_severity_id_override(UVM_ERROR, "APB_PROTOCOL", UVM_INFO);
    env.sb_a.enabled = 1'b0;
    `uvm_info("APB_FAULT", $sformatf("injecting %s on %s", fault.name(), env.agent_a.get_full_name()),
              UVM_LOW)
  endfunction

  // Replaces apb_poc_test::check_phase: instance A is expected to misbehave
  virtual function void check_phase(uvm_phase phase);
    apb_mon_error_e want;
    case (fault)
      APB_FAULT_PADDR_UNSTABLE: want = APB_MON_ERR_UNSTABLE_IN_ACCESS;
      APB_FAULT_SKIP_SETUP:     want = APB_MON_ERR_ACCESS_WITHOUT_SETUP;
      default:                  want = APB_MON_ERR_PSEL_DROPPED_IN_ACCESS;
    endcase
    if (env.agent_a.cfg.observe.get_error_count(want) == 0)
      `uvm_error("APB_FAULT", $sformatf("injected %s was NOT detected (%s count is 0)",
                                        fault.name(), want.name()))
    else
      `uvm_info("APB_FAULT", $sformatf("detected: %0d x %s", env.agent_a.cfg.observe.get_error_count(want),
                                       want.name()), UVM_LOW)
    if (env.agent_b.cfg.observe.get_total_errors() != 0)
      `uvm_error("APB_FAULT", "instance B reported protocol errors: fault leaked across instances")
    check_traffic(env.sb_b);
  endfunction

endclass : apb_fault_injection_test
