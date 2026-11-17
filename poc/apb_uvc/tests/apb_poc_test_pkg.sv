// -----------------------------------------------------------------------------
// apb_poc_test_pkg — POC environment, scoreboards and tests
//
// Test code only. Uses the UVM core through apb_uvc_pkg and the abstract
// capabilities through apb_api_pkg; it never names an HDL interface type
// (the binding is done in examples/apb_hvl_top.sv).
//
// Tests (select with +UVM_TESTNAME=<name>):
//   apb_poc_test              DW=32 + DW=16 concurrent directed + random traffic
//   apb_fault_injection_test  +APB_FAULT=1|2|3 on instance A; must be detected
//   apb_cfg_negative_test     CFG-01..06 legality verdicts (no bus traffic)
//   apb_width_negative_test   unfit write on DW=16 must be rejected, not truncated
//   apb_path_negative_test    corrupted drive path on B must be caught (RV-001)
//   apb_no_pstrb_test         B as APB3: writes observed full-width (RV-002)
//
// Include directory: tests.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

package apb_poc_test_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import apb_bfm_pkg::*;
  import apb_api_pkg::*;
  import apb_uvc_pkg::*;

  `include "apb_poc_scoreboard.sv"
  `include "apb_poc_path_scoreboard.sv"
  `include "apb_poc_env.sv"
  `include "apb_poc_seqs.sv"
  `include "apb_fake_proxies.sv"
  `include "apb_poc_test.sv"
  `include "apb_fault_injection_test.sv"
  `include "apb_negative_tests.sv"
  `include "apb_no_pstrb_test.sv"

endpackage : apb_poc_test_pkg
