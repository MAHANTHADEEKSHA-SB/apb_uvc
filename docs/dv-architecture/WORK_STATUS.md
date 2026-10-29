# WORK_STATUS — single APB UVC handoff checkpoint

**Checkpoint date:** 2026-10-29
**Repository:** https://github.com/MAHANTHADEEKSHA-SB/apb_uvc
**Branch:** `feature/apb-001-protocol-contract` (from `dev` at `3f5c50b515c7aa67e110e2011801217b35ea6588`; `dev` merged back in at `91c369f` for the toolchain gate; `dev` was initially created from `main` at `aa3f1af8bc4c6a0c03f74aaad094ca382fc7ee85`)
**Current commit SHA:** read actual `git rev-parse HEAD`; this file cannot self-reference its own commit. Latest source commit described here: `5b217c97cf89bc551914f1f43ff89842f85f620a`.
**Working tree:** UNKNOWN for local clones; verify before changing code.
**Phase:** M1 sources for steps 2–6 **written** (HDL, HVL API, adapters, UVM agent, HVL top, tests) as portable IEEE 1800-2017 SystemVerilog/UVM. Approved slang (T1) + UVM 1.2 (T3): **HDL elaborates clean; the full UVM POC elaborates with 0 errors/0 warnings in project code**, but the run fails on one error inside the UVM library (`MissingTimeScale`), pending owner decision T5. Nothing simulated.
**Tool results:** at `386e64d` (`evidence/APB-004/`): HDL smoke std/DW=64 errors=0 warnings=0; UVM POC std/DW=64 errors=1 warnings=2, **all inside UVM 1.2** (1 × `MissingTimeScale` in `uvm_pkg.sv`, 2 × `-Wempty-body`). Earlier `evidence/APB-003b/` (HDL, `3dfd30a`) also clean. Unapproved runs at `5060712` superseded (RISK-010).
**Next implementer:** Claude or another authorized model/engineer.
**Active task:** owner decision **T5** (add `--timescale 1ns/1ps` to the T1 UVM command), then re-run the UVM elaboration; after that, write the missing passive/reset/APB3 tests.
**Spec reference:** Arm AMBA APB Protocol Specification, ARM IHI 0024D (ID041221, 09 April 2021; adds APB5). The PDF itself is Arm copyright and is not committed here.

> Do not trust this status without comparing it to the real files, current Git SHA, and logs. Any difference must be reconciled explicitly.

## Resume here (new session, other model or engineer)

1. `git fetch origin && git switch feature/apb-001-protocol-contract && git status --short && git log --oneline -12`. Compare HEAD with the SHAs in this file.
2. Read in order: `AGENTS.md` (root) → `docs/dv-architecture/AGENTS.md` → `ARCHITECTURE_CONTRACT.md` (v0.10) → ADR-001 (with Amendment A1) → ADR-002 → `APB_PROTOCOL_CONTRACT.md` → this file → `REVIEW_FEEDBACK.md` → `poc/apb_uvc/README.md`.
3. **Owner rules in force:**
   - **No tool execution** (simulator, compiler, elaborator, lint) without explicit owner approval of tool, version, commands **and options**. Approved so far (2026-10-29): **T1** slang 12.1.0 with exactly the commands in the approval table; **T3** UVM 1.2 from the owner-named mirror `github.com/gchinna/uvm-1.2`. Nothing else (T5 pending).
   - **No tool-specific workarounds:** no `` `ifdef <TOOL> ``, tool pragmas or tool-motivated rewrites. Log tool shortfalls in `REVIEW_FEEDBACK.md` instead.
   - Width pair **DW=32 + DW=16**; DW=64 only behind `APB_ENABLE_DW64_EXTENSION` / `ALLOW_NONSTANDARD_DW` / `allow_nonstandard_width`, never reported as compliant.
   - Revisions APB2–APB5 are per-instance configuration; default APB4 with `PSTRB` and `PPROT`.
   - Do not touch the root-level legacy `apb_*.sv` files. No force-push, no merge into `dev`/`main`.
   - Mark every unexecuted stage **NOT RUN**.
4. **What exists:** see *Source manifest*. **What is missing:** see *Known gaps*.
5. **Next exact step:** see the handoff block at the end.

## Approved scope

Deliver **one reusable APB UVC** rooted at `poc/apb_uvc/`, including its **own** signal interface, driver BFM, monitor BFM, APB-specific abstract/proxy classes, UVM agent, sequences, coverage, filelists, integration example and tests. Two simultaneous 32/16-bit instances demonstrate parameter independence (ADR-001 Amendment A1; DW=64 only as an opt-in non-standard extension). The existing root-level flat APB UVC is preserved. No other protocol UVC or multi-UVC TB is part of this POC.

## Decision/progress inventory

| ID | Work | Status | Evidence or caveat |
|---|---|---|---|
| DOC-001 | ADR-001: HVL concrete proxies | ACCEPTED_FOR_POC, amended A1 | `ADR-001-HVL-PROXY-PLACEMENT.md`; not compiler validated |
| DOC-002 | ADR-002: distinct drive/observe APIs; 2 BFMs / 1 APB signal interface | ACCEPTED_LOGIC | `ADR-002-SEPARATE-DRIVE-OBSERVE-APIS.md`; wiring not yet compiled |
| DOC-003 | Single-APB-UVC directory/contract/prompt | DOCUMENTED | `DIRECTORY_ARCHITECTURE.md`, `ARCHITECTURE_CONTRACT.md` v0.10, `CLAUDE_GENERATION_PROMPT.md` |
| DOC-004 | APB-001 protocol contract | PROPOSED | `APB_PROTOCOL_CONTRACT.md`; Q1/Q3 decided; Q2/Q4/Q5 on proposed defaults |
| IMP-001 | APB interface and BFMs | WRITTEN_M1 (APB2/3/4), ELABORATED (slang), NOT SIMULATED | `poc/apb_uvc/hdl/*`; `evidence/APB-003b/`; 4-state/release unverified (RISK-009); APB5 features M2/M3 |
| IMP-002 | Proxy bases and concrete adapters | WRITTEN, ELABORATED (slang, project code clean), NOT SIMULATED | `hvl/api/*`, `hvl/adapter/*`; two specializations per adapter elaborate (`evidence/APB-004/`) |
| IMP-003 | Non-parameterized UVM APB components | WRITTEN, ELABORATED (slang, project code clean), NOT SIMULATED | `hvl/config`, `hvl/agent`, `hvl/coverage`, `hvl/sequences`, `hvl/pkg/apb_uvc_pkg.sv` |
| IMP-004 | 32/16 dual-instance UVM test | WRITTEN, ELABORATED (slang), NOT SIMULATED | `examples/apb_hvl_top.sv`, `tests/apb_poc_test.sv` |
| IMP-005 | Negative tests | WRITTEN, NOT RUN | fault injection (3 modes), cfg legality, unfit-width; independent reviews NOT_STARTED |

## Source manifest

All paths under `poc/apb_uvc/`. Every SV file elaborates with **0 errors and 0 warnings in project code** on approved slang at `386e64d` (`evidence/APB-004/`); the UVM run as a whole still fails on the UVM-library timescale error (T5). Nothing is simulated.

| Path | Content | Status |
|---|---|---|
| `hdl/apb_bfm_pkg.sv` | Types shared by BFMs and adapters (revision, features, status, fault, monitor-error enums); no UVM | WRITTEN |
| `hdl/apb_if.sv` | APB5 superset pins, modports, width legality checks | WRITTEN |
| `hdl/apb_driver_bfm_if.sv` | Requester drive BFM: SETUP/ACCESS, wait states, back-to-back, `'z` release, reset abort (`fork…join_any`), 3 fault modes | WRITTEN_M1 |
| `hdl/apb_monitor_bfm_if.sv` | Passive BFM: clocking-block sampling, protocol checks, bounded queue, `get_transfer()` with named event | WRITTEN_M1 |
| `hvl/types/apb_defines.svh` | `APB_MAX_ADDR_WIDTH` 32, `APB_MAX_DATA_WIDTH` 32 (64 with the extension switch) | WRITTEN |
| `hvl/types/apb_transaction.sv` | `apb_dir_e`, `apb_transaction` (4-state, bus-context constraints, copy/compare/print) | WRITTEN |
| `hvl/api/apb_drive_proxy_base.sv` | Abstract drive capability (+ POL-01/02 and X-wdata policies) | WRITTEN |
| `hvl/api/apb_monitor_proxy_base.sv` | Abstract observe capability (+ error and activity counters) | WRITTEN |
| `hvl/adapter/apb_drive_proxy.sv` | `apb_drive_proxy #(AW,DW,NUM_SEL,user widths)`: typed vif, lossless/legality request checks | WRITTEN |
| `hvl/adapter/apb_monitor_proxy.sv` | `apb_monitor_proxy #(…,QUEUE_DEPTH)`: typed vif, builds a new transaction per transfer | WRITTEN |
| `hvl/config/apb_agent_cfg.sv` | Per-instance cfg; `legality_error()` / `validate()` (CFG-01..06, M1 limits) | WRITTEN |
| `hvl/agent/apb_sequencer.sv`, `apb_driver.sv`, `apb_monitor.sv`, `apb_agent.sv` | Non-parameterized UVM components | WRITTEN |
| `hvl/coverage/apb_coverage.sv` | Protocol coverage (dir, waits, PSLVERR, strobe kind, b2b, PPROT, crosses) | WRITTEN |
| `hvl/sequences/apb_base_seq.sv`, `apb_random_seq.sv` | Helpers `do_write/do_write_strb/do_read`; random window sequence | WRITTEN |
| `hvl/pkg/apb_api_pkg.sv`, `apb_uvc_pkg.sv`, `apb_adapter_pkg.sv` | Packages (compile in this order after HDL + uvm_pkg) | WRITTEN |
| `examples/apb_example_slave.sv` | APB4 Completer fixture (wait states = PADDR[5:4], PSLVERR ≥ 0x100) | WRITTEN |
| `examples/apb_hdl_top.sv` | Instances A (DW=32) + B (DW=16), own clocks/resets; C (DW=64) under the extension switch | WRITTEN |
| `examples/apb_hvl_top.sv` | Explicit adapter construction, one cfg per instance, single `uvm_config_db::set`, `run_test` | WRITTEN |
| `tests/apb_hdl_smoke.sv` | HDL-only directed + fault smoke (no UVM) | WRITTEN |
| `tests/apb_poc_test_pkg.sv` + `apb_poc_scoreboard.sv`, `apb_poc_env.sv`, `apb_poc_seqs.sv`, `apb_fake_proxies.sv`, `apb_poc_test.sv`, `apb_fault_injection_test.sv`, `apb_negative_tests.sv` | UVM POC env, fixture scoreboard, tests | WRITTEN |
| `filelists/apb_hdl.f`, `apb_hvl.f`, `apb_hdl_smoke.f`, `apb_poc.f` | Compile order; use `-F` | WRITTEN |
| `scripts/slang_elab.py` | slang elaboration wrapper (needs approval to run) | WRITTEN |
| `scripts/make_eda_bundle.py` | Single-file EDA Playground bundle; inlines includes (text only; exercised on `apb_poc.f` and `apb_hdl_smoke.f`) | WRITTEN |
| `README.md` | Consumer integration, BFM + HVL API, run instructions, portability policy | WRITTEN |

The original root-level `apb_*.sv` implementation exists and is **out of scope for modification**.

## Tests available (none run)

| Flow | Top(s) | Test / plusargs | Pass criterion |
|---|---|---|---|
| HDL smoke (no UVM) | `apb_hdl_smoke` | none; `+APB_FAULT=1|2|3` for negatives; `+define+APB_ENABLE_DW64_EXTENSION` | line `SMOKE_RESULT: PASS` |
| UVM POC | `apb_hdl_top` + `apb_hvl_top` | `+UVM_TESTNAME=apb_poc_test` | `TEST_RESULT: PASS (0 errors)` |
| UVM fault injection | same | `+UVM_TESTNAME=apb_fault_injection_test +APB_FAULT=1|2|3` | `TEST_RESULT: PASS` (A detected, B clean) |
| UVM cfg legality | same | `+UVM_TESTNAME=apb_cfg_negative_test` | `TEST_RESULT: PASS`; 16 verdict lines `ok:` |
| UVM width boundary | same | `+UVM_TESTNAME=apb_width_negative_test` | `TEST_RESULT: PASS` (unfit write rejected, not on the bus) |
| DW=64 extension | add `+define+APB_ENABLE_DW64_EXTENSION` to any UVM flow | as above | agent_c also passes |

## Static self-review done (2026-10-29, no tool)

- Every adapter call matches the BFM task/function signatures in `hdl/apb_driver_bfm_if.sv` / `hdl/apb_monitor_bfm_if.sv` (argument order, widths, directions).
- Every pure virtual method of both proxy bases is implemented in the concrete adapters and in the fake proxies.
- Virtual-interface typedefs in the adapters list **all** BFM parameters (including `QUEUE_DEPTH`), so they match the `apb_hdl_top` instances that use defaults.
- Only APIs common to UVM 1.2 and IEEE 1800.2-2017/2020 are used: `uvm_config_db`, `type_id::create`, `uvm_declare_p_sequencer`, `phase.get_objection().set_drain_time`, `uvm_root::get().set_timeout`, `uvm_report_server::get_server`, `set_report_severity_id_override`.
- No tool names, `` `ifdef <TOOL> `` or pragmas in any source. The only `` `ifdef `` switches are the project's own `APB_ENABLE_DW64_EXTENSION` and the `apb_defines.svh` guards.

## First-compile watch list (most likely to need attention)

Classify any failure as **source bug**, **standard violation** or **tool limitation** (contract gate). Never add tool-specific code.

1. `+incdir+` paths in `-F` filelists: some simulators resolve them relative to the filelist, others to the current directory. If includes are not found, pass the include dirs on the command line or use the EDA bundle.
2. Function call in an inline constraint: `strb == full_strb()` in `apb_base_seq::do_write`.
3. Covergroup `iff` that references a class member (`cfg.features.has_pprot`) in `apb_coverage`.
4. Size casts by package parameters (`APB_MAX_DW'(x)`, `ADDR_WIDTH'(x)`) in the adapters.
5. Package import in the interface header (`interface … import apb_bfm_pkg::*; #(…)`).
6. `fork…join_any` + `disable fork` inside an interface task (driver BFM); named-event wake in `get_transfer()` (RISK-002).
7. Two specializations of each parameterized adapter in one image (A and B), the core RISK-001 question. Verilator 5.020 is known to fail here; that is a tool limitation, not a reason to change ADR-001.
8. Hierarchical references from `apb_hvl_top` into `apb_hdl_top` (two top modules).

## Known gaps (not implemented in M1)

- APB5: `PWAKEUP` and user signals (M2), parity generation/checking (M3). `configure()` and `apb_agent_cfg` reject them today.
- CFG-05 (user widths vs physical) arrives with M2.
- RST-4 reset *event* in the observe API: only counters (`get_reset_count`) exist. No reset test yet, and the fixture scoreboard does not model reset clearing.
- Passive-agent test: needs an independent Requester on a bus (a second monitor-only instance or an RTL master). Not written.
- APB2/APB3 integration test: needs an HDL top variant tying the fixture's `PSTRB` to `PWRITE` (IHI 0024D Table 3-1). Not written.
- Coverage of reset transitions; 4-state injection test (RISK-009).
- Emulation suitability (`fork` in the BFM, `string` in monitor messages) is unassessed.

## Next tasks — in priority order

- [~] **APB-001 — Review protocol contract:** drafted in `APB_PROTOCOL_CONTRACT.md`; Q1 decided (ADR-001 A1), Q3 decided (EDA Playground as owner option), Q2/Q4/Q5 implemented on proposed defaults, awaiting owner review.
- [~] **APB-002 — Review BFM connection legality:** implemented (ordinary-port wiring, clocking blocks in the BFMs, queue + `get_transfer()`); NOT RUN in its current form.
- [~] **APB-003 — Generate minimal HDL + compile:** sources written; compile NOT RUN pending approval.
- [~] **APB-004 — Generate HVL types/proxies/agent + compile:** sources written (`30cf97d`, `4ff7f39`); compile NOT RUN pending approval.
- [~] **APB-005 — Run APB POC:** tests written (`6bf7f84`, `5b217c9`); NOT RUN. Still missing: passive, reset and APB2/APB3 tests (see *Known gaps*).
- [ ] **APB-006 — Independent reviews:** ChatGPT and Gemini review the same pinned commit (suggest `5b217c9` or later), record findings and rerun failing tests.

## Toolchain (this container, 2026-10-29)

| Tool | Version | Status | Use |
|---|---|---|---|
| slang (via `pyslang`, PyPI) | 12.1.0 (`42710c788`) | Installed; **execution needs owner approval** | SV/UVM parse and elaboration only; **cannot simulate** |
| Verilator (Ubuntu 24.04 package) | 5.020 (`5.020-1`, from `dpkg-query`) | Installed; **withdrawn** (cannot build the portable sources; RISK-001/009) | — |
| Verilator from source | 5.052 | Build denied by the session permission policy | Not tried |
| Commercial simulators (VCS/Xcelium/Questa/DSim) | — | Not in this container | Owner option: EDA Playground |
| UVM library | — | Not downloaded (needs approval, T3) | Needed for slang elaboration of HVL code |

## Validation evidence

Current sources: everything **elaborated** on approved slang (below); **nothing simulated**. Earlier unapproved slang/Verilator runs on revision `5060712` are superseded (`evidence/APB-003a/README.md`).

| Stage | Tool/version | Command | Result | Log | Commit |
|---|---|---|---|---|---|
| HDL elaboration (std + DW=64 ext.) | slang 12.1.0 (T1, approved) | `python3 -I poc/apb_uvc/scripts/slang_elab.py -F poc/apb_uvc/filelists/apb_hdl_smoke.f --top apb_hdl_smoke` [`+define+APB_ENABLE_DW64_EXTENSION`] | **PASS** — errors=0 warnings=0 (both) | `evidence/APB-004/logs/slang_hdl_*.log` (also `evidence/APB-003b/`) | `386e64d` |
| HDL-only smoke 32/16 (+DW=64 ext.) and 3 fault runs | — (T4 proposed) | NOT RUN | NOT RUN | — | — |
| HVL + UVM elaboration (`apb_poc.f`, std + DW=64 ext.) | slang 12.1.0 + UVM 1.2 mirror `a3cb911` (T1 + T3, approved) | `python3 -I poc/apb_uvc/scripts/slang_elab.py +incdir+<UVM>/src <UVM>/src/uvm_pkg.sv -F poc/apb_uvc/filelists/apb_poc.f --top apb_hdl_top --top apb_hvl_top` [`+define+APB_ENABLE_DW64_EXTENSION`] | **FAIL (UVM library)** — errors=1 warnings=2, all in UVM 1.2: `MissingTimeScale` (`uvm_pkg.sv:28`), 2 × `-Wempty-body`. **Project code: 0 errors, 0 warnings** | `evidence/APB-004/logs/slang_uvm_*.log` | `386e64d` |
| UVM `apb_poc_test` | — (T4 proposed) | NOT RUN | NOT RUN | — | — |
| UVM `apb_fault_injection_test` ×3 | — (T4 proposed) | NOT RUN | NOT RUN | — | — |
| UVM `apb_cfg_negative_test`, `apb_width_negative_test` | — (T4 proposed) | NOT RUN | NOT RUN | — | — |
| 4-state / drive release / X-Z checks | — | NOT RUN | NOT RUN | — | — |
| Reset mid-transfer, passive instance, APB2/APB3 configs | — | NOT WRITTEN | — | — | — |
| Emulation | UNKNOWN | NOT RUN | NOT RUN | — | — |
| *Superseded:* slang + Verilator 5.020 on `5060712` | slang 12.1.0, Verilator 5.020 | former `run_hdl_smoke.sh` | PASS (unapproved, revision had workarounds) | `evidence/APB-003a/logs/` | `5060712` |

## Toolchain approval request

**Owner decision 2026-10-29: T1 and T3 approved, UVM version 1.2, source `github.com/gchinna/uvm-1.2` (owner-named).** T2 withdrawn; T4 is an owner-run option; **T5 pending**. Nothing outside these items may run (contract gate; approval for one item does not cover another). No tool-specific source changes and no extra tool flags without approval. Commands are from the repository root.

| # | Tool / version | Scope | Exact commands |
|---|---|---|---|
| T1 | slang 12.1.0 (pyslang, PyPI) — **APPROVED** | Elaboration/lint of the HDL smoke and the full UVM POC | HDL: `python3 -I poc/apb_uvc/scripts/slang_elab.py -F poc/apb_uvc/filelists/apb_hdl_smoke.f --top apb_hdl_smoke` (and with `+define+APB_ENABLE_DW64_EXTENSION`). UVM: `python3 -I poc/apb_uvc/scripts/slang_elab.py +incdir+<UVM>/src <UVM>/src/uvm_pkg.sv -F poc/apb_uvc/filelists/apb_poc.f --top apb_hdl_top --top apb_hvl_top` (and with the same define) |
| T2 | ~~Verilator 5.020~~ | **Withdrawn:** cannot build the portable sources (RISK-001/009); workarounds not allowed | — |
| T3 | UVM **1.2** source — **APPROVED**, owner-named mirror | Download only, for T1 elaboration; not a simulator | `git clone https://github.com/gchinna/uvm-1.2.git /opt/tools/uvm-1.2-gchinna` (checked: commit `a3cb911`; release notes `UVM_1_2_RELEASE-1-gd6e87e2`; only extra file `src/tags`; see `evidence/APB-004/README.md`). Accellera's own host is blocked by the network policy, so no byte-compare with the official tarball |
| T4 | Commercial simulator on EDA Playground (owner picks Questa/Xcelium/VCS/…, with its UVM 1.2 or 1800.2 library) | Owner-run: HDL smoke and the UVM tests in *Tests available*, 4-state checks (RISK-009) | HDL bundle: `python3 -I poc/apb_uvc/scripts/make_eda_bundle.py poc/apb_uvc/filelists/apb_hdl_smoke.f apb_hdl_smoke_bundle.sv` (top `apb_hdl_smoke`). UVM bundle: `python3 -I poc/apb_uvc/scripts/make_eda_bundle.py poc/apb_uvc/filelists/apb_poc.f apb_poc_bundle.sv` (tops `apb_hdl_top apb_hvl_top`, run option `+UVM_TESTNAME=<test>`). The bundle step is plain text processing; record each result here |
| T5 | slang option `--timescale 1ns/1ps` — **PENDING owner decision** | Default time scale for design elements that declare none — only UVM 1.2's `uvm_pkg` here; project files keep their own `` `timescale 1ns/1ps ``. Counterpart of the `-timescale` compile option of every simulator; no source change | the T1 UVM command with `--timescale 1ns/1ps` added. Without it the UVM run fails on `MissingTimeScale` inside `uvm_pkg.sv` |

## AI handoff template (fill every session)

```text
HANDOFF FROM:
REPO/BRANCH:
EXACT COMMIT SHA:
GIT STATUS (including uncommitted files):
CURRENT TASK ID:
FILES CREATED/CHANGED:
PROVEN WORKING (with log/command):
FAILED CHECKS (with log/command):
NOT YET RUN:
UNRESOLVED APB SPEC/PORT/SCHEDULING QUESTIONS:
OPEN REVIEW FINDING IDS:
ARCHITECTURE CONTRACT/ADR AMENDED?:
NEXT EXACT COMMAND/SMALLEST TASK:
```

**Rule:** One model's confidence is not a validation result. If context/tokens are low, write this handoff before starting further generation.

### Latest handoff — 2026-10-29

```text
HANDOFF FROM: Claude (Claude Code session)
REPO/BRANCH: MAHANTHADEEKSHA-SB/apb_uvc @ feature/apb-001-protocol-contract
EXACT COMMIT SHA: approved runs at 386e64d5130748329f8148507837819e7d9f6456; evidence in fae5f10; this checkpoint is the docs commit on top (`git log -1`)
GIT STATUS (including uncommitted files): clean after commit
CURRENT TASK ID: APB-004 UVM elaboration done except the UVM-library timescale error; waiting for owner decision T5
FILES CREATED/CHANGED (this session): poc/apb_uvc/hvl/adapter/apb_drive_proxy.sv (lossless check without full-width shifts), poc/apb_uvc/scripts/slang_elab.py (reports slang's error/warning counts); docs: evidence/APB-004/**, WORK_STATUS.md, REVIEW_FEEDBACK.md
PROVEN WORKING (with log/command): slang 12.1.0 + UVM 1.2 (T1+T3) at 386e64d: HDL smoke std/DW=64 errors=0 warnings=0; UVM POC std/DW=64: project code 0 errors 0 warnings (evidence/APB-004/)
FAILED CHECKS (with log/command): UVM POC elaboration std/DW=64 exit 1: MissingTimeScale in <UVM>/src/uvm_pkg.sv:28 (library has no `timescale, project files do); fix needs T5. T3 Accellera download blocked earlier (403 connect_rejected); replaced by the owner-named mirror
NOT YET RUN: every simulation (see Validation evidence); clean UVM elaboration (needs T5)
UNRESOLVED APB SPEC/PORT/SCHEDULING QUESTIONS: Q2/Q4/Q5 implemented on proposed defaults, awaiting owner review; RST-4 reset event not in the observe API; passive and APB2/APB3 tests not written
OPEN REVIEW FINDING IDS: RISK-001..012
ARCHITECTURE CONTRACT/ADR AMENDED?: no change this session (contract v0.10, ADR-001 A1)
NEXT EXACT COMMAND/SMALLEST TASK: if the owner approves T5: run the T1 UVM command with `--timescale 1ns/1ps` (std and DW=64), record in evidence/APB-004/, fix SOURCE bugs only. Otherwise keep the UVM row as FAIL (library). Then write the missing passive/reset/APB3 tests (Known gaps). Simulation needs T4 (owner on EDA Playground) or another approved simulator
```
