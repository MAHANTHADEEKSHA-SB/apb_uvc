// -----------------------------------------------------------------------------
// apb_if — APB physical signal interface (APB5 pin superset)
//
// Declares every signal of ARM IHI 0024D Table B-1 and the check signals of
// Table B-2, so one interface definition serves APB2, APB3, APB4 and APB5
// instances. Which signals are live is a per-instance configuration of the
// BFMs (docs/dv-architecture/APB_PROTOCOL_CONTRACT.md section 1); absent
// signals are simply left unconnected at the Completer.
//
// This interface owns pins and modports only. Protocol timing lives in
// apb_driver_bfm_if and apb_monitor_bfm_if (ADR-002 decision 3). Signals are
// resolved nets so a disabled driver BFM can release the bus to 'z.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

interface apb_if #(
  parameter int ADDR_WIDTH           = 32,  // IHI Table 2-1: up to 32
  parameter int DATA_WIDTH           = 32,  // IHI 2.1.2: 8, 16 or 32
  parameter int NUM_SEL              = 1,   // one PSELx per Completer
  parameter int USER_REQ_WIDTH       = 1,   // physical width; presence is cfg
  parameter int USER_DATA_WIDTH      = 1,
  parameter int USER_RESP_WIDTH      = 1,
  parameter bit ALLOW_NONSTANDARD_DW = 1'b0 // ADR-001 A1: DW=64 extension
) (
  input wire logic PCLK,
  input wire logic PRESETn
);

  localparam int STRB_WIDTH         = DATA_WIDTH / 8;
  localparam int ADDRCHK_WIDTH      = (ADDR_WIDTH + 7) / 8;      // IHI Table 5-1
  localparam int USER_REQ_CHK_WIDTH  = (USER_REQ_WIDTH + 7) / 8;
  localparam int USER_DATA_CHK_WIDTH = (USER_DATA_WIDTH + 7) / 8;
  localparam int USER_RESP_CHK_WIDTH = (USER_RESP_WIDTH + 7) / 8;

  // Requester -> Completer
  wire logic [ADDR_WIDTH-1:0]      PADDR;
  wire logic [2:0]                 PPROT;
  wire logic [NUM_SEL-1:0]         PSEL;
  wire logic                       PENABLE;
  wire logic                       PWRITE;
  wire logic [DATA_WIDTH-1:0]      PWDATA;
  wire logic [STRB_WIDTH-1:0]      PSTRB;
  wire logic                       PWAKEUP;
  wire logic [USER_REQ_WIDTH-1:0]  PAUSER;
  wire logic [USER_DATA_WIDTH-1:0] PWUSER;

  // Completer -> Requester
  wire logic                       PREADY;
  wire logic [DATA_WIDTH-1:0]      PRDATA;
  wire logic                       PSLVERR;
  wire logic [USER_DATA_WIDTH-1:0] PRUSER;
  wire logic [USER_RESP_WIDTH-1:0] PBUSER;

  // APB5 parity check signals (IHI Table 5-1), Requester -> Completer
  wire logic [ADDRCHK_WIDTH-1:0]       PADDRCHK;
  wire logic                           PCTRLCHK;
  wire logic [NUM_SEL-1:0]             PSELCHK;
  wire logic                           PENABLECHK;
  wire logic [STRB_WIDTH-1:0]          PWDATACHK;
  wire logic                           PSTRBCHK;
  wire logic                           PWAKEUPCHK;
  wire logic [USER_REQ_CHK_WIDTH-1:0]  PAUSERCHK;
  wire logic [USER_DATA_CHK_WIDTH-1:0] PWUSERCHK;

  // APB5 parity check signals, Completer -> Requester
  wire logic                           PREADYCHK;
  wire logic [STRB_WIDTH-1:0]          PRDATACHK;
  wire logic                           PSLVERRCHK;
  wire logic [USER_DATA_CHK_WIDTH-1:0] PRUSERCHK;
  wire logic [USER_RESP_CHK_WIDTH-1:0] PBUSERCHK;

  // Modports give a DUT or a hand-written testbench a direction-checked view of the
  // bus. The UVC's own BFMs do not use them: they connect through ordinary signal
  // ports wired in the HDL top (ADR-002 decision 7).
  modport requester (
    input  PCLK, PRESETn,
    output PADDR, PPROT, PSEL, PENABLE, PWRITE, PWDATA, PSTRB, PWAKEUP, PAUSER, PWUSER,
           PADDRCHK, PCTRLCHK, PSELCHK, PENABLECHK, PWDATACHK, PSTRBCHK, PWAKEUPCHK,
           PAUSERCHK, PWUSERCHK,
    input  PREADY, PRDATA, PSLVERR, PRUSER, PBUSER,
           PREADYCHK, PRDATACHK, PSLVERRCHK, PRUSERCHK, PBUSERCHK
  );

  modport completer (
    input  PCLK, PRESETn,
    input  PADDR, PPROT, PSEL, PENABLE, PWRITE, PWDATA, PSTRB, PWAKEUP, PAUSER, PWUSER,
           PADDRCHK, PCTRLCHK, PSELCHK, PENABLECHK, PWDATACHK, PSTRBCHK, PWAKEUPCHK,
           PAUSERCHK, PWUSERCHK,
    output PREADY, PRDATA, PSLVERR, PRUSER, PBUSER,
           PREADYCHK, PRDATACHK, PSLVERRCHK, PRUSERCHK, PBUSERCHK
  );

  modport monitor (
    input  PCLK, PRESETn,
           PADDR, PPROT, PSEL, PENABLE, PWRITE, PWDATA, PSTRB, PWAKEUP, PAUSER, PWUSER,
           PADDRCHK, PCTRLCHK, PSELCHK, PENABLECHK, PWDATACHK, PSTRBCHK, PWAKEUPCHK,
           PAUSERCHK, PWUSERCHK,
           PREADY, PRDATA, PSLVERR, PRUSER, PBUSER,
           PREADYCHK, PRDATACHK, PSLVERRCHK, PRUSERCHK, PBUSERCHK
  );

  // Elaboration-time legality checks (APB_PROTOCOL_CONTRACT CFG-03/CFG-04)
  if (ADDR_WIDTH < 1 || ADDR_WIDTH > 32) begin : g_bad_addr_width
    $error("apb_if: ADDR_WIDTH=%0d outside IHI 0024D range 1..32", ADDR_WIDTH);
  end
  if (!(DATA_WIDTH inside {8, 16, 32}) && !(ALLOW_NONSTANDARD_DW && DATA_WIDTH == 64))
  begin : g_bad_data_width
    $error("apb_if: DATA_WIDTH=%0d not in IHI 0024D {8,16,32}; 64 needs ALLOW_NONSTANDARD_DW=1",
           DATA_WIDTH);
  end
  if (NUM_SEL < 1) begin : g_bad_num_sel
    $error("apb_if: NUM_SEL=%0d must be >= 1", NUM_SEL);
  end
  if (USER_REQ_WIDTH < 1 || USER_DATA_WIDTH < 1 || USER_RESP_WIDTH < 1) begin : g_bad_user_width
    $error("apb_if: physical user widths must be >= 1; use cfg widths of 0 for absent signals");
  end

endinterface : apb_if
