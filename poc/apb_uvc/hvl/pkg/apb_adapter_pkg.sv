// -----------------------------------------------------------------------------
// apb_adapter_pkg — width-specialized HVL adapters of the APB UVC
//
// The only package that names the HDL BFM interface types (through virtual
// interface handles). Integration code specializes these classes per bus
// instance and hands them to apb_agent_cfg as base-class handles.
//
// Compile after the HDL interfaces (filelists/apb_hdl.f), uvm_pkg,
// apb_bfm_pkg and apb_api_pkg. apb_uvc_pkg does not import this package.
// Include directory: hvl/adapter.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

package apb_adapter_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import apb_bfm_pkg::*;
  import apb_api_pkg::*;

  `include "apb_drive_proxy.sv"
  `include "apb_monitor_proxy.sv"

endpackage : apb_adapter_pkg
