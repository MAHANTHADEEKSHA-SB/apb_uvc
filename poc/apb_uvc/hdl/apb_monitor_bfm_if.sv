// -----------------------------------------------------------------------------
// apb_monitor_bfm_if — passive APB observation BFM
//
// Owns passive sampling and transfer reconstruction (ADR-002 decision 3).
// Every port is an input: this BFM can never drive the bus. It connects to
// the same apb_if instance as the driver BFM through ordinary signal ports.
//
// Transport (APB_PROTOCOL_CONTRACT section 7, RISK-002 — proposal until
// validated on the target simulator):
//   * an always-running process samples through a clocking block
//     (input #1step), independent of HVL timing;
//   * a transfer is published once, at the PCLK edge where
//     PSEL & PENABLE & PREADY is sampled HIGH (APB-R05), into a bounded queue
//     of plain packed values (no UVM objects in HDL, ADR-002 section 6);
//   * the HVL observe adapter calls the blocking task get_transfer().
//
// Protocol violations are counted per apb_mon_error_e code and optionally
// printed; the HVL side turns the counts into UVM reports.
//
// Milestone M1 checks APB2/APB3/APB4 behaviour. APB5 pins (wake-up, user,
// parity) are accepted as ports but not checked until M2/M3.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

interface apb_monitor_bfm_if
  import apb_bfm_pkg::*;
#(
  parameter int ADDR_WIDTH      = 32,
  parameter int DATA_WIDTH      = 32,
  parameter int NUM_SEL         = 1,
  parameter int USER_REQ_WIDTH  = 1,
  parameter int USER_DATA_WIDTH = 1,
  parameter int USER_RESP_WIDTH = 1,
  parameter int QUEUE_DEPTH     = 16
) (
  input wire logic                             PCLK,
  input wire logic                             PRESETn,
  // Requester outputs
  input wire logic [ADDR_WIDTH-1:0]            PADDR,
  input wire logic [2:0]                       PPROT,
  input wire logic [NUM_SEL-1:0]               PSEL,
  input wire logic                             PENABLE,
  input wire logic                             PWRITE,
  input wire logic [DATA_WIDTH-1:0]            PWDATA,
  input wire logic [DATA_WIDTH/8-1:0]          PSTRB,
  input wire logic                             PWAKEUP,
  input wire logic [USER_REQ_WIDTH-1:0]        PAUSER,
  input wire logic [USER_DATA_WIDTH-1:0]       PWUSER,
  input wire logic [(ADDR_WIDTH+7)/8-1:0]      PADDRCHK,
  input wire logic                             PCTRLCHK,
  input wire logic [NUM_SEL-1:0]               PSELCHK,
  input wire logic                             PENABLECHK,
  input wire logic [DATA_WIDTH/8-1:0]          PWDATACHK,
  input wire logic                             PSTRBCHK,
  input wire logic                             PWAKEUPCHK,
  input wire logic [(USER_REQ_WIDTH+7)/8-1:0]  PAUSERCHK,
  input wire logic [(USER_DATA_WIDTH+7)/8-1:0] PWUSERCHK,
  // Completer outputs
  input wire logic                             PREADY,
  input wire logic [DATA_WIDTH-1:0]            PRDATA,
  input wire logic                             PSLVERR,
  input wire logic [USER_DATA_WIDTH-1:0]       PRUSER,
  input wire logic [USER_RESP_WIDTH-1:0]       PBUSER,
  input wire logic                             PREADYCHK,
  input wire logic [DATA_WIDTH/8-1:0]          PRDATACHK,
  input wire logic                             PSLVERRCHK,
  input wire logic [(USER_DATA_WIDTH+7)/8-1:0] PRUSERCHK,
  input wire logic [(USER_RESP_WIDTH+7)/8-1:0] PBUSERCHK
);

  localparam int STRB_WIDTH = DATA_WIDTH / 8;

  // One observed transfer, kept as plain packed values
  typedef struct packed {
    logic                  write;
    logic [ADDR_WIDTH-1:0] addr;
    logic [DATA_WIDTH-1:0] wdata;
    logic [STRB_WIDTH-1:0] strb;
    logic [2:0]            prot;
    logic [NUM_SEL-1:0]    sel;
    logic [DATA_WIDTH-1:0] rdata;
    logic                  slverr;
    int unsigned           wait_states;
    longint unsigned       start_cycle;  // cycle of the SETUP sample
    longint unsigned       end_cycle;    // cycle of the completion sample
  } apb_obs_t;

  // Bus state as reconstructed from the samples (IHI 0024D Figure 4-1).
  typedef enum int unsigned { MON_IDLE, MON_SETUP, MON_ACCESS } mon_state_e;

  apb_features_t   features           = apb_default_features();
  bit              publish_en         = 1'b0;  // queue only when a consumer exists
  bit              verbose            = 1'b1;  // print each violation
  apb_obs_t        obs_q[$];
  event            obs_ev;                     // triggered on every publish
  int unsigned     error_count[APB_MON_NUM_ERRORS];
  int unsigned     transfer_count     = 0;     // completed transfers observed
  int unsigned     reset_count        = 0;     // resets after the first release
  int unsigned     aborted_count      = 0;     // transfers cut short by reset
  bit              in_reset           = 1'b1;
  bit              seen_reset_release = 1'b0;
  longint unsigned cycle              = 0;
  mon_state_e      state              = MON_IDLE;
  apb_obs_t        cur;

  // Every input is sampled 1step before the PCLK rising edge: the values that were
  // stable during the cycle, race-free against any driver (HDL-05).
  clocking cb @(posedge PCLK);
    default input #1step;
    input PRESETn, PADDR, PPROT, PSEL, PENABLE, PWRITE, PWDATA, PSTRB,
          PREADY, PRDATA, PSLVERR;
  endclocking

  // ---------------------------------------------------------------------------
  // Control / observation API (called by the HVL observe adapter)
  // ---------------------------------------------------------------------------

  function automatic bit configure(apb_features_t f);
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
    features = f;
    return 1'b1;
  endfunction

  // Queue completed transfers for get_transfer() only once a consumer exists, so an
  // unused monitor cannot overflow. transfer_count counts either way.
  function automatic void set_publish(bit en);
    publish_en = en;
  endfunction

  // Print each violation when it happens; the counters are kept either way.
  function automatic void set_verbose(bit en);
    verbose = en;
  endfunction

  // Violation counters per apb_mon_error_e; apb_monitor reports them in check_phase.
  function automatic int unsigned get_error_count(apb_mon_error_e code);
    return error_count[code];
  endfunction

  function automatic int unsigned get_total_errors();
    int unsigned total = 0;
    foreach (error_count[i]) total += error_count[i];
    return total;
  endfunction

  function automatic void clear_errors();
    foreach (error_count[i]) error_count[i] = 0;
  endfunction

  // Blocks until a completed transfer is available, then removes it. The
  // queue is checked before waiting, so a publish earlier in the same time
  // step is never missed.
  task automatic get_transfer(
    output bit                    write,
    output logic [ADDR_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0] wdata,
    output logic [STRB_WIDTH-1:0] strb,
    output logic [2:0]            prot,
    output logic [NUM_SEL-1:0]    sel,
    output logic [DATA_WIDTH-1:0] rdata,
    output logic                  slverr,
    output int unsigned           wait_states,
    output longint unsigned       start_cycle,
    output longint unsigned       end_cycle
  );
    apb_obs_t o;
    while (obs_q.size() == 0) @(obs_ev);
    o           = obs_q.pop_front();
    write       = o.write;
    addr        = o.addr;
    wdata       = o.wdata;
    strb        = o.strb;
    prot        = o.prot;
    sel         = o.sel;
    rdata       = o.rdata;
    slverr      = o.slverr;
    wait_states = o.wait_states;
    start_cycle = o.start_cycle;
    end_cycle   = o.end_cycle;
  endtask

  // ---------------------------------------------------------------------------
  // Sampling process
  // ---------------------------------------------------------------------------

  // Free-running sampler: one sample_cycle() per PCLK edge, independent of the HVL
  // side (APB_PROTOCOL_CONTRACT section 7).
  initial forever begin
    @(cb);
    cycle++;
    sample_cycle();
  end

  // Count one violation; when verbose, print it with time, instance and PCLK cycle.
  task automatic flag(apb_mon_error_e code, string msg);
    error_count[code]++;
    if (verbose)
      $display("%0t APB_MON_ERROR %m [%s] cycle=%0d: %s", $realtime, code.name(), cycle, msg);
  endtask

  // Count a completed transfer. When publishing, queue it (bounded: an overflow is
  // itself a violation) and wake a get_transfer() caller.
  task automatic publish(apb_obs_t o);
    transfer_count++;
    if (!publish_en) return;
    if (obs_q.size() >= QUEUE_DEPTH) begin
      flag(APB_MON_ERR_QUEUE_OVERFLOW, "observation queue full; transfer dropped");
      return;
    end
    obs_q.push_back(o);
    -> obs_ev;
  endtask

  // Capture the request-side values of a transfer from the current sample
  task automatic capture_request();
    cur             = '0;
    cur.write       = cb.PWRITE;
    cur.addr        = cb.PADDR;
    cur.wdata       = cb.PWRITE ? cb.PWDATA : '0;
    cur.strb        = features.has_pstrb ? cb.PSTRB : '0;
    cur.prot        = features.has_pprot ? cb.PPROT : 3'b000;  // IHI Table B-1 default
    cur.sel         = cb.PSEL;
    cur.start_cycle = cycle;
    if ($isunknown(cb.PADDR) || $isunknown(cb.PWRITE) ||
        (features.has_pprot && $isunknown(cb.PPROT)) ||
        (features.has_pstrb && $isunknown(cb.PSTRB)))
      flag(APB_MON_ERR_CONTROL_XZ, "PADDR/PWRITE/PPROT/PSTRB X/Z while PSEL asserted");
    if (features.has_pstrb && cb.PWRITE === 1'b0 && cb.PSTRB !== '0)
      flag(APB_MON_ERR_PSTRB_ON_READ, $sformatf("PSTRB=%0h on a read", cb.PSTRB));
  endtask

  // APB-R04: request-side signals must not change during ACCESS
  task automatic check_stable();
    string bad = "";
    if (cb.PSEL   !== cur.sel)   bad = {bad, " PSEL"};
    if (cb.PADDR  !== cur.addr)  bad = {bad, " PADDR"};
    if (cb.PWRITE !== cur.write) bad = {bad, " PWRITE"};
    if (features.has_pprot && cb.PPROT !== cur.prot) bad = {bad, " PPROT"};
    if (features.has_pstrb && cb.PSTRB !== cur.strb) bad = {bad, " PSTRB"};
    if (cur.write === 1'b1 && cb.PWDATA !== cur.wdata) bad = {bad, " PWDATA"};
    if (bad != "") flag(APB_MON_ERR_UNSTABLE_IN_ACCESS, {"changed during ACCESS:", bad});
  endtask

  // Process one PCLK sample, in this order: reset (RST-4/6/7), PSEL validity
  // (APB-R13), IDLE, SETUP capture (APB-R03), ACCESS stability (APB-R04) and the
  // completion point (APB-R05). Consumes no time.
  task automatic sample_cycle();
    logic pready;

    // Reset (RST-4, RST-6, RST-7)
    if (cb.PRESETn !== 1'b1) begin
      if (cb.PRESETn !== 1'b0 && seen_reset_release)
        flag(APB_MON_ERR_PRESETN_XZ, "PRESETn is X/Z");
      if (!in_reset) begin
        reset_count++;
        if (state != MON_IDLE) aborted_count++;
      end
      in_reset = 1'b1;
      state    = MON_IDLE;  // a partial transfer is discarded, never published
      return;
    end
    if (in_reset) begin
      in_reset           = 1'b0;
      seen_reset_release = 1'b1;
    end

    // APB-R13: PSEL must always be valid
    if ($isunknown(cb.PSEL)) begin
      flag(APB_MON_ERR_PSEL_XZ, "PSEL is X/Z");
      state = MON_IDLE;
      return;
    end
    if (!$onehot0(cb.PSEL))
      flag(APB_MON_ERR_MULTIPLE_PSEL,
           $sformatf("PSEL=%b selects more than one Completer", cb.PSEL));

    // IDLE
    if (cb.PSEL == '0) begin
      if (state == MON_SETUP)
        flag(APB_MON_ERR_SETUP_NOT_FOLLOWED_BY_ACCESS, "PSEL deasserted after SETUP");
      else if (state == MON_ACCESS)
        flag(APB_MON_ERR_PSEL_DROPPED_IN_ACCESS, "PSEL deasserted while PREADY LOW");
      state = MON_IDLE;
      return;
    end

    if ($isunknown(cb.PENABLE)) begin
      flag(APB_MON_ERR_CONTROL_XZ, "PENABLE X/Z while PSEL asserted");
      state = MON_IDLE;
      return;
    end

    // SETUP (APB-R03): a new transfer starts
    if (cb.PENABLE == 1'b0) begin
      if (state == MON_SETUP)
        flag(APB_MON_ERR_SETUP_NOT_FOLLOWED_BY_ACCESS, "SETUP lasted more than one cycle");
      else if (state == MON_ACCESS)
        flag(APB_MON_ERR_UNSTABLE_IN_ACCESS, "PENABLE deasserted while PREADY LOW");
      capture_request();
      state = MON_SETUP;
      return;
    end

    // ACCESS (APB-R04)
    if (state == MON_IDLE) begin
      flag(APB_MON_ERR_ACCESS_WITHOUT_SETUP, "PSEL & PENABLE without a SETUP cycle");
      capture_request();  // still reconstruct the transfer the Completer sees
    end else begin
      check_stable();
    end
    state = MON_ACCESS;

    // PREADY: APB2 has none, so the IHI Table B-1 default (1) applies
    if (apb_has_pready(features.revision)) begin
      if ($isunknown(cb.PREADY))
        flag(APB_MON_ERR_PREADY_XZ, "PREADY X/Z during ACCESS");
      pready = cb.PREADY;
    end else begin
      pready = 1'b1;
    end

    if (pready === 1'b1) begin  // completion point (APB-R05)
      cur.rdata     = cur.write ? '0 : cb.PRDATA;  // APB-R10, 4-state verbatim
      cur.slverr    = apb_has_pslverr(features.revision) ? cb.PSLVERR : 1'b0;
      cur.end_cycle = cycle;
      publish(cur);
      state = MON_IDLE;  // next sample must be IDLE or SETUP
    end else begin
      cur.wait_states++;
    end
  endtask

endinterface : apb_monitor_bfm_if
