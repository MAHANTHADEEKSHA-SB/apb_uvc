// -----------------------------------------------------------------------------
// apb_monitor_proxy — concrete observe adapter for one bus specialization
//
// Holds a typed virtual handle to apb_monitor_bfm_if with exactly the
// parameters of the bound instance (ADR-001 decision 2). receive() takes the
// next completed transfer from the BFM (plain values, no UVM objects in HDL —
// ADR-002 section 6) and builds a new apb_transaction from it, zero-extending
// every field to the transaction maxima with X/Z preserved.
//
// Built explicitly by the integration code (no factory, ADR-001 decision 5).
// Included by apb_adapter_pkg.
// -----------------------------------------------------------------------------

class apb_monitor_proxy #(
  int ADDR_WIDTH      = 32,
  int DATA_WIDTH      = 32,
  int NUM_SEL         = 1,
  int USER_REQ_WIDTH  = 1,
  int USER_DATA_WIDTH = 1,
  int USER_RESP_WIDTH = 1,
  int QUEUE_DEPTH     = 16
) extends apb_monitor_proxy_base;

  typedef virtual apb_monitor_bfm_if #(
    .ADDR_WIDTH     (ADDR_WIDTH),
    .DATA_WIDTH     (DATA_WIDTH),
    .NUM_SEL        (NUM_SEL),
    .USER_REQ_WIDTH (USER_REQ_WIDTH),
    .USER_DATA_WIDTH(USER_DATA_WIDTH),
    .USER_RESP_WIDTH(USER_RESP_WIDTH),
    .QUEUE_DEPTH    (QUEUE_DEPTH)
  ) vif_t;

  localparam int STRB_WIDTH = DATA_WIDTH / 8;

  protected vif_t          vif;
  protected apb_features_t features;

  function new(string name, vif_t vif);
    super.new(name);
    if (vif == null)
      `uvm_fatal("APB_PROXY", $sformatf("%s: null monitor BFM handle", name))
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

  virtual function void set_publish(bit en);
    vif.set_publish(en);
  endfunction

  virtual function void set_verbose(bit en);
    vif.set_verbose(en);
  endfunction

  virtual task receive(output apb_transaction observed);
    bit                    write;
    logic [ADDR_WIDTH-1:0] addr;
    logic [DATA_WIDTH-1:0] wdata;
    logic [DATA_WIDTH-1:0] rdata;
    logic [STRB_WIDTH-1:0] strb;
    logic [2:0]            prot;
    logic [NUM_SEL-1:0]    sel;
    logic                  slverr;
    int unsigned           waits;
    longint unsigned       start_cycle;
    longint unsigned       end_cycle;

    vif.get_transfer(write, addr, wdata, strb, prot, sel, rdata, slverr, waits,
                     start_cycle, end_cycle);

    observed = apb_transaction::type_id::create("observed");
    observed.set_bus_context(ADDR_WIDTH, DATA_WIDTH, NUM_SEL, features.has_pstrb, features.has_pprot);
    observed.instance_name = get_name();
    observed.dir           = write ? APB_WRITE : APB_READ;
    observed.addr          = APB_MAX_AW'(addr);
    observed.wdata         = APB_MAX_DW'(wdata);
    observed.rdata         = APB_MAX_DW'(rdata);
    observed.strb          = APB_MAX_SW'(strb);
    observed.prot          = prot;
    observed.sel           = onehot_index(sel);
    observed.slverr        = slverr;
    observed.status        = (slverr === 1'b1) ? APB_ST_SLVERR : APB_ST_OK;
    observed.wait_states   = waits;
    observed.start_cycle   = start_cycle;
    observed.end_cycle     = end_cycle;
    observed.idle_cycles   = 0;  // not observable from the bus
  endtask

  virtual function int unsigned get_error_count(apb_mon_error_e code);
    return vif.get_error_count(code);
  endfunction

  virtual function int unsigned get_total_errors();
    return vif.get_total_errors();
  endfunction

  virtual function void clear_errors();
    vif.clear_errors();
  endfunction

  virtual function int unsigned get_transfer_count();
    return vif.transfer_count;
  endfunction

  virtual function int unsigned get_reset_count();
    return vif.reset_count;
  endfunction

  // First selected Completer; the BFM reports MULTIPLE_PSEL separately
  protected function int unsigned onehot_index(logic [NUM_SEL-1:0] sel);
    for (int i = 0; i < NUM_SEL; i++)
      if (sel[i] === 1'b1) return i;
    return 0;
  endfunction

endclass : apb_monitor_proxy
