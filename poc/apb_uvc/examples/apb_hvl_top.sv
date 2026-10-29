// -----------------------------------------------------------------------------
// apb_hvl_top — HVL integration example: bind adapters, register cfg, run
//
// The only place that connects the width-independent UVM core to the
// physical instances in apb_hdl_top (ADR-002 configuration flow):
//   1. construct one width-specialized drive and observe adapter per
//      instance, each bound to that instance's own BFM (explicit, no factory)
//   2. put them as base-class handles into one apb_agent_cfg per instance
//   3. register each cfg ONCE at the exact agent path
//   4. run_test()
// Elaborate with both tops: apb_hdl_top and apb_hvl_top.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

module apb_hvl_top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import apb_bfm_pkg::*;
  import apb_api_pkg::*;
  import apb_uvc_pkg::*;
  import apb_adapter_pkg::*;
  import apb_poc_test_pkg::*;

  initial begin : bind_and_run
    apb_drive_proxy   #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) drive_a;
    apb_monitor_proxy #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) observe_a;
    apb_drive_proxy   #(.ADDR_WIDTH(32), .DATA_WIDTH(16)) drive_b;
    apb_monitor_proxy #(.ADDR_WIDTH(32), .DATA_WIDTH(16)) observe_b;
    apb_agent_cfg     cfg_a;
    apb_agent_cfg     cfg_b;
`ifdef APB_ENABLE_DW64_EXTENSION
    apb_drive_proxy   #(.ADDR_WIDTH(32), .DATA_WIDTH(64)) drive_c;
    apb_monitor_proxy #(.ADDR_WIDTH(32), .DATA_WIDTH(64)) observe_c;
    apb_agent_cfg     cfg_c;
`endif

    // Instance A: AW=32, DW=32
    drive_a       = new("drive_a",   apb_hdl_top.drv_a);
    observe_a     = new("observe_a", apb_hdl_top.mon_a);
    cfg_a         = apb_agent_cfg::type_id::create("cfg_a");
    cfg_a.drive   = drive_a;
    cfg_a.observe = observe_a;
    uvm_config_db#(apb_agent_cfg)::set(null, "uvm_test_top.env.agent_a", "cfg", cfg_a);

    // Instance B: AW=32, DW=16
    drive_b       = new("drive_b",   apb_hdl_top.drv_b);
    observe_b     = new("observe_b", apb_hdl_top.mon_b);
    cfg_b         = apb_agent_cfg::type_id::create("cfg_b");
    cfg_b.drive   = drive_b;
    cfg_b.observe = observe_b;
    uvm_config_db#(apb_agent_cfg)::set(null, "uvm_test_top.env.agent_b", "cfg", cfg_b);

`ifdef APB_ENABLE_DW64_EXTENSION
    // Instance C: AW=32, DW=64 — NON-STANDARD extension (ADR-001 A1)
    drive_c       = new("drive_c",   apb_hdl_top.drv_c);
    observe_c     = new("observe_c", apb_hdl_top.mon_c);
    cfg_c         = apb_agent_cfg::type_id::create("cfg_c");
    cfg_c.drive   = drive_c;
    cfg_c.observe = observe_c;
    cfg_c.allow_nonstandard_width = 1'b1;
    uvm_config_db#(apb_agent_cfg)::set(null, "uvm_test_top.env.agent_c", "cfg", cfg_c);
`endif

    run_test("apb_poc_test");
  end

endmodule : apb_hvl_top
