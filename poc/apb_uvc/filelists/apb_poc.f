// Full UVM POC: reusable HDL + HVL core, example HDL, tests, HVL top.
// Tops: apb_hdl_top apb_hvl_top. UVM library supplied by the simulator.
// Use with -F: paths are relative to this file's directory.
-F apb_hdl.f
-F apb_hvl.f
../examples/apb_example_slave.sv
../examples/apb_hdl_top.sv
+incdir+../tests
../tests/apb_poc_test_pkg.sv
../examples/apb_hvl_top.sv
