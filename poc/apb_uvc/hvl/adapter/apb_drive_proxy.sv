// -----------------------------------------------------------------------------
// apb_drive_proxy — concrete drive adapter for one bus specialization
//
// Holds a typed virtual handle to apb_driver_bfm_if with exactly the
// parameters of the bound instance (ADR-001 decision 2) and converts the
// width-independent apb_transaction into a BFM do_transfer() call.
//
// Boundary rules (ADR-001 decision 4, APB_PROTOCOL_CONTRACT section 6):
//   * a null handle, or a bus wider than the transaction maxima, is fatal at
//     construction
//   * a request that cannot be driven losslessly or legally is rejected with
//     uvm_error and status APB_ST_BAD_REQUEST; nothing is truncated
//
// Built explicitly by the integration code (no factory, ADR-001 decision 5).
// Included by apb_adapter_pkg.
// -----------------------------------------------------------------------------

class apb_drive_proxy #(
  int ADDR_WIDTH      = 32,
  int DATA_WIDTH      = 32,
  int NUM_SEL         = 1,
  int USER_REQ_WIDTH  = 1,
  int USER_DATA_WIDTH = 1,
  int USER_RESP_WIDTH = 1
) extends apb_drive_proxy_base;

  typedef virtual apb_driver_bfm_if #(
    .ADDR_WIDTH     (ADDR_WIDTH),
    .DATA_WIDTH     (DATA_WIDTH),
    .NUM_SEL        (NUM_SEL),
    .USER_REQ_WIDTH (USER_REQ_WIDTH),
    .USER_DATA_WIDTH(USER_DATA_WIDTH),
    .USER_RESP_WIDTH(USER_RESP_WIDTH)
  ) vif_t;

  localparam int STRB_WIDTH = DATA_WIDTH / 8;

  protected vif_t          vif;
  protected apb_features_t features;

  function new(string name, vif_t vif);
    super.new(name);
    if (vif == null)
      `uvm_fatal("APB_PROXY", $sformatf("%s: null driver BFM handle", name))
    if (ADDR_WIDTH > APB_MAX_AW || DATA_WIDTH > APB_MAX_DW)
      `uvm_fatal("APB_PROXY", $sformatf(
        "%s: bus AW=%0d DW=%0d exceeds transaction maxima AW=%0d DW=%0d; set +define+APB_MAX_DATA_WIDTH",
        name, ADDR_WIDTH, DATA_WIDTH, APB_MAX_AW, APB_MAX_DW))
    this.vif      = vif;
    this.features = apb_default_features();
  endfunction

  virtual function int unsigned get_addr_width();
    return ADDR_WIDTH;
  endfunction

  virtual function int unsigned get_data_width();
    return DATA_WIDTH;
  endfunction

  virtual function int unsigned get_num_sel();
    return NUM_SEL;
  endfunction

  virtual function bit configure(apb_features_t features);
    if (!vif.configure(features)) return 1'b0;
    this.features = features;
    return 1'b1;
  endfunction

  virtual function void set_enable(bit en);
    vif.set_enable(en);
  endfunction

  virtual function void set_fault(apb_fault_e fault);
    vif.set_fault(fault);
  endfunction

  virtual task wait_for_reset_release(int unsigned idle_cycles);
    vif.wait_for_reset_release(idle_cycles);
  endtask

  virtual task send(apb_transaction req);
    logic [DATA_WIDTH-1:0] rdata;
    logic                  slverr;
    int unsigned           waits;
    apb_bfm_status_e       st;

    req.instance_name = get_name();
    req.set_bus_context(ADDR_WIDTH, DATA_WIDTH, NUM_SEL, features.has_pstrb, features.has_pprot);
    req.rdata       = '0;
    req.slverr      = 1'b0;
    req.wait_states = 0;
    if (!request_ok(req)) begin
      req.status = APB_ST_BAD_REQUEST;
      return;
    end

    vif.do_transfer(req.dir == APB_WRITE,
                    ADDR_WIDTH'(req.addr), DATA_WIDTH'(req.wdata), STRB_WIDTH'(req.strb),
                    req.prot, req.sel, req.idle_cycles, max_wait_cycles,
                    rdata, slverr, waits, st);

    req.rdata       = APB_MAX_DW'(rdata);  // zero-extended, 4-state preserved
    req.slverr      = slverr;
    req.wait_states = waits;
    req.status      = st;
  endtask

  // Every reason a request cannot be driven as written; reports each one
  protected function bit request_ok(apb_transaction req);
    logic [APB_MAX_SW-1:0] full_lanes = req.full_strb();
    bit ok = 1'b1;

    if ($isunknown(req.addr) || $isunknown(req.strb) || $isunknown(req.prot)) begin
      `uvm_error("APB_REQ", {get_name(), ": X/Z in addr/strb/prot: ", req.convert2string()})
      return 1'b0;  // the checks below need known values
    end
    if (req.dir == APB_WRITE && !allow_x_wdata && $isunknown(req.wdata)) begin
      `uvm_error("APB_REQ", {get_name(), ": X/Z in write data: ", req.convert2string()})
      ok = 1'b0;
    end
    // Lossless rule: every bit at or above the bus width must be a known 0
    if (!upper_bits_zero_addr(req.addr)) begin
      `uvm_error("APB_REQ", $sformatf("%s: addr %0h does not fit AW=%0d", get_name(), req.addr, ADDR_WIDTH))
      ok = 1'b0;
    end
    if (!upper_bits_zero_data(req.wdata)) begin
      `uvm_error("APB_REQ", $sformatf("%s: wdata %0h does not fit DW=%0d", get_name(), req.wdata, DATA_WIDTH))
      ok = 1'b0;
    end
    if (!upper_bits_zero_strb(req.strb)) begin
      `uvm_error("APB_REQ", $sformatf("%s: strb %0h does not fit DW=%0d", get_name(), req.strb, DATA_WIDTH))
      ok = 1'b0;
    end
    if (req.sel >= NUM_SEL) begin
      `uvm_error("APB_REQ", $sformatf("%s: sel %0d with NUM_SEL=%0d", get_name(), req.sel, NUM_SEL))
      ok = 1'b0;
    end
    if (!allow_unaligned && (req.addr % STRB_WIDTH) != 0) begin       // POL-01
      `uvm_error("APB_REQ", $sformatf("%s: unaligned addr %0h", get_name(), req.addr))
      ok = 1'b0;
    end
    if (!features.has_pprot && req.prot != 3'b000) begin                // Table B-1
      `uvm_error("APB_REQ", $sformatf("%s: prot %0b but PPROT is absent", get_name(), req.prot))
      ok = 1'b0;
    end
    if (req.dir == APB_READ && req.strb != 0) begin                     // APB-R09
      `uvm_error("APB_REQ", $sformatf("%s: strb %0h on a read", get_name(), req.strb))
      ok = 1'b0;
    end
    if (req.dir == APB_WRITE && !features.has_pstrb && req.strb != full_lanes) begin  // Table 3-1
      `uvm_error("APB_REQ", $sformatf("%s: sparse write strb %0h but PSTRB is absent",
                                      get_name(), req.strb))
      ok = 1'b0;
    end
    return ok;
  endfunction

  // 1 when every bit at index >= the bus width is a known 0. Written as a
  // loop rather than `value >> WIDTH`, which shifts by the full operand
  // width whenever the bus is as wide as the transaction.
  protected function bit upper_bits_zero_addr(logic [APB_MAX_AW-1:0] value);
    for (int unsigned i = ADDR_WIDTH; i < APB_MAX_AW; i++)
      if (value[i] !== 1'b0) return 1'b0;
    return 1'b1;
  endfunction

  protected function bit upper_bits_zero_data(logic [APB_MAX_DW-1:0] value);
    for (int unsigned i = DATA_WIDTH; i < APB_MAX_DW; i++)
      if (value[i] !== 1'b0) return 1'b0;
    return 1'b1;
  endfunction

  protected function bit upper_bits_zero_strb(logic [APB_MAX_SW-1:0] value);
    for (int unsigned i = STRB_WIDTH; i < APB_MAX_SW; i++)
      if (value[i] !== 1'b0) return 1'b0;
    return 1'b1;
  endfunction

endclass : apb_drive_proxy
