# WORK_STATUS — single APB UVC handoff checkpoint

**Checkpoint date:** 2026-10-29
**Repository:** https://github.com/MAHANTHADEEKSHA-SB/apb_uvc
**Branch:** `feature/apb-001-protocol-contract` (from `dev` at `3f5c50b515c7aa67e110e2011801217b35ea6588`, which merged `feature/dv-architecture-handoff`; `dev` was initially created from `main` at `aa3f1af8bc4c6a0c03f74aaad094ca382fc7ee85`)
**Current commit SHA:** read actual `git rev-parse HEAD` / branch HEAD; this file cannot self-reference its own commit.
**Working tree:** UNKNOWN for local clones; verify before changing code.
**Phase:** APB-001 protocol contract **PROPOSED** (`APB_PROTOCOL_CONTRACT.md`), awaiting owner review; **POC implementation NOT STARTED** (`poc/apb_uvc/` does not exist yet).
**Tool results:** No RTL/UVM compilation, simulation, regression or emulation of APB UVC sources (none exist). Toolchain probe only, see *Toolchain* below.
**Next implementer:** Claude or another authorized model/engineer.
**Active task:** APB-001 — protocol contract.
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
| IMP-001 | POC APB interface and BFMs | NOT_STARTED | No new sources in `poc/apb_uvc/` evidenced |
| IMP-002 | Proxy base and concrete adapters | NOT_STARTED | No compile evidence |
| IMP-003 | Non-parameterized UVM APB components | NOT_STARTED | No compile evidence |
| IMP-004 | Single APB UVC 32/16 dual-instance test | NOT_STARTED | No simulation evidence |
| IMP-005 | Negative tests, independent reviews | NOT_STARTED | No execution or review results |

## Planned source manifest (not yet generated)

| Target path under `poc/apb_uvc/` | Owner | Status |
|---|---|---|
| `hdl/apb_if.sv` | APB pins/modports/clocking | NOT_STARTED |
| `hdl/apb_driver_bfm_if.sv` | Master protocol drive/timing | NOT_STARTED |
| `hdl/apb_monitor_bfm_if.sv` | Passive observation | NOT_STARTED |
| `hvl/types/apb_transaction.sv` | Width-independent packet representation | NOT_STARTED |
| `hvl/api/apb_{drive,monitor}_proxy_base.sv` | Abstract proxy pair | NOT_STARTED |
| `hvl/adapter/apb_{drive,monitor}_proxy.sv` | Width-specialized HVL concrete adapters | NOT_STARTED |
| `hvl/config/apb_agent_cfg.sv` | Per-instance cfg | NOT_STARTED |
| `hvl/agent/*.sv` | Non-parameterized driver/monitor/sequencer/agent | NOT_STARTED |
| `hvl/pkg/*.sv` | API/UVM/adapter package definitions | NOT_STARTED |
| `filelists/*.f` | Explicit compile dependencies | NOT_STARTED |
| `examples/*.sv` | Sample slave and dual-instance top | NOT_STARTED |
| `tests/*.sv` | Directed/negative validation | NOT_STARTED |

The original root-level `apb_*.sv` implementation exists and is **out of scope for modification**. Do not confuse that with implementation of the new `poc/apb_uvc/` design.

## Next tasks — in priority order

- [~] **APB-001 — Review protocol contract:** Select APB revision, optional pins, reset details, supported address/data widths, and 4-state transport semantics. Produce a testable signal table and acceptance matrix. → Drafted in `APB_PROTOCOL_CONTRACT.md`; Q1 decided (ADR-001 A1), Q3 decided (EDA Playground as owner option), Q2/Q4/Q5 proceeding on proposed defaults.
- [ ] **APB-002 — Review BFM connection legality:** Diagram ordinary signal-port wiring of two BFM interfaces to one `apb_if` instance; specify driver/monitor clocking and monitor-to-HVL return path. Note simulator/version.
- [ ] **APB-003 — Generate minimal HDL + compile:** `apb_if.sv`, two BFMs, example HDL top and HDL filelist. Save exact command/log and fix language restrictions.
- [ ] **APB-004 — Generate HVL types/proxies/agent + compile:** Update manifest and run a targeted smoke.
- [ ] **APB-005 — Run APB POC:** 32-bit and 16-bit instances concurrently, read/write, waits, passive observation, reset and error where applicable, negative tests.
- [ ] **APB-006 — Independent reviews:** ChatGPT and Gemini review the same pinned commit, record findings and rerun failing tests.

## Toolchain (this container, 2026-10-29)

| Tool | Version | Status | Use |
|---|---|---|---|
| slang (via `pyslang`, PyPI) | 12.1.0 (`42710c788`) | Installed; smoke-checked: clean 2-instance parameterized interface → 0 errors, seeded undeclared identifier → 1 error | SV parse/elaboration only; **cannot simulate** |
| Verilator | 5.052 (git tag) | Source build **denied by the session permission policy**; not installed | Would provide simulation evidence |
| Ubuntu `verilator` package | 5.020 | Not installed; too old for UVM | — |
| Commercial simulators (VCS/Xcelium/Questa/DSim) | — | Not available | Owner's target simulator UNKNOWN (Q3) |
| UVM library | — | Not downloaded | Needed for HVL elaboration |

## Validation evidence

| Stage | Tool/version | Command | Result | Log | Commit |
|---|---|---|---|---|---|
| APB SV syntax/style | UNKNOWN | NOT RUN | NOT RUN | — | — |
| APB HDL compile | UNKNOWN | NOT RUN | NOT RUN | — | — |
| APB UVM compile/elaboration | UNKNOWN | NOT RUN | NOT RUN | — | — |
| APB 32/16 simulation | UNKNOWN | NOT RUN | NOT RUN | — | — |
| Passive-mode + fault injection | UNKNOWN | NOT RUN | NOT RUN | — | — |
| Emulation | UNKNOWN | NOT RUN | NOT RUN | — | — |

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
EXACT COMMIT SHA: branch HEAD (`git rev-parse HEAD`); work started from 37430cb
GIT STATUS (including uncommitted files): clean after commit
CURRENT TASK ID: APB-001 (design step 1)
FILES CREATED/CHANGED: docs/dv-architecture/{APB_PROTOCOL_CONTRACT.md (new), ARCHITECTURE_CONTRACT.md, README.md, WORK_STATUS.md, REVIEW_FEEDBACK.md}
PROVEN WORKING (with log/command): slang 12.1.0 smoke only (see Toolchain); no APB sources exist
FAILED CHECKS (with log/command): none run on APB sources
NOT YET RUN: all compile/simulation stages
UNRESOLVED APB SPEC/PORT/SCHEDULING QUESTIONS: Q1 DW=64 vs IHI 0024D §2.1.2; Q2 NUM_SEL; Q3 simulator; Q4 parity milestone; Q5 reset assumptions RST-1..7
OPEN REVIEW FINDING IDS: RISK-001..008
ARCHITECTURE CONTRACT/ADR AMENDED?: contract v0.8 (PROPOSED scope section only); ADR-001/002 unchanged; ADR-001 amendment proposed for Q1
NEXT EXACT COMMAND/SMALLEST TASK: after Q1/Q5 answers, APB-003a — create poc/apb_uvc/hdl/{apb_if,apb_driver_bfm_if,apb_monitor_bfm_if}.sv, examples/{apb_example_slave,apb_hdl_top}.sv, filelists/apb_hdl.f; elaborate with slang (0 errors) and record the log
```
