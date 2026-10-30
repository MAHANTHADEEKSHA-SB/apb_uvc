// -----------------------------------------------------------------------------
// apb_drive_proxy_base — abstract APB drive capability (ADR-001, ADR-002)
//
// Not parameterized by bus width. The UVM driver holds only this handle; a
// width-specialized adapter (apb_adapter_pkg::apb_drive_proxy) implements it
// over a typed virtual driver-BFM handle. A monitor never receives this type.
// Included by apb_api_pkg.
// -----------------------------------------------------------------------------

virtual class apb_drive_proxy_base extends uvm_object;

  // Policies copied from apb_agent_cfg by the driver (APB_PROTOCOL_CONTRACT)
  int unsigned max_wait_cycles = 1024;  // POL-02: TIMEOUT after this many waits; 0 = off
  bit          allow_unaligned = 1'b0;  // POL-01
  bit          allow_x_wdata   = 1'b0;  // section 6: X/Z write data only for fault injection

  function new(string name = "apb_drive_proxy_base");
    super.new(name);
  endfunction

  // Physical parameters of the bound bus (CFG-06 cross-checks)
  pure virtual function int unsigned get_addr_width();
  pure virtual function int unsigned get_data_width();
  pure virtual function int unsigned get_num_sel();

  // Push the instance feature set to the BFM; 0 = rejected
  pure virtual function bit configure(apb_features_t features);

  // 1: drive the bus; 0: release every Requester output to 'z
  pure virtual function void set_enable(bit en);

  // Deliberate protocol faults for negative tests
  pure virtual function void set_fault(apb_fault_e fault);

  // RST-5: return once reset is released, plus idle_cycles PCLK edges
  pure virtual task wait_for_reset_release(int unsigned idle_cycles);

  // Run one transfer. Fills req.rdata, slverr, wait_states and status
  // (APB_ST_BAD_REQUEST when the request cannot be driven losslessly).
  pure virtual task send(apb_transaction req);

endclass : apb_drive_proxy_base
