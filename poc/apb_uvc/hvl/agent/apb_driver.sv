// -----------------------------------------------------------------------------
// apb_driver — non-parameterized APB Requester driver (ADR-001 decision 3)
//
// Uses only the abstract drive capability from apb_agent_cfg; it never sees a
// virtual interface. Items are updated in place with the response (rdata,
// slverr, wait_states, status) before item_done(), so a sequence reads the
// result from the item it sent.
//
// Reset (RST-3/RST-5): after an item ends with APB_ST_RESET_ABORTED the
// driver waits for reset release before taking the next item.
// Included by apb_uvc_pkg.
// -----------------------------------------------------------------------------

class apb_driver extends uvm_driver #(apb_transaction);
  `uvm_component_utils(apb_driver)

  apb_agent_cfg cfg;  // set by apb_agent
  int unsigned  num_sent;

  protected apb_drive_proxy_base drive;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (cfg == null)
      `uvm_fatal("APB_DRV", "apb_agent_cfg not set by the agent")
    drive = cfg.drive;
    if (drive == null)
      `uvm_fatal("APB_DRV", {cfg.get_name(), ": active agent without a drive proxy"})
  endfunction

  virtual function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    drive.max_wait_cycles = cfg.max_wait_cycles;
    drive.allow_unaligned = cfg.allow_unaligned;
    drive.allow_x_wdata   = cfg.allow_x_wdata;
    if (!drive.configure(cfg.features))
      `uvm_fatal("APB_DRV", {cfg.get_name(), ": driver BFM rejected the feature set"})
    drive.set_enable(1'b1);
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      drive.wait_for_reset_release(cfg.post_reset_idle_cycles);
      do begin
        seq_item_port.get_next_item(req);
        drive.send(req);
        num_sent++;
        report_result(req);
        seq_item_port.item_done();
      end while (req.status != APB_ST_RESET_ABORTED);
    end
  endtask

  protected function void report_result(apb_transaction t);
    case (t.status)
      APB_ST_OK, APB_ST_SLVERR:
        `uvm_info("APB_DRV", t.convert2string(), UVM_HIGH)
      APB_ST_RESET_ABORTED:
        `uvm_info("APB_DRV", {"abandoned by reset: ", t.convert2string()}, UVM_MEDIUM)
      APB_ST_FAULT_INJECTED:
        `uvm_info("APB_DRV", {"fault injected: ", t.convert2string()}, UVM_MEDIUM)
      APB_ST_TIMEOUT:
        `uvm_error("APB_TIMEOUT", $sformatf("no PREADY after %0d wait states: %s",
                                            cfg.max_wait_cycles, t.convert2string()))
      APB_ST_NOT_ENABLED:
        `uvm_fatal("APB_DRV", {"driver BFM not enabled: ", t.convert2string()})
      default:  // APB_ST_BAD_REQUEST: the adapter already reported why
        `uvm_info("APB_DRV", {"rejected: ", t.convert2string()}, UVM_MEDIUM)
    endcase
  endfunction

endclass : apb_driver
