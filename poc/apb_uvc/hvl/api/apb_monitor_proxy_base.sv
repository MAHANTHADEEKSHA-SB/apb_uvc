// -----------------------------------------------------------------------------
// apb_monitor_proxy_base — abstract APB observe capability (ADR-001, ADR-002)
//
// Not parameterized by bus width. The UVM monitor holds only this handle; a
// width-specialized adapter (apb_adapter_pkg::apb_monitor_proxy) implements
// it over a typed virtual monitor-BFM handle. It offers no drive operation.
// Included by apb_api_pkg.
// -----------------------------------------------------------------------------

virtual class apb_monitor_proxy_base extends uvm_object;

  function new(string name = "apb_monitor_proxy_base");
    super.new(name);
  endfunction

  // Physical parameters of the bound bus (CFG-03/04/06 checks)
  pure virtual function int unsigned get_addr_width();
  pure virtual function int unsigned get_data_width();
  pure virtual function int unsigned get_num_sel();

  // Push the instance feature set to the BFM; 0 = rejected
  pure virtual function bit configure(apb_features_t features);

  // Enable the BFM observation queue (only once a consumer exists)
  pure virtual function void set_publish(bit en);

  // Print each protocol violation from the BFM as it happens
  pure virtual function void set_verbose(bit en);

  // Blocks until the next completed transfer; returns a new object per call
  pure virtual task receive(output apb_transaction observed);

  // Protocol violations detected by the BFM (apb_bfm_pkg::apb_mon_error_e)
  pure virtual function int unsigned get_error_count(apb_mon_error_e code);
  pure virtual function int unsigned get_total_errors();
  pure virtual function void         clear_errors();

  // Activity counters kept by the BFM
  pure virtual function int unsigned get_transfer_count();  // completed transfers
  pure virtual function int unsigned get_reset_count();     // resets after the first release

endclass : apb_monitor_proxy_base
