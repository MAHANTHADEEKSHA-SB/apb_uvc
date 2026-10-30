// -----------------------------------------------------------------------------
// apb_fake_proxies — test doubles of the two capability classes
//
// Report any widths without an HDL instance, so apb_cfg_negative_test can
// exercise apb_agent_cfg legality checks (CFG-01..06) for widths that cannot
// be instantiated legally. Never connected to a bus.
// Contains apb_fake_drive_proxy and apb_fake_monitor_proxy (FILE-02 helpers).
// Included by apb_poc_test_pkg.
// -----------------------------------------------------------------------------

class apb_fake_drive_proxy extends apb_drive_proxy_base;
  int unsigned aw = 32;
  int unsigned dw = 32;
  int unsigned ns = 1;

  function new(string name = "apb_fake_drive_proxy");
    super.new(name);
  endfunction

  // The width getters return the knobs above; every other method is an inert stub.
  virtual function int unsigned get_addr_width();
    return aw;
  endfunction

  virtual function int unsigned get_data_width();
    return dw;
  endfunction

  virtual function int unsigned get_num_sel();
    return ns;
  endfunction

  virtual function bit configure(apb_features_t features);
    return 1'b1;
  endfunction

  virtual function void set_enable(bit en);
  endfunction

  virtual function void set_fault(apb_fault_e fault);
  endfunction

  virtual task wait_for_reset_release(int unsigned idle_cycles);
  endtask

  virtual task send(apb_transaction req);
    req.status = APB_ST_NOT_ENABLED;
  endtask
endclass : apb_fake_drive_proxy


// Observe-side double with the same width knobs; it never receives anything.
class apb_fake_monitor_proxy extends apb_monitor_proxy_base;
  int unsigned aw = 32;
  int unsigned dw = 32;
  int unsigned ns = 1;

  function new(string name = "apb_fake_monitor_proxy");
    super.new(name);
  endfunction

  // The width getters return the knobs above; every other method is an inert stub.
  virtual function int unsigned get_addr_width();
    return aw;
  endfunction

  virtual function int unsigned get_data_width();
    return dw;
  endfunction

  virtual function int unsigned get_num_sel();
    return ns;
  endfunction

  virtual function bit configure(apb_features_t features);
    return 1'b1;
  endfunction

  virtual function void set_publish(bit en);
  endfunction

  virtual function void set_verbose(bit en);
  endfunction

  virtual task receive(output apb_transaction observed);
    observed = null;
  endtask

  virtual function int unsigned get_error_count(apb_mon_error_e code);
    return 0;
  endfunction

  virtual function int unsigned get_total_errors();
    return 0;
  endfunction

  virtual function void clear_errors();
  endfunction

  virtual function int unsigned get_transfer_count();
    return 0;
  endfunction

  virtual function int unsigned get_reset_count();
    return 0;
  endfunction
endclass : apb_fake_monitor_proxy
