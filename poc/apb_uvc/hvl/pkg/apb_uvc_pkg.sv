// -----------------------------------------------------------------------------
// apb_uvc_pkg — non-parameterized UVM core of the APB UVC
//
// Configuration, agent, sequencer, driver, monitor, coverage and generic
// sequences. Depends only on apb_api_pkg (abstract capabilities), never on a
// physical interface type or on apb_adapter_pkg (ADR-001 decision 3).
//
// Compile after uvm_pkg, apb_bfm_pkg and apb_api_pkg. Include directories:
// hvl/config, hvl/agent, hvl/coverage, hvl/sequences.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

package apb_uvc_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import apb_bfm_pkg::*;
  import apb_api_pkg::*;

  `include "apb_agent_cfg.sv"
  `include "apb_sequencer.sv"
  `include "apb_driver.sv"
  `include "apb_monitor.sv"
  `include "apb_coverage.sv"
  `include "apb_agent.sv"
  `include "apb_base_seq.sv"
  `include "apb_random_seq.sv"

endpackage : apb_uvc_pkg
