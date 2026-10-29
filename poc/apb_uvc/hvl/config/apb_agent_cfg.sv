// -----------------------------------------------------------------------------
// apb_agent_cfg — configuration of ONE APB UVC instance (ADR-002 decision 6)
//
// Carries the two base-class capability handles, the active/passive policy,
// the revision/feature set and the UVC policies. The integration code fills
// one object per instance and registers it once with
//   uvm_config_db#(apb_agent_cfg)::set(null, "<exact agent path>", "cfg", cfg)
// The agent retrieves it once and hands it to its children. Never share an
// object between instances.
//
// validate() enforces APB_PROTOCOL_CONTRACT section 2.3 (CFG-01..06) and the
// milestone M1 feature limits; legality_error() returns the same verdict as
// text so negative tests can check it without a fatal.
// Included by apb_uvc_pkg.
// -----------------------------------------------------------------------------

class apb_agent_cfg extends uvm_object;
  `uvm_object_utils(apb_agent_cfg)

  // Capability handles: drive may stay null on a passive instance
  apb_drive_proxy_base    drive;
  apb_monitor_proxy_base  observe;

  uvm_active_passive_enum is_active = UVM_ACTIVE;

  // Revision and optional features (default: APB4 with PSTRB and PPROT)
  apb_features_t          features;
  bit                     allow_nonstandard_width = 1'b0;  // ADR-001 A1: DW=64

  // Policies (APB_PROTOCOL_CONTRACT sections 4-6)
  int unsigned            max_wait_cycles        = 1024;   // POL-02; 0 = no watchdog
  int unsigned            post_reset_idle_cycles = 1;      // RST-5
  bit                     allow_unaligned        = 1'b0;   // POL-01
  bit                     allow_x_wdata          = 1'b0;   // section 6
  bit                     enable_coverage        = 1'b1;
  bit                     monitor_verbose        = 1'b1;   // BFM prints each violation

  function new(string name = "apb_agent_cfg");
    super.new(name);
    features = apb_default_features();
  endfunction

  // Physical bus parameters, taken from the observe adapter
  function int unsigned addr_width();
    return (observe == null) ? 0 : observe.get_addr_width();
  endfunction

  function int unsigned data_width();
    return (observe == null) ? 0 : observe.get_data_width();
  endfunction

  function int unsigned num_sel();
    return (observe == null) ? 0 : observe.get_num_sel();
  endfunction

  // "" when the configuration is legal, otherwise the first problem found
  function string legality_error();
    int unsigned aw;
    int unsigned dw;

    if (observe == null)
      return "no observe (monitor) proxy bound";
    if (is_active == UVM_ACTIVE && drive == null)
      return "active agent without a drive proxy";

    aw = observe.get_addr_width();
    dw = observe.get_data_width();

    // CFG-06: both adapters must be bound to the same bus specialization
    if (drive != null && (drive.get_addr_width() != aw || drive.get_data_width() != dw ||
                          drive.get_num_sel() != observe.get_num_sel()))
      return $sformatf(
          "CFG-06: drive proxy AW=%0d DW=%0d NUM_SEL=%0d, observe proxy AW=%0d DW=%0d NUM_SEL=%0d",
          drive.get_addr_width(), drive.get_data_width(), drive.get_num_sel(),
          aw, dw, observe.get_num_sel());
    // CFG-03: IHI 0024D Table 2-1
    if (aw < 1 || aw > 32)
      return $sformatf("CFG-03: ADDR_WIDTH=%0d outside 1..32", aw);
    // CFG-04: IHI 0024D 2.1.2; DW=64 only as the opt-in extension
    if (!(dw inside {8, 16, 32}) && !(dw == 64 && allow_nonstandard_width))
      return $sformatf("CFG-04: DATA_WIDTH=%0d not in {8,16,32}%s", dw,
                       dw == 64 ? " (64 needs allow_nonstandard_width)" : "");
    // CFG-01: IHI 0024D Table B-1
    if (features.revision < APB4 && (features.has_pprot || features.has_pstrb))
      return $sformatf("CFG-01: PPROT/PSTRB are not present on %s", features.revision.name());
    // CFG-02: IHI 0024D Table B-3
    if (features.revision < APB5 &&
        (features.has_pwakeup || features.check_type != APB_CHECK_NONE ||
         features.user_req_width != 0 || features.user_data_width != 0 ||
         features.user_resp_width != 0))
      return "CFG-02: wake-up, user and check signals exist on APB5 only";
    // Milestone limits (CFG-05 user-width checks arrive with M2)
    if (features.has_pwakeup || features.user_req_width != 0 ||
        features.user_data_width != 0 || features.user_resp_width != 0)
      return "PWAKEUP and user signals are milestone M2; not implemented yet";
    if (features.check_type != APB_CHECK_NONE)
      return "parity check signals are milestone M3; not implemented yet";
    return "";
  endfunction

  function void validate();
    string problem = legality_error();
    if (problem != "")
      `uvm_fatal("APB_CFG", {get_name(), ": ", problem})
    if (is_active == UVM_PASSIVE && drive != null)
      `uvm_warning("APB_CFG",
                   {get_name(), ": passive agent has a drive proxy; it will not be used"})
    if (data_width() == 64)
      `uvm_warning("APB_CFG", {get_name(),
                   ": DATA_WIDTH=64 is a NON-STANDARD extension, not IHI 0024D compliant"})
  endfunction

  virtual function string convert2string();
    return $sformatf("%s: %s %s AW=%0d DW=%0d NUM_SEL=%0d pstrb=%0b pprot=%0b max_wait=%0d",
                     get_name(), is_active.name(), features.revision.name(), addr_width(),
                     data_width(), num_sel(), features.has_pstrb, features.has_pprot,
                     max_wait_cycles);
  endfunction

endclass : apb_agent_cfg
