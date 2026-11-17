// -----------------------------------------------------------------------------
// apb_fake_proxies — test doubles of the two capability classes
//
// apb_fake_drive_proxy and apb_fake_monitor_proxy report any widths without an
// HDL instance, so apb_cfg_negative_test can exercise apb_agent_cfg legality
// checks (CFG-01..06) for widths that cannot be instantiated legally. They are
// never connected to a bus.
// apb_corrupt_drive_proxy wraps a real drive proxy and silently corrupts one
// data bit, so apb_path_negative_test can prove that the path scoreboard
// notices (RV-001, VER-03).
// All three share this file as FILE-02 helpers.
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


// Drive-side double for apb_path_negative_test. It forwards every call to a real
// drive proxy but flips data bit 0 on the way to the bus (writes) and on the way
// back (reads), without touching the request fields of the caller's item: silent,
// symmetric corruption. A read-back check and the fixture scoreboard still pass;
// only a comparison of the request with its observation can tell.
class apb_corrupt_drive_proxy extends apb_drive_proxy_base;
  protected apb_drive_proxy_base inner;

  // Wrap an existing drive proxy; a null handle is fatal.
  function new(string name, apb_drive_proxy_base inner);
    super.new(name);
    if (inner == null)
      `uvm_fatal("APB_PROXY", {name, ": no drive proxy to wrap"})
    this.inner = inner;
  endfunction

  // Everything except send() is a thin forward to the wrapped proxy.
  virtual function int unsigned get_addr_width();
    return inner.get_addr_width();
  endfunction

  virtual function int unsigned get_data_width();
    return inner.get_data_width();
  endfunction

  virtual function int unsigned get_num_sel();
    return inner.get_num_sel();
  endfunction

  virtual function bit configure(apb_features_t features);
    return inner.configure(features);
  endfunction

  virtual function void set_enable(bit en);
    inner.set_enable(en);
  endfunction

  virtual function void set_fault(apb_fault_e fault);
    inner.set_fault(fault);
  endfunction

  virtual task wait_for_reset_release(int unsigned idle_cycles);
    inner.wait_for_reset_release(idle_cycles);
  endtask

  // Drive a corrupted copy and hand its response back in the caller's item. The
  // policies the driver set on this object are passed on to the wrapped proxy.
  virtual task send(apb_transaction req);
    apb_transaction bad;
    inner.max_wait_cycles = max_wait_cycles;
    inner.allow_unaligned = allow_unaligned;
    inner.allow_x_wdata   = allow_x_wdata;
    if (!$cast(bad, req.clone()))
      `uvm_fatal("APB_PROXY", "clone() of a request is not an apb_transaction")
    if (bad.dir == APB_WRITE) bad.wdata[0] = ~bad.wdata[0];
    inner.send(bad);
    req.set_bus_context(bad.bus_addr_width, bad.bus_data_width, bad.bus_num_sel,
                        bad.bus_has_pstrb, bad.bus_has_pprot);
    req.instance_name = bad.instance_name;
    req.rdata         = bad.rdata;
    req.slverr        = bad.slverr;
    req.wait_states   = bad.wait_states;
    req.status        = bad.status;
    if (req.dir == APB_READ && req.status == APB_ST_OK) req.rdata[0] = ~req.rdata[0];
  endtask
endclass : apb_corrupt_drive_proxy
