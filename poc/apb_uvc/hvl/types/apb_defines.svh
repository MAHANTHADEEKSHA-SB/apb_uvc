// -----------------------------------------------------------------------------
// apb_defines.svh — compile-time maxima for the width-independent transaction
//
// One simulation image uses one set of maxima (APB_PROTOCOL_CONTRACT
// section 6). Defaults follow IHI 0024D: PADDR up to 32 bits, data 8/16/32.
// The DW=64 non-standard extension (ADR-001 A1) raises the data maximum.
// Override any value with +define+NAME=value.
// -----------------------------------------------------------------------------
`ifndef APB_DEFINES_SVH
`define APB_DEFINES_SVH

`ifndef APB_MAX_ADDR_WIDTH
  `define APB_MAX_ADDR_WIDTH 32
`endif

`ifndef APB_MAX_DATA_WIDTH
  `ifdef APB_ENABLE_DW64_EXTENSION
    `define APB_MAX_DATA_WIDTH 64
  `else
    `define APB_MAX_DATA_WIDTH 32
  `endif
`endif

`endif // APB_DEFINES_SVH
