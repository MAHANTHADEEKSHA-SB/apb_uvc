# Evidence — APB-003a (HDL step 2)

> **SUPERSEDED.** These logs describe source revision `5060712` only. That revision contained Verilator-specific workarounds, which the owner rejected on 2026-10-29 ("no tool-specific workarounds"). They were reverted (`REVIEW_FEEDBACK.md` RISK-010), so **none of these results apply to the current sources**, which are NOT RUN. The files are kept as a record of what was observed and of the Verilator 5.020 defects (`verilator_repro/`).

> **Toolchain gate:** the slang 12.1.0 and Verilator 5.020 runs below were executed on 2026-10-29 **before** the toolchain approval gate (ARCHITECTURE_CONTRACT "Toolchain selection and execution gate", `dev` PR #3) reached this branch, and **without explicit owner approval of those tools**. Their outcomes are recorded as observed, but they are **not accepted as gate evidence** until the owner approves the tools and commands (see `WORK_STATUS.md` *Toolchain approval request*) or the checks are re-run on an approved tool. Source edits made for these tools are listed in `REVIEW_FEEDBACK.md` RISK-010.

| Item | Value |
|---|---|
| Source commit | `50607121dfc980ac89bbb768d30e768c9df98e68` (clean tree) |
| Date (UTC) | 2026-10-29T10:01:49Z |
| Command | `poc/apb_uvc/scripts/run_hdl_smoke.sh <out>` |
| Tools | slang 12.1.0+42710c788 (pyslang, PyPI); Verilator 5.020 (Ubuntu 24.04 package `5.020-1`) |
| Overall | **HDL_SMOKE_OVERALL: PASS** (`logs/summary.txt`) |

Machine-local output paths in the logs are replaced by `<out>`.

## Steps

| Step | Result | Log |
|---|---|---|
| slang elaboration, standard (A DW=32, B DW=16) | PASS, 0 errors, 0 diagnostics | `logs/slang_std.log` |
| slang elaboration, + DW=64 extension instance | PASS, 0 errors, 0 diagnostics | `logs/slang_dw64.log` |
| Verilator build, standard | PASS, 71 warnings (triaged below) | `logs/verilator_build_std.log` |
| Positive smoke: 10 transfers per instance | PASS | `logs/sim_positive.log` |
| `+APB_FAULT=1` PADDR changed in a wait state | PASS: `UNSTABLE_IN_ACCESS` ×2 on A, B clean | `logs/sim_fault1_paddr_unstable.log` |
| `+APB_FAULT=2` ACCESS without SETUP | PASS: `ACCESS_WITHOUT_SETUP` on A, B clean | `logs/sim_fault2_skip_setup.log` |
| `+APB_FAULT=3` PSEL dropped while PREADY LOW | PASS: `PSEL_DROPPED_IN_ACCESS` ×2 on A, B clean | `logs/sim_fault3_drop_psel_in_wait.log` |
| Verilator build + run with DW=64 extension | PASS (3 instances) | `logs/verilator_build_dw64.log`, `logs/sim_positive_dw64_extension.log` |

Positive smoke per instance: write/read 0 waits, write/read 2 waits, back-to-back write→read (SETUP at completion cycle + 1), full write + `PSTRB`=0b0001 rewrite + read-back of the merged word, `PSLVERR` read at 0x100. Checked: driver status, wait states and read data; every monitor observation (direction, address, data, strobe, `PSLVERR`, wait states, SETUP/completion cycle consistency); exact publication count 4 cycles after the last transfer; zero monitor errors.

## Additional checks run on the same sources (not in `logs/`)

- **Width guard:** `apb_if` with `DATA_WIDTH`=64 and `ALLOW_NONSTANDARD_DW`=0 → 1 error; 24 → 1 error; 16 → 0; 64 with `ALLOW_NONSTANDARD_DW`=1 → 0 (slang).
- **Mutation check:** with the monitor's `PADDR` stability check deleted, the `+APB_FAULT=1` run reports `SMOKE_RESULT: FAIL` ("injected APB_FAULT_PADDR_UNSTABLE NOT detected"), so the negative test is not vacuous.
- **EDA Playground bundle:** `make_eda_bundle.py filelists/apb_hdl_smoke.f` → one file (8 sources). slang: 0 diagnostics; Verilator: `SMOKE_RESULT: PASS`.

## Verilator warning triage (standard build)

| Warning | Count | Disposition |
|---|---|---|
| UNUSEDSIGNAL | 30 | APB5 pins unused until M2/M3 (monitor 22, driver 4); unused smoke locals (3); example slave (1). Expected |
| UNDRIVEN | 22 | APB5 Completer nets absent on the example slave (7); Verilator lint on `input wire` ports of interface instances (15). Data flow through those ports is proven by the simulation |
| INITIALDLY | 17 | BFM tasks intentionally drive with NBAs and are called from `initial` processes |
| BLKSEQ | 2 | Clock generators in `apb_hdl_top` |

## Not covered by this evidence

- 4-state behaviour and `'z` drive release (Verilator is 2-state; RISK-009)
- Reset at a transfer boundary or mid-transfer (RST-2..RST-4)
- Passive instance with the driver BFM released
- APB2/APB3 configurations (only APB4 defaults are exercised)
- Any commercial simulator

## `verilator_repro/` — minimal Verilator 5.020 cases (RISK-001)

| File | Construct | Verilator 5.020 |
|---|---|---|
| `r1.sv` | parameterized class, one specialization, parameterized virtual-interface typedef | builds, runs |
| `r2.sv` | non-parameterized class with a specialized virtual interface | builds, runs |
| `r3.sv` | parameterized class, **two** specializations (default + other) | **internal fault** |
| `r4.sv` | as r3, neither specialization equals the default | **internal fault** |
| `r6.sv` | non-parameterized abstract base + per-width non-parameterized concrete classes | builds, runs |

Build each with `verilator --binary --timing --top-module <name> <name>.sv`.
