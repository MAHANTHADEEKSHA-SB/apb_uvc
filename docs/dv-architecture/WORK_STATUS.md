# WORK_STATUS — single APB UVC handoff checkpoint

**Checkpoint date:** 2026-10-29
**Repository:** https://github.com/MAHANTHADEEKSHA-SB/apb_uvc
**Branch:** `feature/apb-001-protocol-contract` (from `dev` at `3f5c50b515c7aa67e110e2011801217b35ea6588`, which merged `feature/dv-architecture-handoff`; `dev` was initially created from `main` at `aa3f1af8bc4c6a0c03f74aaad094ca382fc7ee85`)
**Current commit SHA:** read actual `git rev-parse HEAD` / branch HEAD; this file cannot self-reference its own commit.
**Working tree:** UNKNOWN for local clones; verify before changing code.
**Phase:** M1 step 2 (HDL) **written as portable IEEE 1800-2017 SystemVerilog; compile/simulation NOT RUN** (toolchain approval pending). HVL (steps 3–5) NOT STARTED. Protocol contract PROPOSED, with Q1/Q3 decided by the owner.
**Tool results:** none for the current sources. Unapproved slang/Verilator runs at `5060712` are superseded, because that revision's Verilator workarounds were reverted per owner decision (RISK-010). No tool runs until the owner approves one.
**Next implementer:** Claude or another authorized model/engineer.
**Active task:** toolchain approval pending (see *Toolchain approval request*). APB-004 source generation may proceed meanwhile; its compile stages stay NOT RUN.
**Spec reference:** Arm AMBA APB Protocol Specification, ARM IHI 0024D (ID041221, 09 April 2021; adds APB5). The PDF itself is Arm copyright and is not committed here.

> Do not trust this status without comparing it to the real files, current Git SHA, and logs. Any difference must be reconciled explicitly.

## Approved scope

Deliver **one reusable APB UVC** rooted at `poc/apb_uvc/`, including its **own** signal interface, driver BFM, monitor BFM, APB-specific abstract/proxy classes, UVM agent, sequences, coverage, filelists, integration example and tests. Two simultaneous 32/16-bit instances demonstrate parameter independence (ADR-001 Amendment A1; DW=64 only as an opt-in non-standard extension). The existing root-level flat APB UVC is preserved. No other protocol UVC or multi-UVC TB is part of this POC.

## Decision/progress inventory

| ID | Work | Status | Evidence or caveat |
|---|---|---|---|
| DOC-001 | ADR-001: HVL concrete proxies | ACCEPTED_FOR_POC | `ADR-001-HVL-PROXY-PLACEMENT.md`; not compiler validated |
| DOC-002 | ADR-002: distinct drive/observe APIs; 2 BFMs / 1 APB signal interface | ACCEPTED_LOGIC | `ADR-002-SEPARATE-DRIVE-OBSERVE-APIS.md`; wiring unresolved pending compile |
| DOC-003 | Single-APB-UVC directory/contract/prompt | DOCUMENTED | `DIRECTORY_ARCHITECTURE.md`, `ARCHITECTURE_CONTRACT.md`, `CLAUDE_GENERATION_PROMPT.md` |
| DOC-004 | APB-001 protocol contract (revision matrix, pins, rules, reset, transaction, deps, manifest) | PROPOSED | `APB_PROTOCOL_CONTRACT.md`; traced to ARM IHI 0024D; open questions Q1–Q5 |
| IMP-001 | POC APB interface and BFMs | WRITTEN_M1 (APB2/3/4), NOT RUN | `poc/apb_uvc/hdl/*`; portable sources after RISK-010 reverts; `evidence/APB-003a/` superseded; 4-state/release unverified (RISK-009); APB5 features M2/M3 |
| IMP-002 | Proxy base and concrete adapters | NOT_STARTED | No compile evidence |
| IMP-003 | Non-parameterized UVM APB components | NOT_STARTED | No compile evidence |
| IMP-004 | Single APB UVC 32/16 dual-instance test | NOT_STARTED | No simulation evidence |
| IMP-005 | Negative tests, independent reviews | NOT_STARTED | No execution or review results |

## Source manifest

| Target path under `poc/apb_uvc/` | Owner | Status |
|---|---|---|
| `hdl/apb_bfm_pkg.sv` | Types shared by BFMs and HVL adapters (no UVM) | DONE (added; contract §10) |
| `hdl/apb_if.sv` | APB5 superset pins/modports; width checks | DONE |
| `hdl/apb_driver_bfm_if.sv` | Master protocol drive/timing, release, fault modes | WRITTEN_M1, NOT RUN |
| `hdl/apb_monitor_bfm_if.sv` | Passive observation, protocol checks, queue | WRITTEN_M1, NOT RUN |
| `hvl/types/apb_transaction.sv` | Width-independent packet representation | NOT_STARTED |
| `hvl/api/apb_{drive,monitor}_proxy_base.sv` | Abstract proxy pair | NOT_STARTED |
| `hvl/adapter/apb_{drive,monitor}_proxy.sv` | Width-specialized HVL concrete adapters | NOT_STARTED |
| `hvl/config/apb_agent_cfg.sv` | Per-instance cfg | NOT_STARTED |
| `hvl/agent/*.sv` | Non-parameterized driver/monitor/sequencer/agent | NOT_STARTED |
| `hvl/pkg/*.sv` | API/UVM/adapter package definitions | NOT_STARTED |
| `filelists/apb_hdl.f`, `filelists/apb_hdl_smoke.f` | HDL compile order (use `-F`) | DONE; `apb_hvl.f`, `apb_poc.f` NOT_STARTED |
| `examples/apb_example_slave.sv`, `examples/apb_hdl_top.sv` | Example Completer; A DW=32 + B DW=16 (+C DW=64 ext.) | DONE; `apb_hvl_top.sv` NOT_STARTED |
| `tests/apb_hdl_smoke.sv` | HDL-only directed + fault-injection smoke (class runner, typed virtual BFM handles) | WRITTEN, NOT RUN; UVM tests NOT_STARTED |
| `scripts/slang_elab.py`, `scripts/make_eda_bundle.py` | slang wrapper (needs approval), EDA Playground bundle (plain text) | WRITTEN; `run_hdl_smoke.sh` removed (Verilator-specific) |
| `README.md` | Consumer integration, BFM API, run instructions | DONE (HDL scope) |

The original root-level `apb_*.sv` implementation exists and is **out of scope for modification**. Do not confuse that with implementation of the new `poc/apb_uvc/` design.

## Next tasks — in priority order

- [~] **APB-001 — Review protocol contract:** Select APB revision, optional pins, reset details, supported address/data widths, and 4-state transport semantics. Produce a testable signal table and acceptance matrix. → Drafted in `APB_PROTOCOL_CONTRACT.md`; Q1 decided (ADR-001 A1), Q3 decided (EDA Playground as owner option), Q2/Q4/Q5 proceeding on proposed defaults.
- [~] **APB-002 — Review BFM connection legality:** Diagram ordinary signal-port wiring of two BFM interfaces to one `apb_if` instance; specify driver/monitor clocking and monitor-to-HVL return path. Note simulator/version. → Implemented: ordinary-port wiring in `apb_hdl_top`, clocking blocks inside each BFM, queue + `get_transfer()` return path (contract §7). Validated on slang + Verilator 5.020 only; open items in RISK-001/002/009.
- [~] **APB-003 — Generate minimal HDL + compile:** `apb_if.sv`, two BFMs, example HDL top and HDL filelist. Save exact command/log and fix language restrictions. → APB-003a sources written (portable, RISK-010 reverts applied); compile/simulation NOT RUN pending toolchain approval. `evidence/APB-003a/` is superseded.
- [ ] **APB-004 — Generate HVL types/proxies/agent + compile:** Update manifest and run a targeted smoke.
- [ ] **APB-005 — Run APB POC:** 32-bit and 16-bit instances concurrently, read/write, waits, passive observation, reset and error where applicable, negative tests.
- [ ] **APB-006 — Independent reviews:** ChatGPT and Gemini review the same pinned commit, record findings and rerun failing tests.

## Toolchain (this container, 2026-10-29)

| Tool | Version | Status | Use |
|---|---|---|---|
| slang (via `pyslang`, PyPI) | 12.1.0 (`42710c788`) | Installed; **execution now needs owner approval**; smoke-checked before the gate: clean 2-instance parameterized interface → 0 errors, seeded undeclared identifier → 1 error | SV parse/elaboration only; **cannot simulate** |
| Verilator (Ubuntu 24.04 package) | 5.020 (`5.020-1`, from `dpkg-query`) | Installed via apt; used before the gate; **execution now needs owner approval** | 2-state; no `'z` into interface nets; two defects found (RISK-001/002). Cannot run UVM |
| Verilator from source | 5.052 | Build **denied by the session permission policy** | Newer versions may fix the RISK-001 defects; not tried |
| Commercial simulators (VCS/Xcelium/Questa/DSim) | — | Not in this container | Owner option: EDA Playground (`poc/apb_uvc/README.md`, `make_eda_bundle.py`) |
| UVM library | — | Not downloaded | Needed for HVL elaboration |

## Validation evidence

Current sources (after the RISK-010 reverts): **nothing has been compiled or simulated.** Earlier unapproved slang/Verilator runs on revision `5060712` are superseded (`evidence/APB-003a/README.md`).

| Stage | Tool/version | Command | Result | Log | Commit |
|---|---|---|---|---|---|
| APB HDL elaboration (std + DW=64 ext.) | — (T1 proposed) | NOT RUN | NOT RUN | — | — |
| APB 32/16 HDL-only simulation (+DW=64 ext.) | — (T4 proposed) | NOT RUN | NOT RUN | — | — |
| HDL fault injection (3 modes, instance A) | — (T4 proposed) | NOT RUN | NOT RUN | — | — |
| 4-state / drive release / X-Z checks | — | NOT RUN | NOT RUN | — | — |
| Reset mid-transfer, passive instance, APB2/APB3 configs | — | NOT RUN | NOT RUN | — | — |
| APB UVM compile/elaboration | UNKNOWN | NOT RUN | NOT RUN | — | — |
| Emulation | UNKNOWN | NOT RUN | NOT RUN | — | — |
| *Superseded:* slang + Verilator 5.020 on `5060712` | slang 12.1.0, Verilator 5.020 | former `run_hdl_smoke.sh` | PASS (unapproved, revision had workarounds) | `evidence/APB-003a/logs/` | `5060712` |

## Toolchain approval request (pending owner decision)

Nothing below runs until the owner explicitly approves it (contract gate; approval for one item does not cover another).

| # | Tool / version | Scope | Exact commands (from repo root) |
|---|---|---|---|
| T1 | slang 12.1.0 (pyslang, PyPI) | Elaboration/lint of HDL now; HVL + UVM elaboration later (needs a UVM library, item T3) | `python3 -I poc/apb_uvc/scripts/slang_elab.py -F poc/apb_uvc/filelists/apb_hdl_smoke.f --top apb_hdl_smoke` (and the same with `+define+APB_ENABLE_DW64_EXTENSION`) |
| T2 | ~~Verilator 5.020~~ | **Not proposed:** it cannot build the portable sources (class runner, `fork` in the BFM, `'z` on interface nets; RISK-001/009), and workarounds are not allowed | — |
| T3 | Accellera UVM library source (version to choose: 1800.2-2020 or 1.2) | Download only, for T1 elaboration of HVL code; not a simulator | owner to confirm source and version |
| T4 | Commercial simulator on EDA Playground (owner picks Questa/Xcelium/VCS/…) | Owner-run 4-state HDL smoke: positive, `+APB_FAULT=1..3`, DW=64 extension (RISK-009); later UVM | bundle: `python3 -I poc/apb_uvc/scripts/make_eda_bundle.py poc/apb_uvc/filelists/apb_hdl_smoke.f apb_hdl_smoke_bundle.sv` (plain-text concatenation, not a tool run); top `apb_hdl_smoke`; results recorded here |

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
EXACT COMMIT SHA: branch HEAD (`git log -1`); dev merged at 91c369f; superseded tool runs at 50607121dfc980ac89bbb768d30e768c9df98e68
GIT STATUS (including uncommitted files): clean after commit
CURRENT TASK ID: APB-003a written (portable; NOT RUN); toolchain approval pending (T1, T3, T4); next APB-004 source only
FILES CREATED/CHANGED: poc/apb_uvc/** (new: hdl, examples, tests, filelists, scripts, README, .gitignore); docs/dv-architecture/{APB_PROTOCOL_CONTRACT.md, REVIEW_FEEDBACK.md, WORK_STATUS.md, ADR-001 (A1), ADR-002, ARCHITECTURE_CONTRACT v0.9, DIRECTORY_ARCHITECTURE, CLAUDE_GENERATION_PROMPT, AGENTS.md, README.md, evidence/APB-003a/**}; root AGENTS.md (DW=16 wording only)
PROVEN WORKING (with log/command): nothing for the current sources. Superseded: unapproved slang + Verilator PASS at 5060712 (revision with Verilator workarounds, reverted per RISK-010)
FAILED CHECKS (with log/command): none run on the current sources. Verilator 5.020 defects logged as tool limitations (RISK-001/002/009), not worked around
NOT YET RUN: 4-state simulator; reset mid-transfer; passive instance; APB2/APB3 configs; anything UVM
UNRESOLVED APB SPEC/PORT/SCHEDULING QUESTIONS: Q2/Q4/Q5 implemented on proposed defaults, awaiting owner review; monitor delivery latency differs on Verilator (RISK-002)
OPEN REVIEW FINDING IDS: RISK-001..010 (RISK-007 decided, open until the cfg check is tested; RISK-010 dispositioned, open until the reverted sources compile on an approved tool)
ARCHITECTURE CONTRACT/ADR AMENDED?: ADR-001 Amendment A1 (owner-approved width pair 32/16, DW=64 extension); contract v0.9; ADR-002 references A1 only
NEXT EXACT COMMAND/SMALLEST TASK: no tool execution until the owner approves items in *Toolchain approval request*. Then APB-004 step 3 — obtain a UVM library (Accellera UVM 2020.3.1 or 1.2) for slang elaboration; write hvl/types/apb_transaction.sv, hvl/api/apb_{drive,monitor}_proxy_base.sv, hvl/pkg/apb_api_pkg.sv; elaborate with slang; then step 4 adapters (Verilator 5.020 cannot validate them — RISK-001)
```
