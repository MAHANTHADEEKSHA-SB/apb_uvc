interface bfm_if #(parameter int DW = 32) (input logic clk);
  logic [DW-1:0] d = '0;
  task automatic poke(input logic [DW-1:0] v); @(posedge clk); d <= v; endtask
endinterface
module r1;
  logic clk = 0; always #5 clk = ~clk;
  bfm_if #(16) b16(clk);
  class runner #(int DW = 32);
    typedef virtual bfm_if #(.DW(DW)) vif_t;
    vif_t v;
    function new(vif_t v); this.v = v; endfunction
    task run(); v.poke('1); endtask
  endclass
  runner #(16) r;
  initial begin r = new(b16); r.run(); #20 $display("R1 d=%h", b16.d); $finish; end
endmodule
