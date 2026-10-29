# APB UVC (proof of concept)

One reusable APB Requester (master) UVC. Two instances of the same source — **AW=32/DW=32** and **AW=32/DW=16** — run side by side to show width independence. **DW=64** is available only as an opt-in, non-standard extension (ADR-001 Amendment A1).

**Status:** milestone M1 sources for HDL, HVL API, adapters, UVM agent, HVL top and tests are written as **portable IEEE 1800-2017 SystemVerilog/UVM with no tool-specific code paths**. **Nothing has been compiled or simulated yet** (toolchain approval pending — see `../../docs/dv-architecture/WORK_STATUS.md`, which also lists the known gaps).

Governing documents: `../../docs/dv-architecture/` — `APB_PROTOCOL_CONTRACT.md` (pins, rules, reset, transaction), `ARCHITECTURE_CONTRACT.md`, ADR-001, ADR-002, `WORK_STATUS.md`.

## Supported protocol

Specification: Arm *AMBA APB Protocol Specification*, ARM IHI 0024D.

| Revision | Status in M1 |
|---|---|
| APB2 | Implemented: no `PREADY`/`PSLVERR`, IHI Table B-1 defaults (1/0) applied |
| APB3 | Implemented: `PREADY` wait states, `PSLVERR` |
| APB4 (default) | Implemented: + `PSTRB`, `PPROT` |
| APB5 | Pins present. `PWAKEUP` and user signals are milestone M2; parity is milestone M3. `configure()` and `apb_agent_cfg` reject them until then |

Revision and features are **per-instance runtime configuration** (`apb_agent_cfg.features`, type `apb_bfm_pkg::apb_features_t`). An absent feature costs nothing: its Requester outputs are driven to 0, and its Completer inputs are replaced by the spec defaults.

## Layout

```text
hdl/apb_bfm_pkg.sv              types shared by BFMs and HVL adapters; no UVM
hdl/apb_if.sv                   APB5 superset pins + modports; width legality checks
hdl/apb_driver_bfm_if.sv        Requester drive BFM; outputs 'z until set_enable(1)
hdl/apb_monitor_bfm_if.sv       passive monitor BFM; protocol checks; observation queue
hvl/types/apb_defines.svh       transaction maxima (AW 32, DW 32 or 64 with the extension)
hvl/types/apb_transaction.sv    one transaction class for every width (4-state)
hvl/api/apb_*_proxy_base.sv     abstract drive / observe capabilities
hvl/adapter/apb_*_proxy.sv      width-specialized adapters with typed virtual BFM handles
hvl/config/apb_agent_cfg.sv     per-instance configuration + legality checks
hvl/agent/                      apb_sequencer, apb_driver, apb_monitor, apb_agent
hvl/coverage/apb_coverage.sv    protocol coverage
hvl/sequences/                  apb_base_seq (helpers), apb_random_seq
hvl/pkg/                        apb_api_pkg, apb_uvc_pkg, apb_adapter_pkg
examples/apb_example_slave.sv   small APB4 Completer (test fixture only)
examples/apb_hdl_top.sv         instances A (DW=32) and B (DW=16), own clocks/resets
examples/apb_hvl_top.sv         binds adapters, registers one cfg per instance, run_test
tests/apb_hdl_smoke.sv          HDL-only smoke (no UVM)
tests/apb_poc_test_pkg.sv       UVM POC env, fixture scoreboard and tests
filelists/apb_hdl.f             reusable HDL core
filelists/apb_hvl.f             reusable HVL core
filelists/apb_hdl_smoke.f       HDL core + example + HDL smoke
filelists/apb_poc.f             everything for the UVM POC
scripts/slang_elab.py           slang elaboration wrapper (proposed check, needs approval)
scripts/make_eda_bundle.py      single-file bundle for EDA Playground (plain text, no tool)
```

Filelists use paths relative to the filelist, so pass them with **`-F`**, not `-f`. Compile order is HDL core, then the simulator's `uvm_pkg`, then `apb_api_pkg`, `apb_uvc_pkg`, `apb_adapter_pkg`.

**Reusable core** = `hdl/` + `hvl/` (`apb_hdl.f` + `apb_hvl.f`). `examples/` and `tests/` show integration and are not needed by a consumer.

## Integrating the UVC

**HDL, per instance:** one `apb_if`, one `apb_driver_bfm_if` and one `apb_monitor_bfm_if` with the **same parameters**. Connect both BFMs to that `apb_if` instance's nets through their ordinary signal ports (ADR-002 decision 7); `examples/apb_hdl_top.sv` is the template. `apb_if` rejects `DATA_WIDTH` outside {8, 16, 32} unless `ALLOW_NONSTANDARD_DW=1` (then 64 is accepted).

**HVL, per instance** (`examples/apb_hvl_top.sv` is the template):

```systemverilog
apb_drive_proxy   #(.ADDR_WIDTH(32), .DATA_WIDTH(16)) drv;
apb_monitor_proxy #(.ADDR_WIDTH(32), .DATA_WIDTH(16)) mon;
apb_agent_cfg                                         cfg;

drv = new("drive_b",   apb_hdl_top.drv_b);   // typed handle to THIS instance's BFMs
mon = new("observe_b", apb_hdl_top.mon_b);
cfg = apb_agent_cfg::type_id::create("cfg_b");
cfg.drive   = drv;            // omit for a passive agent (cfg.is_active = UVM_PASSIVE)
cfg.observe = mon;
// cfg.features.revision = APB3; cfg.features.has_pstrb = 0; ...   (default: APB4)
uvm_config_db#(apb_agent_cfg)::set(null, "uvm_test_top.env.agent_b", "cfg", cfg);
```

The agent, driver, monitor, sequencer and sequences are **not** width-parameterized; the same classes serve every instance. Sequences derived from `apb_base_seq` get the bus context automatically (`new_item()`), so random values always fit the instance. The drive adapter rejects anything that would not fit (no silent truncation).

### BFM API (used by the adapters)

| BFM | Call | Purpose |
|---|---|---|
| driver | `configure(apb_features_t)` → bit | set revision/features; 0 = rejected |
| driver | `set_enable(bit)` | 0 releases every output to `'z` (passive instance) |
| driver | `wait_for_reset_release(idle_cycles)` | RST-5 |
| driver | `do_transfer(...)` | one SETUP+ACCESS transfer; returns data, `PSLVERR`, wait states, `apb_bfm_status_e` |
| driver | `set_fault(apb_fault_e)` | deliberate protocol faults for negative tests |
| monitor | `configure(apb_features_t)` → bit | same feature set as the driver |
| monitor | `set_publish(bit)` | enable the observation queue |
| monitor | `get_transfer(...)` | blocking; next completed transfer |
| monitor | `get_error_count(code)` / `get_total_errors()` | protocol violations by `apb_mon_error_e` |

## Running

Inside this repository's AI workflow, no simulator or compiler may be run without explicit owner approval of the tool, version and commands (ARCHITECTURE_CONTRACT toolchain gate).

| Flow | Filelist | Top(s) | Options | Pass line |
|---|---|---|---|---|
| HDL smoke | `apb_hdl_smoke.f` | `apb_hdl_smoke` | `+APB_FAULT=1\|2\|3` for negatives | `SMOKE_RESULT: PASS` |
| UVM POC | `apb_poc.f` + UVM library | `apb_hdl_top apb_hvl_top` | `+UVM_TESTNAME=apb_poc_test` | `TEST_RESULT: PASS (0 errors)` |
| UVM fault injection | same | same | `+UVM_TESTNAME=apb_fault_injection_test +APB_FAULT=1\|2\|3` | `TEST_RESULT: PASS` |
| UVM cfg legality | same | same | `+UVM_TESTNAME=apb_cfg_negative_test` | `TEST_RESULT: PASS` |
| UVM width boundary | same | same | `+UVM_TESTNAME=apb_width_negative_test` | `TEST_RESULT: PASS` |

Add `+define+APB_ENABLE_DW64_EXTENSION` at compile time to include the DW=64 instance (and agent) in any flow.

Language features the sources rely on: 4-state nets with `'z` release on interface nets, clocking blocks with `#1step` input skew, `fork…join_any` with `disable fork` in interface tasks, named events, queues, parameterized classes holding parameterized virtual-interface types, embedded covergroups, and UVM 1.2 or IEEE 1800.2.

### EDA Playground (commercial simulators)

```sh
python3 -I scripts/make_eda_bundle.py filelists/apb_hdl_smoke.f apb_hdl_smoke_bundle.sv   # HDL smoke
python3 -I scripts/make_eda_bundle.py filelists/apb_poc.f       apb_poc_bundle.sv         # UVM POC
```

The bundle inlines every project `include`, so no include path is needed; `uvm_macros.svh` comes from the simulator's UVM library. Paste the file into the *testbench.sv* pane, leave *design.sv* empty, pick a SystemVerilog simulator (for the UVM bundle also select a UVM library), set the top(s) from the table above and add the run options. For the DW=64 extension, add `+define+APB_ENABLE_DW64_EXTENSION` to the bundle command.

## Portability policy

The sources contain **no tool-specific code paths, pragmas or workarounds** (owner decision 2026-10-29). A simulator that cannot handle the standard constructs above is recorded as a tool limitation in `../../docs/dv-architecture/REVIEW_FEEDBACK.md`; the code is not bent to fit it. Known example: Verilator 5.020 (RISK-001, RISK-009).
