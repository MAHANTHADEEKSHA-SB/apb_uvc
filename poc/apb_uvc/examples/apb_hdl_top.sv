// -----------------------------------------------------------------------------
// apb_hdl_top — HDL integration example: two instances of the same APB UVC
//
//   Instance A: AW=32, DW=32  (APB4, own clock/reset)
//   Instance B: AW=32, DW=16  (APB4, own clock/reset)          ADR-001 A1
//   Instance C: AW=32, DW=64  non-standard extension, only with
//               +define+APB_ENABLE_DW64_EXTENSION               ADR-001 A1
//
// Per instance, both BFM interfaces connect to the SAME apb_if instance
// through ordinary signal ports (ADR-002 decision 7). Each instance has its
// own clock and reset so any cross-instance wiring shows up as wrong timing.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

module apb_hdl_top;

  // ---------------------------------------------------------------------------
  // Clocks and resets
  // ---------------------------------------------------------------------------
  logic pclk_a = 1'b0, presetn_a = 1'b0;
  logic pclk_b = 1'b0, presetn_b = 1'b0;
  always #5 pclk_a = ~pclk_a;  // 10 ns period
  always #7 pclk_b = ~pclk_b;  // 14 ns period

  // Initial reset: 5 cycles, released on a falling edge to avoid racing the
  // rising-edge samplers.
  initial begin
    repeat (5) @(negedge pclk_a);
    presetn_a = 1'b1;
  end
  initial begin
    repeat (5) @(negedge pclk_b);
    presetn_b = 1'b1;
  end

  // Mid-simulation reset for tests (RST-1..RST-4): assert now, release on a
  // falling edge after `cycles` rising edges.
  task automatic pulse_reset_a(input int unsigned cycles);
    presetn_a = 1'b0;
    repeat (cycles) @(posedge pclk_a);
    @(negedge pclk_a) presetn_a = 1'b1;
  endtask

  task automatic pulse_reset_b(input int unsigned cycles);
    presetn_b = 1'b0;
    repeat (cycles) @(posedge pclk_b);
    @(negedge pclk_b) presetn_b = 1'b1;
  endtask

  // ---------------------------------------------------------------------------
  // Instance A — AW=32, DW=32
  // ---------------------------------------------------------------------------
  apb_if #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) bus_a (
    .PCLK       (pclk_a),
    .PRESETn    (presetn_a)
  );

  apb_driver_bfm_if #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) drv_a (
    .PCLK       (bus_a.PCLK),
    .PRESETn    (bus_a.PRESETn),
    .PADDR      (bus_a.PADDR),
    .PPROT      (bus_a.PPROT),
    .PSEL       (bus_a.PSEL),
    .PENABLE    (bus_a.PENABLE),
    .PWRITE     (bus_a.PWRITE),
    .PWDATA     (bus_a.PWDATA),
    .PSTRB      (bus_a.PSTRB),
    .PWAKEUP    (bus_a.PWAKEUP),
    .PAUSER     (bus_a.PAUSER),
    .PWUSER     (bus_a.PWUSER),
    .PADDRCHK   (bus_a.PADDRCHK),
    .PCTRLCHK   (bus_a.PCTRLCHK),
    .PSELCHK    (bus_a.PSELCHK),
    .PENABLECHK (bus_a.PENABLECHK),
    .PWDATACHK  (bus_a.PWDATACHK),
    .PSTRBCHK   (bus_a.PSTRBCHK),
    .PWAKEUPCHK (bus_a.PWAKEUPCHK),
    .PAUSERCHK  (bus_a.PAUSERCHK),
    .PWUSERCHK  (bus_a.PWUSERCHK),
    .PREADY     (bus_a.PREADY),
    .PRDATA     (bus_a.PRDATA),
    .PSLVERR    (bus_a.PSLVERR),
    .PRUSER     (bus_a.PRUSER),
    .PBUSER     (bus_a.PBUSER)
  );

  apb_monitor_bfm_if #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) mon_a (
    .PCLK       (bus_a.PCLK),
    .PRESETn    (bus_a.PRESETn),
    .PADDR      (bus_a.PADDR),
    .PPROT      (bus_a.PPROT),
    .PSEL       (bus_a.PSEL),
    .PENABLE    (bus_a.PENABLE),
    .PWRITE     (bus_a.PWRITE),
    .PWDATA     (bus_a.PWDATA),
    .PSTRB      (bus_a.PSTRB),
    .PWAKEUP    (bus_a.PWAKEUP),
    .PAUSER     (bus_a.PAUSER),
    .PWUSER     (bus_a.PWUSER),
    .PADDRCHK   (bus_a.PADDRCHK),
    .PCTRLCHK   (bus_a.PCTRLCHK),
    .PSELCHK    (bus_a.PSELCHK),
    .PENABLECHK (bus_a.PENABLECHK),
    .PWDATACHK  (bus_a.PWDATACHK),
    .PSTRBCHK   (bus_a.PSTRBCHK),
    .PWAKEUPCHK (bus_a.PWAKEUPCHK),
    .PAUSERCHK  (bus_a.PAUSERCHK),
    .PWUSERCHK  (bus_a.PWUSERCHK),
    .PREADY     (bus_a.PREADY),
    .PRDATA     (bus_a.PRDATA),
    .PSLVERR    (bus_a.PSLVERR),
    .PRUSER     (bus_a.PRUSER),
    .PBUSER     (bus_a.PBUSER),
    .PREADYCHK  (bus_a.PREADYCHK),
    .PRDATACHK  (bus_a.PRDATACHK),
    .PSLVERRCHK (bus_a.PSLVERRCHK),
    .PRUSERCHK  (bus_a.PRUSERCHK),
    .PBUSERCHK  (bus_a.PBUSERCHK)
  );

  apb_example_slave #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) slv_a (
    .PCLK       (bus_a.PCLK),
    .PRESETn    (bus_a.PRESETn),
    .PSEL       (bus_a.PSEL[0]),
    .PENABLE    (bus_a.PENABLE),
    .PWRITE     (bus_a.PWRITE),
    .PADDR      (bus_a.PADDR),
    .PWDATA     (bus_a.PWDATA),
    .PSTRB      (bus_a.PSTRB),
    .PPROT      (bus_a.PPROT),
    .PREADY     (bus_a.PREADY),
    .PRDATA     (bus_a.PRDATA),
    .PSLVERR    (bus_a.PSLVERR)
  );

  // ---------------------------------------------------------------------------
  // Instance B — AW=32, DW=16
  // ---------------------------------------------------------------------------
  apb_if #(.ADDR_WIDTH(32), .DATA_WIDTH(16)) bus_b (
    .PCLK       (pclk_b),
    .PRESETn    (presetn_b)
  );

  apb_driver_bfm_if #(.ADDR_WIDTH(32), .DATA_WIDTH(16)) drv_b (
    .PCLK       (bus_b.PCLK),
    .PRESETn    (bus_b.PRESETn),
    .PADDR      (bus_b.PADDR),
    .PPROT      (bus_b.PPROT),
    .PSEL       (bus_b.PSEL),
    .PENABLE    (bus_b.PENABLE),
    .PWRITE     (bus_b.PWRITE),
    .PWDATA     (bus_b.PWDATA),
    .PSTRB      (bus_b.PSTRB),
    .PWAKEUP    (bus_b.PWAKEUP),
    .PAUSER     (bus_b.PAUSER),
    .PWUSER     (bus_b.PWUSER),
    .PADDRCHK   (bus_b.PADDRCHK),
    .PCTRLCHK   (bus_b.PCTRLCHK),
    .PSELCHK    (bus_b.PSELCHK),
    .PENABLECHK (bus_b.PENABLECHK),
    .PWDATACHK  (bus_b.PWDATACHK),
    .PSTRBCHK   (bus_b.PSTRBCHK),
    .PWAKEUPCHK (bus_b.PWAKEUPCHK),
    .PAUSERCHK  (bus_b.PAUSERCHK),
    .PWUSERCHK  (bus_b.PWUSERCHK),
    .PREADY     (bus_b.PREADY),
    .PRDATA     (bus_b.PRDATA),
    .PSLVERR    (bus_b.PSLVERR),
    .PRUSER     (bus_b.PRUSER),
    .PBUSER     (bus_b.PBUSER)
  );

  apb_monitor_bfm_if #(.ADDR_WIDTH(32), .DATA_WIDTH(16)) mon_b (
    .PCLK       (bus_b.PCLK),
    .PRESETn    (bus_b.PRESETn),
    .PADDR      (bus_b.PADDR),
    .PPROT      (bus_b.PPROT),
    .PSEL       (bus_b.PSEL),
    .PENABLE    (bus_b.PENABLE),
    .PWRITE     (bus_b.PWRITE),
    .PWDATA     (bus_b.PWDATA),
    .PSTRB      (bus_b.PSTRB),
    .PWAKEUP    (bus_b.PWAKEUP),
    .PAUSER     (bus_b.PAUSER),
    .PWUSER     (bus_b.PWUSER),
    .PADDRCHK   (bus_b.PADDRCHK),
    .PCTRLCHK   (bus_b.PCTRLCHK),
    .PSELCHK    (bus_b.PSELCHK),
    .PENABLECHK (bus_b.PENABLECHK),
    .PWDATACHK  (bus_b.PWDATACHK),
    .PSTRBCHK   (bus_b.PSTRBCHK),
    .PWAKEUPCHK (bus_b.PWAKEUPCHK),
    .PAUSERCHK  (bus_b.PAUSERCHK),
    .PWUSERCHK  (bus_b.PWUSERCHK),
    .PREADY     (bus_b.PREADY),
    .PRDATA     (bus_b.PRDATA),
    .PSLVERR    (bus_b.PSLVERR),
    .PRUSER     (bus_b.PRUSER),
    .PBUSER     (bus_b.PBUSER),
    .PREADYCHK  (bus_b.PREADYCHK),
    .PRDATACHK  (bus_b.PRDATACHK),
    .PSLVERRCHK (bus_b.PSLVERRCHK),
    .PRUSERCHK  (bus_b.PRUSERCHK),
    .PBUSERCHK  (bus_b.PBUSERCHK)
  );

  apb_example_slave #(.ADDR_WIDTH(32), .DATA_WIDTH(16)) slv_b (
    .PCLK       (bus_b.PCLK),
    .PRESETn    (bus_b.PRESETn),
    .PSEL       (bus_b.PSEL[0]),
    .PENABLE    (bus_b.PENABLE),
    .PWRITE     (bus_b.PWRITE),
    .PADDR      (bus_b.PADDR),
    .PWDATA     (bus_b.PWDATA),
    .PSTRB      (bus_b.PSTRB),
    .PPROT      (bus_b.PPROT),
    .PREADY     (bus_b.PREADY),
    .PRDATA     (bus_b.PRDATA),
    .PSLVERR    (bus_b.PSLVERR)
  );

`ifdef APB_ENABLE_DW64_EXTENSION
  // ---------------------------------------------------------------------------
  // Instance C — AW=32, DW=64: NON-STANDARD extension (not IHI 0024D compliant)
  // ---------------------------------------------------------------------------
  logic pclk_c = 1'b0, presetn_c = 1'b0;
  always #4 pclk_c = ~pclk_c;  // 8 ns period
  initial begin
    repeat (5) @(negedge pclk_c);
    presetn_c = 1'b1;
  end

  apb_if #(.ADDR_WIDTH(32), .DATA_WIDTH(64), .ALLOW_NONSTANDARD_DW(1'b1)) bus_c (
    .PCLK       (pclk_c),
    .PRESETn    (presetn_c)
  );

  apb_driver_bfm_if #(.ADDR_WIDTH(32), .DATA_WIDTH(64)) drv_c (
    .PCLK       (bus_c.PCLK),
    .PRESETn    (bus_c.PRESETn),
    .PADDR      (bus_c.PADDR),
    .PPROT      (bus_c.PPROT),
    .PSEL       (bus_c.PSEL),
    .PENABLE    (bus_c.PENABLE),
    .PWRITE     (bus_c.PWRITE),
    .PWDATA     (bus_c.PWDATA),
    .PSTRB      (bus_c.PSTRB),
    .PWAKEUP    (bus_c.PWAKEUP),
    .PAUSER     (bus_c.PAUSER),
    .PWUSER     (bus_c.PWUSER),
    .PADDRCHK   (bus_c.PADDRCHK),
    .PCTRLCHK   (bus_c.PCTRLCHK),
    .PSELCHK    (bus_c.PSELCHK),
    .PENABLECHK (bus_c.PENABLECHK),
    .PWDATACHK  (bus_c.PWDATACHK),
    .PSTRBCHK   (bus_c.PSTRBCHK),
    .PWAKEUPCHK (bus_c.PWAKEUPCHK),
    .PAUSERCHK  (bus_c.PAUSERCHK),
    .PWUSERCHK  (bus_c.PWUSERCHK),
    .PREADY     (bus_c.PREADY),
    .PRDATA     (bus_c.PRDATA),
    .PSLVERR    (bus_c.PSLVERR),
    .PRUSER     (bus_c.PRUSER),
    .PBUSER     (bus_c.PBUSER)
  );

  apb_monitor_bfm_if #(.ADDR_WIDTH(32), .DATA_WIDTH(64)) mon_c (
    .PCLK       (bus_c.PCLK),
    .PRESETn    (bus_c.PRESETn),
    .PADDR      (bus_c.PADDR),
    .PPROT      (bus_c.PPROT),
    .PSEL       (bus_c.PSEL),
    .PENABLE    (bus_c.PENABLE),
    .PWRITE     (bus_c.PWRITE),
    .PWDATA     (bus_c.PWDATA),
    .PSTRB      (bus_c.PSTRB),
    .PWAKEUP    (bus_c.PWAKEUP),
    .PAUSER     (bus_c.PAUSER),
    .PWUSER     (bus_c.PWUSER),
    .PADDRCHK   (bus_c.PADDRCHK),
    .PCTRLCHK   (bus_c.PCTRLCHK),
    .PSELCHK    (bus_c.PSELCHK),
    .PENABLECHK (bus_c.PENABLECHK),
    .PWDATACHK  (bus_c.PWDATACHK),
    .PSTRBCHK   (bus_c.PSTRBCHK),
    .PWAKEUPCHK (bus_c.PWAKEUPCHK),
    .PAUSERCHK  (bus_c.PAUSERCHK),
    .PWUSERCHK  (bus_c.PWUSERCHK),
    .PREADY     (bus_c.PREADY),
    .PRDATA     (bus_c.PRDATA),
    .PSLVERR    (bus_c.PSLVERR),
    .PRUSER     (bus_c.PRUSER),
    .PBUSER     (bus_c.PBUSER),
    .PREADYCHK  (bus_c.PREADYCHK),
    .PRDATACHK  (bus_c.PRDATACHK),
    .PSLVERRCHK (bus_c.PSLVERRCHK),
    .PRUSERCHK  (bus_c.PRUSERCHK),
    .PBUSERCHK  (bus_c.PBUSERCHK)
  );

  apb_example_slave #(.ADDR_WIDTH(32), .DATA_WIDTH(64)) slv_c (
    .PCLK       (bus_c.PCLK),
    .PRESETn    (bus_c.PRESETn),
    .PSEL       (bus_c.PSEL[0]),
    .PENABLE    (bus_c.PENABLE),
    .PWRITE     (bus_c.PWRITE),
    .PADDR      (bus_c.PADDR),
    .PWDATA     (bus_c.PWDATA),
    .PSTRB      (bus_c.PSTRB),
    .PPROT      (bus_c.PPROT),
    .PREADY     (bus_c.PREADY),
    .PRDATA     (bus_c.PRDATA),
    .PSLVERR    (bus_c.PSLVERR)
  );
`endif

endmodule : apb_hdl_top
