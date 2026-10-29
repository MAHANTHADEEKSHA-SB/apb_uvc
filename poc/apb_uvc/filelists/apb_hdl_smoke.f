// HDL-only smoke: reusable core + example Completer/top + smoke test.
// Use with -F: paths are relative to this file's directory.
-F apb_hdl.f
../examples/apb_example_slave.sv
../examples/apb_hdl_top.sv
../tests/apb_hdl_smoke_runner.sv
../tests/apb_hdl_smoke.sv
