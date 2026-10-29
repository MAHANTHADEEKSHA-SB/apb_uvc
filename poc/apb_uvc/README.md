# APB UVC (proof of concept)

One reusable APB Requester (master) UVC. Two instances of the same source — **AW=32/DW=32** and **AW=32/DW=16** — run side by side to show width independence. **DW=64** is available only as an opt-in, non-standard extension (ADR-001 Amendment A1).

**Status:** milestone M1, step 2 (HDL) only. The signal interface, the driver and monitor BFMs, an example Completer, the HDL top and an HDL-only smoke test exist and pass (see *Evidence*). HVL proxies, UVM components, sequences and coverage are **not written yet**.

Governing documents: `../../docs/dv-architecture/` — `APB_PROTOCOL_CONTRACT.md` (pins, rules, reset, transaction), `ARCHITECTURE_CONTRACT.md`, ADR-001, ADR-002, `WORK_STATUS.md`.

## Supported protocol

Specification: Arm *AMBA APB Protocol Specification*, ARM IHI 0024D.

| Revision | Status in M1 |
|---|---|
| APB2 | Implemented: no `PREADY`/`PSLVERR`, IHI Table B-1 defaults (1/0) applied |
| APB3 | Implemented: `PREADY` wait states, `PSLVERR` |
| APB4 (default) | Implemented: + `PSTRB`, `PPROT` |
| APB5 | Pins present. `PWAKEUP` and user signals are milestone M2; parity is milestone M3. `configure()` rejects them until then |

Revision and features are **per-instance runtime configuration** (`apb_bfm_pkg::apb_features_t`). An absent feature costs nothing: its Requester outputs are driven to 0, and its Completer inputs are replaced by the spec defaults.

## Layout (files that exist today)

```text
hdl/apb_bfm_pkg.sv          types shared by BFMs and (later) HVL adapters; no UVM
hdl/apb_if.sv               APB5 superset pins + modports; width legality checks
hdl/apb_driver_bfm_if.sv    Requester drive BFM; outputs 'z until set_enable(1)
hdl/apb_monitor_bfm_if.sv   passive monitor BFM; protocol checks; observation queue
examples/apb_example_slave.sv  small APB4 Completer (test fixture only)
examples/apb_hdl_top.sv     instances A (DW=32) and B (DW=16), own clocks/resets
tests/apb_hdl_smoke_runner.sv  directed sequence for one instance
tests/apb_hdl_smoke.sv      smoke top; binds a runner into each instance
filelists/apb_hdl.f         reusable HDL core, compile order
filelists/apb_hdl_smoke.f   core + example + smoke test
scripts/run_hdl_smoke.sh    full evidence run (slang + Verilator)
scripts/slang_elab.py       slang elaboration wrapper
scripts/make_eda_bundle.py  single-file bundle for EDA Playground
```

Filelists use paths relative to the filelist, so pass them with **`-F`**, not `-f`.

## Integrating the HDL

Per APB instance, instantiate one `apb_if`, one `apb_driver_bfm_if` and one `apb_monitor_bfm_if` with the **same parameters**. Connect both BFMs to that `apb_if` instance's nets through their ordinary signal ports (ADR-002 decision 7); `examples/apb_hdl_top.sv` is the template. The width checks in `apb_if` reject `DATA_WIDTH` outside {8, 16, 32} unless `ALLOW_NONSTANDARD_DW=1` (then 64 is accepted).

BFM API used by the (future) HVL adapters:

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

## Running the HDL smoke

```sh
scripts/run_hdl_smoke.sh [output_dir]   # needs python3 + pyslang, verilator >= 5.020
```

It runs slang elaboration (standard and DW=64), a positive Verilator run, three fault-injection runs (`+APB_FAULT=1..3`, each must be detected on instance A while instance B stays clean) and the DW=64 extension run. It exits 0 only if every step passes.

### EDA Playground (commercial simulators)

```sh
python3 -I scripts/make_eda_bundle.py filelists/apb_hdl_smoke.f apb_hdl_smoke_bundle.sv
```

Paste the generated file into the *testbench.sv* pane, leave *design.sv* empty, pick a SystemVerilog simulator, set the top to `apb_hdl_smoke`, and look for `SMOKE_RESULT: PASS`. Add `+APB_FAULT=1` (2, 3) as a run option for the negative tests. For the DW=64 extension, add `+define+APB_ENABLE_DW64_EXTENSION` to the bundle command. A 4-state simulator also exercises the `'z` release and X/Z checks, which Verilator cannot (see below).

## Known tool limitations (Verilator 5.020)

- 2-state, and no `'z` into interface nets. Under `VERILATOR` the driver's released outputs read 0, so **drive release and X/Z checks are not verified by Verilator runs**.
- Faults on two specializations of a parameterized class that each hold a parameterized virtual-interface type, which is the ADR-001 adapter pattern. It also cannot bind a generic interface port to a hierarchical instance. Hence the smoke runner is a module bound into the top.
- It can miss the monitor's same-time-step wake-up, so `get_transfer()` returns one PCLK later than on a compliant simulator. Contents and cycle stamps are unchanged.

Details and repro cases are in `../../docs/dv-architecture/REVIEW_FEEDBACK.md` (RISK-001, RISK-002, RISK-009).
