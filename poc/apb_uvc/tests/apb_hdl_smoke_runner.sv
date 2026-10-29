// -----------------------------------------------------------------------------
// apb_hdl_smoke_runner — directed HDL-only sequence for ONE APB UVC instance
//
// Bound once per width into apb_hdl_top by apb_hdl_smoke. Reaches its
// instance only through the driver/monitor BFM APIs (generic interface
// ports), the same calls the HVL adapters will make.
//
// Sequence: write/read-back with 0 and 2 wait states, a back-to-back
// write->read with no IDLE cycle (APB-R05), a PSTRB partial write
// (IHI 0024D 3.2) and a PSLVERR read (IHI 0024D 3.4). The monitor must
// publish exactly these transfers with matching values and report zero
// protocol errors.
//
// With FAULT_TARGET=1 and +APB_FAULT=<n> (apb_fault_e) the driver injects
// that fault; the runner then passes only if the monitor reports the
// matching violation.
//
// A width-parameterized class holding typed virtual BFM handles was the
// first choice here, but Verilator 5.020 faults on two specializations of
// such a class, and it cannot bind a generic interface port to a
// hierarchical instance (REVIEW_FEEDBACK RISK-001); hence a bound module.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

module apb_hdl_smoke_runner
  import apb_bfm_pkg::*;
#(
  parameter int    ADDR_WIDTH   = 32,
  parameter int    DATA_WIDTH   = 32,
  parameter bit    FAULT_TARGET = 1'b0,
  parameter string NAME         = "apb"
) (
  apb_driver_bfm_if  drv,
  apb_monitor_bfm_if mon
);

  localparam int AW = ADDR_WIDTH;
  localparam int DW = DATA_WIDTH;
  localparam int SW = DW / 8;
  localparam logic [63:0] P1 = 64'hA5A5_5A5A_DEAD_BEEF;
  localparam logic [63:0] P2 = 64'h0123_4567_89AB_CDEF;
  localparam logic [63:0] P3 = 64'hFEDC_BA98_7654_3210;
  localparam logic [63:0] P4 = 64'h1357_9BDF_2468_ACE0;

  apb_fault_e  fault    = APB_FAULT_NONE;
  int unsigned failures = 0;
  bit          done     = 1'b0;

  // Expected bus transfers, in order
  bit            exp_write[$];
  logic [AW-1:0] exp_addr[$];
  logic [DW-1:0] exp_data[$];   // wdata for writes, rdata for reads
  logic [SW-1:0] exp_strb[$];
  bit            exp_slverr[$];
  int unsigned   exp_waits[$];

  function automatic void check(bit ok, string msg);
    if (!ok) begin
      failures++;
      $display("SMOKE_FAIL [%s] %s", NAME, msg);
    end
  endfunction

  task automatic xfer(bit write, logic [AW-1:0] addr, logic [DW-1:0] wdata,
                      logic [SW-1:0] strb, int unsigned idle,
                      logic [DW-1:0] exp_rdata, apb_bfm_status_e exp_st,
                      int unsigned exp_ws);
    logic [DW-1:0]   rdata;
    logic            slverr;
    int unsigned     ws;
    apb_bfm_status_e st;
    drv.do_transfer(write, addr, wdata, write ? strb : '0, 3'b000, 0, idle, 64,
                    rdata, slverr, ws, st);
    if (fault != APB_FAULT_NONE) return;  // only the monitor verdict matters
    check(st == exp_st, $sformatf("addr %0h: status %s, expected %s",
                                  addr, st.name(), exp_st.name()));
    check(ws == exp_ws, $sformatf("addr %0h: %0d wait states, expected %0d",
                                  addr, ws, exp_ws));
    if (!write)
      check(rdata === exp_rdata, $sformatf("addr %0h: rdata %0h, expected %0h",
                                           addr, rdata, exp_rdata));
    exp_write.push_back(write);
    exp_addr.push_back(addr);
    exp_data.push_back(write ? wdata : exp_rdata);
    exp_strb.push_back(write ? strb : '0);
    exp_slverr.push_back(exp_st == APB_ST_SLVERR);
    exp_waits.push_back(exp_ws);
  endtask

  task automatic check_fault_detected();
    apb_mon_error_e want;
    case (fault)
      APB_FAULT_PADDR_UNSTABLE: want = APB_MON_ERR_UNSTABLE_IN_ACCESS;
      APB_FAULT_SKIP_SETUP:     want = APB_MON_ERR_ACCESS_WITHOUT_SETUP;
      default:                  want = APB_MON_ERR_PSEL_DROPPED_IN_ACCESS;
    endcase
    check(mon.get_error_count(want) > 0,
          $sformatf("injected %s NOT detected (%s count is 0)", fault.name(), want.name()));
    $display("SMOKE_INFO [%s] fault %s -> monitor %s count=%0d, total errors=%0d",
             NAME, fault.name(), want.name(), mon.get_error_count(want),
             mon.get_total_errors());
  endtask

  task automatic check_monitor();
    bit                    write;
    logic [AW-1:0]         addr;
    logic [DW-1:0]         wdata, rdata;
    logic [SW-1:0]         strb;
    logic [2:0]            prot;
    logic [0:0]            sel;
    logic                  slverr;
    int unsigned           ws;
    longint unsigned       start_c, end_c, prev_end;

    // Drain the expected observations first: the driver returns at the
    // completion edge, possibly before the monitor has sampled that edge.
    prev_end = 0;
    foreach (exp_write[i]) begin
      mon.get_transfer(write, addr, wdata, strb, prot, sel, rdata, slverr, ws, start_c, end_c);
      check(write == exp_write[i] && addr === exp_addr[i],
            $sformatf("obs %0d: %s @%0h, expected %s @%0h", i, write ? "WR" : "RD", addr,
                      exp_write[i] ? "WR" : "RD", exp_addr[i]));
      check((write ? wdata : rdata) === exp_data[i],
            $sformatf("obs %0d: data %0h, expected %0h", i, write ? wdata : rdata, exp_data[i]));
      check(strb === exp_strb[i],
            $sformatf("obs %0d: strb %0h, expected %0h", i, strb, exp_strb[i]));
      check(slverr === exp_slverr[i],
            $sformatf("obs %0d: slverr %0b, expected %0b", i, slverr, exp_slverr[i]));
      check(ws == exp_waits[i],
            $sformatf("obs %0d: %0d wait states, expected %0d", i, ws, exp_waits[i]));
      check(end_c - start_c == 64'(ws) + 64'd1,
            $sformatf("obs %0d: SETUP@%0d END@%0d inconsistent with %0d waits",
                      i, start_c, end_c, ws));
      if (i == 5)  // the read issued with idle_cycles = 0 after obs 4
        check(start_c == prev_end + 64'd1,
              $sformatf("obs 5: SETUP@%0d, expected directly after completion @%0d",
                        start_c, prev_end));
      prev_end = end_c;
    end

    // Nothing extra may be published afterwards
    repeat (4) @(posedge drv.PCLK);
    check(mon.transfer_count == unsigned'(exp_write.size()),
          $sformatf("monitor saw %0d transfers, expected %0d",
                    mon.transfer_count, exp_write.size()));
    check(mon.get_total_errors() == 0,
          $sformatf("monitor reported %0d protocol errors", mon.get_total_errors()));
    $display("SMOKE_INFO [%s] %0d transfers checked, monitor errors=%0d",
             NAME, exp_write.size(), mon.get_total_errors());
  endtask

  initial begin : run
    apb_features_t f;
    logic [SW-1:0] all;
    logic [DW-1:0] merged;
    int unsigned   fault_arg;

    f   = apb_default_features();
    all = '1;
    if (FAULT_TARGET && $value$plusargs("APB_FAULT=%d", fault_arg))
      fault = apb_fault_e'(fault_arg);

    check($bits(drv.PWDATA) == DATA_WIDTH && $bits(mon.PWDATA) == DATA_WIDTH,
          $sformatf("DATA_WIDTH=%0d does not match the connected BFMs", DATA_WIDTH));
    check(drv.configure(f), "driver configure() rejected APB4 defaults");
    check(mon.configure(f), "monitor configure() rejected APB4 defaults");
    mon.set_publish(1'b1);
    drv.set_fault(fault);
    drv.set_enable(1'b1);
    drv.wait_for_reset_release(1);

    // 0 wait states (PADDR[5:4] = 0) and 2 wait states (PADDR[5:4] = 2)
    xfer(1, 'h00, P1[DW-1:0], all, 1, '0,         APB_ST_OK, 0);
    xfer(0, 'h00, '0,         all, 1, P1[DW-1:0], APB_ST_OK, 0);
    xfer(1, 'h20, P2[DW-1:0], all, 1, '0,         APB_ST_OK, 2);
    xfer(0, 'h20, '0,         all, 1, P2[DW-1:0], APB_ST_OK, 2);
    // back-to-back: no IDLE cycle between the write and the read (APB-R05)
    xfer(1, 'h04, P3[DW-1:0], all, 1, '0,         APB_ST_OK, 0);
    xfer(0, 'h04, '0,         all, 0, P3[DW-1:0], APB_ST_OK, 0);
    // PSTRB: rewrite byte lane 0 only
    merged = {P4[DW-1:8], 8'hFF};
    xfer(1, 'h08, P4[DW-1:0], all,    1, '0,     APB_ST_OK, 0);
    xfer(1, 'h08, '1,         SW'(1), 1, '0,     APB_ST_OK, 0);
    xfer(0, 'h08, '0,         all,    1, merged, APB_ST_OK, 0);
    // PSLVERR: read beyond the example slave's 256-byte memory
    xfer(0, 'h100, '0,        all,    1, '0,     APB_ST_SLVERR, 0);

    if (fault != APB_FAULT_NONE) check_fault_detected();
    else                         check_monitor();
    done = 1'b1;
  end

endmodule : apb_hdl_smoke_runner
