// -----------------------------------------------------------------------------
// apb_api_pkg — width-independent HVL API of the APB UVC
//
// Contains the transaction and the two abstract capability classes. Nothing
// here depends on a physical interface type (ADR-001 decision 1), so the UVM
// core (apb_uvc_pkg) can be compiled against it alone.
//
// Compile after uvm_pkg and apb_bfm_pkg. Include directories: hvl/types,
// hvl/api (see filelists/apb_hvl.f).
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

`include "apb_defines.svh"

package apb_api_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import apb_bfm_pkg::*;

  // Transaction maxima for this simulation image (apb_defines.svh)
  localparam int APB_MAX_AW = `APB_MAX_ADDR_WIDTH;
  localparam int APB_MAX_DW = `APB_MAX_DATA_WIDTH;
  localparam int APB_MAX_SW = `APB_MAX_DATA_WIDTH / 8;

  `include "apb_transaction.sv"
  `include "apb_drive_proxy_base.sv"
  `include "apb_monitor_proxy_base.sv"

endpackage : apb_api_pkg
