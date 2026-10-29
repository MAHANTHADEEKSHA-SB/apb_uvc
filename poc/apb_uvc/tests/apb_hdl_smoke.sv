// -----------------------------------------------------------------------------
// apb_hdl_smoke — HDL-only directed smoke test (APB-003a acceptance, no UVM)
//
// Binds apb_hdl_smoke_runner into instance A (DW=32) and instance B
// (DW=16) of apb_hdl_top and runs them concurrently, each on its own clock and reset, plus
// instance C (DW=64, non-standard) with +define+APB_ENABLE_DW64_EXTENSION.
//
// Negative control: +APB_FAULT=<n> (apb_fault_e) injects a fault on
// instance A only. The test then passes only if A's monitor reports the
// matching violation and every other instance stays error-free (isolation).
//
// Result line: "SMOKE_RESULT: PASS" or "SMOKE_RESULT: FAIL".
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

module apb_hdl_smoke;
  import apb_bfm_pkg::*;

  apb_hdl_top u_top ();

`ifdef APB_ENABLE_DW64_EXTENSION
  wire all_done = u_top.run_a.done && u_top.run_b.done && u_top.run_c.done;
  wire all_pass = u_top.run_a.failures == 0 && u_top.run_b.failures == 0 &&
                  u_top.run_c.failures == 0;
`else
  wire all_done = u_top.run_a.done && u_top.run_b.done;
  wire all_pass = u_top.run_a.failures == 0 && u_top.run_b.failures == 0;
`endif

  initial begin
    wait (all_done);
    $display("SMOKE_SUMMARY mode=%s A.failures=%0d B.failures=%0d B.monitor_errors=%0d",
             u_top.run_a.fault.name(), u_top.run_a.failures, u_top.run_b.failures,
             u_top.mon_b.get_total_errors());
    $display("SMOKE_RESULT: %s", all_pass ? "PASS" : "FAIL");
    $finish;
  end

  initial begin
    #200us;
    $display("SMOKE_RESULT: FAIL (watchdog timeout)");
    $finish;
  end

endmodule : apb_hdl_smoke

// The runners are bound into apb_hdl_top so each connects to its BFMs by a
// local name; the example top itself contains no test code.
bind apb_hdl_top apb_hdl_smoke_runner
  #(.ADDR_WIDTH(32), .DATA_WIDTH(32), .FAULT_TARGET(1'b1), .NAME("A DW=32"))
  run_a (.drv(drv_a), .mon(mon_a));

bind apb_hdl_top apb_hdl_smoke_runner
  #(.ADDR_WIDTH(32), .DATA_WIDTH(16), .NAME("B DW=16"))
  run_b (.drv(drv_b), .mon(mon_b));

`ifdef APB_ENABLE_DW64_EXTENSION
bind apb_hdl_top apb_hdl_smoke_runner
  #(.ADDR_WIDTH(32), .DATA_WIDTH(64), .NAME("C DW=64 non-standard"))
  run_c (.drv(drv_c), .mon(mon_c));
`endif
