// -----------------------------------------------------------------------------
// apb_example_slave — small APB4 Completer used only by the POC examples/tests
//
// This is a test fixture, not a reference for the APB specification
// (DIRECTORY_ARCHITECTURE "APB POC behavior"). Behaviour chosen to make
// directed tests easy:
//   * MEM_BYTES of word-organised memory, cleared by PRESETn; PSTRB byte-lane
//     writes (IHI 0024D 3.2); unaligned addresses use the aligned word
//   * wait states = PADDR[5:4] (0..3) so a test selects them by address
//   * PSLVERR for addresses >= MEM_BYTES (IHI 0024D 3.4)
//   * PRDATA/PSLVERR driven LOW outside the completion cycle (IHI 0024D 3.4, A.1)
// An APB3 integration ties PSTRB to {DATA_WIDTH/8{PWRITE}} (IHI 0024D Table 3-1)
// and PPROT to 0.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

module apb_example_slave #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32,
  parameter int MEM_BYTES  = 256
) (
  input  logic                    PCLK,
  input  logic                    PRESETn,
  input  logic                    PSEL,
  input  logic                    PENABLE,
  input  logic                    PWRITE,
  input  logic [ADDR_WIDTH-1:0]   PADDR,
  input  logic [DATA_WIDTH-1:0]   PWDATA,
  input  logic [DATA_WIDTH/8-1:0] PSTRB,
  input  logic [2:0]              PPROT,  // accepted, no protection model
  output logic                    PREADY,
  output logic [DATA_WIDTH-1:0]   PRDATA,
  output logic                    PSLVERR
);

  localparam int NBYTES    = DATA_WIDTH / 8;
  localparam int LANE_BITS = $clog2(NBYTES);
  localparam int MEM_WORDS = MEM_BYTES / NBYTES;
  localparam logic [ADDR_WIDTH-1:0] MEM_LIMIT = MEM_BYTES;

  // Word-addressed memory; PSTRB selects byte lanes within a word
  logic [DATA_WIDTH-1:0] mem [MEM_WORDS];
  logic [1:0]            wait_cnt;

  wire                  access   = PSEL && PENABLE;
  wire [1:0]            wait_req = PADDR[5:4];
  wire                  in_range = (PADDR < MEM_LIMIT);
  wire [ADDR_WIDTH-1:0] word     = PADDR >> LANE_BITS;  // unaligned -> aligned word

  assign PREADY  = access && (wait_cnt == wait_req);
  assign PSLVERR = access && PREADY && !in_range;
  assign PRDATA  = (access && PREADY && !PWRITE && in_range) ? mem[word] : '0;

  // Wait-state counter and memory. Reset clears both (a fixture choice, not an IHI
  // 0024D rule). A write updates only PSTRB-enabled lanes, at the completion edge.
  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      wait_cnt <= '0;
      for (int w = 0; w < MEM_WORDS; w++) mem[w] <= '0;
    end else begin
      wait_cnt <= (access && !PREADY) ? wait_cnt + 2'd1 : 2'd0;
      if (access && PREADY && PWRITE && in_range)
        for (int i = 0; i < NBYTES; i++)
          if (PSTRB[i]) mem[word][8*i +: 8] <= PWDATA[8*i +: 8];
    end
  end

  if (ADDR_WIDTH < 6) begin : g_bad_addr_width
    $error("apb_example_slave: ADDR_WIDTH must be >= 6 (wait states use PADDR[5:4])");
  end
  if (MEM_BYTES % NBYTES != 0) begin : g_bad_mem_bytes
    $error("apb_example_slave: MEM_BYTES must be a multiple of DATA_WIDTH/8");
  end

endmodule : apb_example_slave
