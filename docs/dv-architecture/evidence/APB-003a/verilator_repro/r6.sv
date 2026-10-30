interface bfm_if #(parameter int DW = 32) (input logic clk);
  logic [DW-1:0] d = '0;
  task automatic poke(input logic [DW-1:0] v); @(posedge clk); d <= v; endtask
endinterface
module sub; logic clk = 0; always #5 clk = ~clk; bfm_if #(32) b32(clk); bfm_if #(16) b16(clk); endmodule
module r6;
  sub u();
  virtual class runner_base; pure virtual task run(); endclass
  class runner32 extends runner_base;
    virtual bfm_if #(.DW(32)) v;
    function new(virtual bfm_if #(.DW(32)) v); this.v = v; endfunction
    virtual task run(); v.poke('1); endtask
  endclass
  class runner16 extends runner_base;
    virtual bfm_if #(.DW(16)) v;
    function new(virtual bfm_if #(.DW(16)) v); this.v = v; endfunction
    virtual task run(); v.poke('1); endtask
  endclass
  runner_base r[2];
  initial begin
    runner32 a; runner16 b; a = new(u.b32); b = new(u.b16); r[0] = a; r[1] = b;
    fork r[0].run(); r[1].run(); join
    #20 $display("R6 %h %h", u.b32.d, u.b16.d); $finish;
  end
endmodule
