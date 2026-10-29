// -----------------------------------------------------------------------------
// apb_driver_bfm_if — APB Requester (master) drive BFM
//
// Owns timed APB master drive (ADR-002 decision 2). Connects to the shared
// apb_if instance through ordinary signal ports wired in the HDL top
// (ADR-002 decision 7); it has no interface-typed ports, so a virtual handle
// to this interface avoids the IEEE restriction noted in DVCon 2024.
//
// Contract references: docs/dv-architecture/APB_PROTOCOL_CONTRACT.md
//   APB-R03..R05  SETUP/ACCESS sequencing and stability
//   APB-R14/POL-03 Requester outputs driven to zero when not valid
//   RST-1..RST-3  reset behaviour
//   section 8     drive release: outputs are 'z until set_enable(1)
//
// Milestone M1 implements APB2/APB3/APB4 behaviour. APB5 pins exist but
// PWAKEUP, user signals and parity generation are rejected by configure()
// until milestones M2/M3; their outputs are driven to 0 while enabled.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

interface apb_driver_bfm_if
  import apb_bfm_pkg::*;
#(
  parameter int ADDR_WIDTH      = 32,
  parameter int DATA_WIDTH      = 32,
  parameter int NUM_SEL         = 1,
  parameter int USER_REQ_WIDTH  = 1,
  parameter int USER_DATA_WIDTH = 1,
  parameter int USER_RESP_WIDTH = 1
) (
  input  wire logic                             PCLK,
  input  wire logic                             PRESETn,
  // Requester outputs
  output wire logic [ADDR_WIDTH-1:0]            PADDR,
  output wire logic [2:0]                       PPROT,
  output wire logic [NUM_SEL-1:0]               PSEL,
  output wire logic                             PENABLE,
  output wire logic                             PWRITE,
  output wire logic [DATA_WIDTH-1:0]            PWDATA,
  output wire logic [DATA_WIDTH/8-1:0]          PSTRB,
  output wire logic                             PWAKEUP,
  output wire logic [USER_REQ_WIDTH-1:0]        PAUSER,
  output wire logic [USER_DATA_WIDTH-1:0]       PWUSER,
  output wire logic [(ADDR_WIDTH+7)/8-1:0]      PADDRCHK,
  output wire logic                             PCTRLCHK,
  output wire logic [NUM_SEL-1:0]               PSELCHK,
  output wire logic                             PENABLECHK,
  output wire logic [DATA_WIDTH/8-1:0]          PWDATACHK,
  output wire logic                             PSTRBCHK,
  output wire logic                             PWAKEUPCHK,
  output wire logic [(USER_REQ_WIDTH+7)/8-1:0]  PAUSERCHK,
  output wire logic [(USER_DATA_WIDTH+7)/8-1:0] PWUSERCHK,
  // Completer outputs sampled by the Requester
  input  wire logic                             PREADY,
  input  wire logic [DATA_WIDTH-1:0]            PRDATA,
  input  wire logic                             PSLVERR,
  input  wire logic [USER_DATA_WIDTH-1:0]       PRUSER,
  input  wire logic [USER_RESP_WIDTH-1:0]       PBUSER
);

  localparam int STRB_WIDTH = DATA_WIDTH / 8;

  // Drive state, written by the tasks below with nonblocking assignments so
  // a Completer sampling on the same PCLK edge sees the previous value.
  logic [ADDR_WIDTH-1:0]      paddr_q   = '0;
  logic [2:0]                 pprot_q   = '0;
  logic [NUM_SEL-1:0]         psel_q    = '0;
  logic                       penable_q = 1'b0;
  logic                       pwrite_q  = 1'b0;
  logic [DATA_WIDTH-1:0]      pwdata_q  = '0;
  logic [STRB_WIDTH-1:0]      pstrb_q   = '0;

  bit            drive_en = 1'b0;  // 0: every output released to 'z (passive-safe)
  bit            busy     = 1'b0;  // a do_transfer() call is in flight
  apb_features_t features = apb_default_features();
  apb_fault_e    fault    = APB_FAULT_NONE;

  // Release-capable output stage (APB_PROTOCOL_CONTRACT section 8)
  assign PADDR      = drive_en ? paddr_q   : 'z;
  assign PPROT      = drive_en ? pprot_q   : 'z;
  assign PSEL       = drive_en ? psel_q    : 'z;
  assign PENABLE    = drive_en ? penable_q : 1'bz;
  assign PWRITE     = drive_en ? pwrite_q  : 1'bz;
  assign PWDATA     = drive_en ? pwdata_q  : 'z;
  assign PSTRB      = drive_en ? pstrb_q   : 'z;
  // APB5 outputs: absent until M2/M3, driven to 0 per IHI 0024D A.1
  assign PWAKEUP    = drive_en ? 1'b0 : 1'bz;
  assign PAUSER     = drive_en ? '0   : 'z;
  assign PWUSER     = drive_en ? '0   : 'z;
  assign PADDRCHK   = drive_en ? '0   : 'z;
  assign PCTRLCHK   = drive_en ? 1'b0 : 1'bz;
  assign PSELCHK    = drive_en ? '0   : 'z;
  assign PENABLECHK = drive_en ? 1'b0 : 1'bz;
  assign PWDATACHK  = drive_en ? '0   : 'z;
  assign PSTRBCHK   = drive_en ? 1'b0 : 1'bz;
  assign PWAKEUPCHK = drive_en ? 1'b0 : 1'bz;
  assign PAUSERCHK  = drive_en ? '0   : 'z;
  assign PWUSERCHK  = drive_en ? '0   : 'z;

  clocking cb @(posedge PCLK);
    default input #1step;
    input PRESETn, PREADY, PRDATA, PSLVERR, PRUSER, PBUSER;
  endclocking

  // ---------------------------------------------------------------------------
  // Control API (called through a virtual interface by the HVL drive adapter)
  // ---------------------------------------------------------------------------

  // Accept a per-instance feature set; returns 0 and changes nothing when the
  // set is illegal for IHI 0024D Table B-1/B-3 or not yet implemented.
  function automatic bit configure(apb_features_t f);
    if (busy) begin
      $error("%m: configure() while a transfer is in flight");
      return 1'b0;
    end
    if (f.revision < APB4 && (f.has_pprot || f.has_pstrb)) begin
      $error("%m: PPROT/PSTRB are not present on %s (IHI 0024D Table B-1)", f.revision.name());
      return 1'b0;
    end
    if (f.revision < APB5 && (f.has_pwakeup || f.check_type != APB_CHECK_NONE ||
                              f.user_req_width != 0 || f.user_data_width != 0 ||
                              f.user_resp_width != 0)) begin
      $error("%m: wake-up/user/check signals are APB5 only (IHI 0024D Table B-3)");
      return 1'b0;
    end
    if (f.has_pwakeup || f.user_req_width != 0 || f.user_data_width != 0 ||
        f.user_resp_width != 0) begin
      $error("%m: PWAKEUP and user signals are milestone M2; not implemented yet");
      return 1'b0;
    end
    if (f.check_type != APB_CHECK_NONE) begin
      $error("%m: parity check signals are milestone M3; not implemented yet");
      return 1'b0;
    end
    features = f;
    return 1'b1;
  endfunction

  // 1: drive the bus; 0: release every output to 'z
  function automatic void set_enable(bit en);
    if (busy && !en) $error("%m: driver released while a transfer is in flight");
    drive_en = en;
  endfunction

  function automatic void set_fault(apb_fault_e f);
    fault = f;
  endfunction

  // RST-5: return after PRESETn is sampled HIGH, plus idle_cycles more edges
  task automatic wait_for_reset_release(input int unsigned idle_cycles = 1);
    do @(cb); while (cb.PRESETn !== 1'b1);
    repeat (idle_cycles) @(cb);
  endtask

  // One complete APB transfer. Returns at the PCLK edge where the transfer
  // completed (PREADY sampled HIGH in ACCESS), after scheduling the IDLE
  // values; a following call in the same time step with idle_cycles == 0
  // overrides them with its SETUP values, giving a back-to-back transfer
  // (APB-R05).
  task automatic do_transfer(
    input  bit                         write,
    input  logic [ADDR_WIDTH-1:0]      addr,
    input  logic [DATA_WIDTH-1:0]      wdata,
    input  logic [STRB_WIDTH-1:0]      strb,
    input  logic [2:0]                 prot,
    input  int unsigned                sel,
    input  int unsigned                idle_cycles,
    input  int unsigned                max_wait_cycles,  // 0 = no watchdog
    output logic [DATA_WIDTH-1:0]      rdata,
    output logic                       slverr,
    output int unsigned                wait_states,
    output apb_bfm_status_e            status
  );
    apb_bfm_status_e st;
    rdata       = '0;
    slverr      = 1'b0;
    wait_states = 0;
    status      = APB_ST_OK;

    if (!drive_en)           begin status = APB_ST_NOT_ENABLED;   return; end
    if (busy)                begin status = APB_ST_BAD_REQUEST;   return; end
    if (sel >= unsigned'(NUM_SEL)) begin status = APB_ST_BAD_REQUEST; return; end
    if (PRESETn !== 1'b1)    begin status = APB_ST_RESET_ABORTED; return; end

    busy = 1'b1;
    st   = APB_ST_OK;
    fork begin : guard  // isolates "disable fork" from the caller's processes
      fork
        begin : transfer
          repeat (idle_cycles) @(cb);
          drive_setup(write, addr, wdata, strb, prot, sel);
          if (fault != APB_FAULT_SKIP_SETUP) begin
            @(cb);                 // Completer samples SETUP at this edge
            penable_q <= 1'b1;     // ACCESS (APB-R04)
          end
          forever begin
            @(cb);
            if (!apb_has_pready(features.revision) || cb.PREADY === 1'b1) begin
              if (!write) rdata = cb.PRDATA;  // 4-state, verbatim
              slverr = apb_has_pslverr(features.revision) ? cb.PSLVERR : 1'b0;
              if (slverr === 1'b1) st = APB_ST_SLVERR;
              break;
            end
            if (wait_states == 0 && fault == APB_FAULT_PADDR_UNSTABLE)
              paddr_q <= ~addr;
            if (wait_states == 0 && fault == APB_FAULT_DROP_PSEL_IN_WAIT) begin
              st = APB_ST_FAULT_INJECTED;
              break;
            end
            wait_states++;
            if (max_wait_cycles != 0 && wait_states >= max_wait_cycles) begin
              st = APB_ST_TIMEOUT;  // POL-02; the Completer is abandoned mid-ACCESS
              break;
            end
          end
        end
        begin : reset_watch      // RST-2/RST-3: abandon the transfer at the reset edge
          wait (PRESETn !== 1'b1);
          st = APB_ST_RESET_ABORTED;
        end
      join_any
      disable fork;
    end join

    drive_idle();
    status = st;
    busy   = 1'b0;
  endtask

  // ---------------------------------------------------------------------------
  // Internal drive helpers
  // ---------------------------------------------------------------------------

  task automatic drive_setup(
    input bit                    write,
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] wdata,
    input logic [STRB_WIDTH-1:0] strb,
    input logic [2:0]            prot,
    input int unsigned           sel
  );
    logic [NUM_SEL-1:0] onehot = '0;
    onehot[sel] = 1'b1;
    psel_q    <= onehot;
    penable_q <= (fault == APB_FAULT_SKIP_SETUP);
    pwrite_q  <= write;
    paddr_q   <= addr;
    pwdata_q  <= write ? wdata : '0;                // A.1: not valid on reads
    pstrb_q   <= features.has_pstrb ? strb : '0;    // absent pin driven to 0
    pprot_q   <= features.has_pprot ? prot : 3'b000;
  endtask

  // IDLE values (APB-R02, APB-R14/POL-03)
  task automatic drive_idle();
    psel_q    <= '0;
    penable_q <= 1'b0;
    pwrite_q  <= 1'b0;
    paddr_q   <= '0;
    pwdata_q  <= '0;
    pstrb_q   <= '0;
    pprot_q   <= 3'b000;
  endtask

  // RST-1/RST-2: return to IDLE as soon as reset asserts (or goes X/Z)
  always @(PRESETn)
    if (PRESETn !== 1'b1) drive_idle();

  // Elaboration-time checks (widths must match the shared apb_if)
  if (DATA_WIDTH % 8 != 0) begin : g_bad_data_width
    $error("apb_driver_bfm_if: DATA_WIDTH=%0d is not a whole number of bytes", DATA_WIDTH);
  end
  if (NUM_SEL < 1) begin : g_bad_num_sel
    $error("apb_driver_bfm_if: NUM_SEL=%0d must be >= 1", NUM_SEL);
  end

endinterface : apb_driver_bfm_if
