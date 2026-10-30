// -----------------------------------------------------------------------------
// apb_transaction — one APB transfer, independent of the bus width
//
// The same class serves every instance (ADR-001 decision 1). Payload fields
// use the compile-time maxima APB_MAX_AW/DW/SW; bits at or above the bound
// bus width must be zero, and the drive adapter rejects any other value
// instead of truncating it (APB_PROTOCOL_CONTRACT section 6).
//
// All payload fields are 4-state `logic`: observed X/Z values are kept.
// The bus context (widths, present features) is plain state copied from the
// agent configuration before randomization, so constraints keep generated
// values legal for the instance the item will run on.
// Included by apb_api_pkg.
// -----------------------------------------------------------------------------

typedef enum bit {
  APB_READ  = 1'b0,
  APB_WRITE = 1'b1
} apb_dir_e;

// Request fields are randomized by sequences. Response fields are filled in place
// by the driver, or set by the observe adapter on a new object per transfer.
class apb_transaction extends uvm_sequence_item;
  `uvm_object_utils(apb_transaction)

  // ---- Request --------------------------------------------------------------
  rand apb_dir_e              dir;
  rand logic [APB_MAX_AW-1:0] addr;
  rand logic [APB_MAX_DW-1:0] wdata;
  rand logic [APB_MAX_SW-1:0] strb;
  rand logic [2:0]            prot;         // IHI 0024D Table 3-2
  rand int unsigned           sel;          // index into PSEL[NUM_SEL-1:0]
  rand int unsigned           idle_cycles;  // IDLE cycles before SETUP; 0 = back-to-back

  // ---- Bus context (not randomized) ------------------------------------------
  int unsigned bus_addr_width = APB_MAX_AW;
  int unsigned bus_data_width = APB_MAX_DW;
  int unsigned bus_num_sel    = 1;
  bit          bus_has_pstrb  = 1'b1;
  bit          bus_has_pprot  = 1'b1;

  // ---- Response / observation -------------------------------------------------
  logic [APB_MAX_DW-1:0] rdata;        // zero-extended from the bus width
  logic                  slverr;       // observed PSLVERR, 4-state
  apb_bfm_status_e       status;       // driver result; monitor: OK or SLVERR
  int unsigned           wait_states;
  longint unsigned       start_cycle;  // monitor only: PCLK sample of SETUP
  longint unsigned       end_cycle;    // monitor only: PCLK sample of completion
  string                 instance_name;

  // ---- Constraints -------------------------------------------------------------
  // Values must fit the bound bus (lossless rule)
  constraint c_fit_bus {
    (addr  >> bus_addr_width)       == 0;
    (wdata >> bus_data_width)       == 0;
    (strb  >> (bus_data_width / 8)) == 0;
    sel < bus_num_sel;
  }

  // POL-01: aligned addresses unless a test disables this constraint
  constraint c_aligned {
    (addr % (bus_data_width / 8)) == 0;
  }

  // APB-R09: no strobes on reads. IHI 0024D Table 3-1: without PSTRB every
  // write is a full-width write. Otherwise full-width writes by default.
  constraint c_strb {
    (dir == APB_READ) -> strb == 0;
    (dir == APB_WRITE && !bus_has_pstrb) -> strb == ((1 << (bus_data_width / 8)) - 1);
    if (dir == APB_WRITE) soft strb == ((1 << (bus_data_width / 8)) - 1);
  }

  // Absent PPROT is driven as 0b000 (IHI 0024D Table B-1 default)
  constraint c_prot {
    !bus_has_pprot -> prot == 3'b000;
  }

  // Short IDLE gaps by default; 0 gives back-to-back transfers (APB-R05).
  constraint c_idle {
    soft idle_cycles inside {[0:2]};
  }

  // status starts OK; the response fields are filled later.
  function new(string name = "apb_transaction");
    super.new(name);
    status = APB_ST_OK;
  endfunction

  // Copy the bound instance's widths and features (call before randomize)
  function void set_bus_context(int unsigned addr_width, int unsigned data_width,
                                int unsigned num_sel, bit has_pstrb, bit has_pprot);
    bus_addr_width = addr_width;
    bus_data_width = data_width;
    bus_num_sel    = num_sel;
    bus_has_pstrb  = has_pstrb;
    bus_has_pprot  = has_pprot;
  endfunction

  // All byte lanes of the bound bus
  function logic [APB_MAX_SW-1:0] full_strb();
    logic [APB_MAX_SW-1:0] mask = '0;
    for (int unsigned i = 0; i < bus_data_width / 8; i++) mask[i] = 1'b1;
    return mask;
  endfunction

  // Deep copy of every field, including bus context and observation stamps (UVM-03).
  virtual function void do_copy(uvm_object rhs);
    apb_transaction rhs_;
    super.do_copy(rhs);
    if (!$cast(rhs_, rhs)) begin
      `uvm_fatal("APB_TXN", "do_copy: argument is not an apb_transaction")
      return;
    end
    dir            = rhs_.dir;
    addr           = rhs_.addr;
    wdata          = rhs_.wdata;
    strb           = rhs_.strb;
    prot           = rhs_.prot;
    sel            = rhs_.sel;
    idle_cycles    = rhs_.idle_cycles;
    bus_addr_width = rhs_.bus_addr_width;
    bus_data_width = rhs_.bus_data_width;
    bus_num_sel    = rhs_.bus_num_sel;
    bus_has_pstrb  = rhs_.bus_has_pstrb;
    bus_has_pprot  = rhs_.bus_has_pprot;
    rdata          = rhs_.rdata;
    slverr         = rhs_.slverr;
    status         = rhs_.status;
    wait_states    = rhs_.wait_states;
    start_cycle    = rhs_.start_cycle;
    end_cycle      = rhs_.end_cycle;
    instance_name  = rhs_.instance_name;
  endfunction

  // Compares the bus-visible content with 4-state equality
  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    apb_transaction rhs_;
    if (!$cast(rhs_, rhs)) return 1'b0;
    return super.do_compare(rhs, comparer) &&
           dir    == rhs_.dir    &&
           addr   === rhs_.addr  &&
           (dir == APB_READ || wdata === rhs_.wdata) &&
           strb   === rhs_.strb  &&
           prot   === rhs_.prot  &&
           sel    == rhs_.sel    &&
           (dir == APB_WRITE || rdata === rhs_.rdata) &&
           slverr === rhs_.slverr;
  endfunction

  // One line for logs; data is wdata for writes and rdata for reads.
  virtual function string convert2string();
    return $sformatf("%s %s addr=%0h data=%0h strb=%0h prot=%0b sel=%0d -> %s slverr=%b waits=%0d",
                     instance_name, dir == APB_WRITE ? "WR" : "RD", addr,
                     dir == APB_WRITE ? wdata : rdata, strb, prot, sel,
                     status.name(), slverr, wait_states);
  endfunction

endclass : apb_transaction
