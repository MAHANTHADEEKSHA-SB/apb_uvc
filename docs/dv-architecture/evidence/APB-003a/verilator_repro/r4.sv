interface bfm_if #(parameter int DW = 32) (input logic clk);
  logic [DW-1:0] d = '0;
  task automatic poke(input logic [DW-1:0] v); @(posedge clk); d <= v; endtask
endinterface
module sub; logic clk = 0; always #5 clk = ~clk; bfm_if #(32) b32(clk); bfm_if #(16) b16(clk); endmodule
module r4;
  sub u();
  class runner #(int DW = 8);
    typedef virtual bfm_if #(.DW(DW)) vif_t;
    vif_t v;
    function new(vif_t v); this.v = v; endfunction
    task run(); v.poke('1); endtask
  endclass
  runner #(32) ra; runner #(16) rb;
  initial begin ra = new(u.b32); rb = new(u.b16); fork ra.run(); rb.run(); join #20 $display("R4 %h %h", u.b32.d, u.b16.d); $finish; end
endmodule
