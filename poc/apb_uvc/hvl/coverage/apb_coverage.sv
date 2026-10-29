// -----------------------------------------------------------------------------
// apb_coverage — functional coverage of observed APB transfers
//
// Protocol-level coverage only (no DUT register map): direction, wait
// states, PSLVERR, strobe pattern, back-to-back transfers and PPROT, with
// the crosses the CLAUDE_GENERATION_PROMPT checks call for. Connected to the
// monitor's analysis port by apb_agent when cfg.enable_coverage is set.
// Reset transitions are not covered yet (WORK_STATUS gap list).
// Included by apb_uvc_pkg.
// -----------------------------------------------------------------------------

class apb_coverage extends uvm_subscriber #(apb_transaction);
  `uvm_component_utils(apb_coverage)

  typedef enum { STRB_NONE, STRB_FULL, STRB_PARTIAL } strb_kind_e;

  apb_agent_cfg cfg;  // set by apb_agent

  protected longint unsigned prev_end;
  protected bit              has_prev;

  covergroup cg with function sample(apb_dir_e dir, int unsigned waits, bit slverr,
                                     strb_kind_e strb_kind, bit b2b, logic [2:0] prot);
    option.per_instance = 1;

    cp_dir    : coverpoint dir;
    cp_waits  : coverpoint waits {
      bins zero    = {0};
      bins one     = {1};
      bins two     = {2};
      bins several = {[3:$]};
    }
    cp_slverr : coverpoint slverr;
    cp_strb   : coverpoint strb_kind iff (dir == APB_WRITE) {
      ignore_bins none_on_write = {STRB_NONE};
    }
    cp_b2b    : coverpoint b2b;
    cp_prot   : coverpoint prot iff (cfg != null && cfg.features.has_pprot);

    x_dir_waits  : cross cp_dir, cp_waits;
    x_dir_slverr : cross cp_dir, cp_slverr;
    x_dir_b2b    : cross cp_dir, cp_b2b;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg = new();
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cg.set_inst_name(get_full_name());
  endfunction

  virtual function void write(apb_transaction t);
    bit b2b = has_prev && (t.start_cycle == prev_end + 1);
    cg.sample(t.dir, t.wait_states, t.slverr === 1'b1, classify_strb(t), b2b, t.prot);
    prev_end = t.end_cycle;
    has_prev = 1'b1;
  endfunction

  protected function strb_kind_e classify_strb(apb_transaction t);
    if (t.strb == 0)              return STRB_NONE;
    if (t.strb == t.full_strb())  return STRB_FULL;
    return STRB_PARTIAL;
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("APB_COV", $sformatf("%s: coverage %0.1f%%", get_full_name(), cg.get_inst_coverage()),
              UVM_LOW)
  endfunction

endclass : apb_coverage
