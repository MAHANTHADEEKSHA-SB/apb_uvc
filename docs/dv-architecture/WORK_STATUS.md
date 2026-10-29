# WORK_STATUS — single APB UVC handoff checkpoint

**Checkpoint date:** 2026-10-29
**Repository:** https://github.com/MAHANTHADEEKSHA-SB/apb_uvc
**Branch:** `feature/apb-001-protocol-contract` (from `dev` at `3f5c50b515c7aa67e110e2011801217b35ea6588`, which merged `feature/dv-architecture-handoff`; `dev` was initially created from `main` at `aa3f1af8bc4c6a0c03f74aaad094ca382fc7ee85`)
**Current commit SHA:** read actual `git rev-parse HEAD` / branch HEAD; this file cannot self-reference its own commit.
**Working tree:** UNKNOWN for local clones; verify before changing code.
**Phase:** APB-only target architecture documented; **POC implementation NOT STARTED**.
**Tool results:** No RTL/UVM compilation, simulation, regression or emulation evidenced by these docs.
**Next implementer:** Claude or another authorized model/engineer.
**Active task:** APB-001 — protocol contract.
**Spec reference:** Arm AMBA APB Protocol Specification, ARM IHI 0024D (ID041221, 09 April 2021; adds APB5). The PDF itself is Arm copyright and is not committed here.

> Do not trust this status without comparing it to the real files, current Git SHA, and logs. Any difference must be reconciled explicitly.

## Approved scope

Deliver **one reusable APB UVC** rooted at `poc/apb_uvc/`, including its **own** signal interface, driver BFM, monitor BFM, APB-specific abstract/proxy classes, UVM agent, sequences, coverage, filelists, integration example and tests. Two simultaneous 32/64-bit instances demonstrate parameter independence. The existing root-level flat APB UVC is preserved. No other protocol UVC or multi-UVC TB is part of this POC.

## Decision/progress inventory

| ID | Work | Status | Evidence or caveat |
|---|---|---|---|
| DOC-001 | ADR-001: HVL concrete proxies | ACCEPTED_FOR_POC | `ADR-001-HVL-PROXY-PLACEMENT.md`; not compiler validated |
| DOC-002 | ADR-002: distinct drive/observe APIs; 2 BFMs / 1 APB signal interface | ACCEPTED_LOGIC | `ADR-002-SEPARATE-DRIVE-OBSERVE-APIS.md`; wiring unresolved pending compile |
| DOC-003 | Single-APB-UVC directory/contract/prompt | DOCUMENTED | `DIRECTORY_ARCHITECTURE.md`, `ARCHITECTURE_CONTRACT.md`, `CLAUDE_GENERATION_PROMPT.md` |
| IMP-001 | POC APB interface and BFMs | NOT_STARTED | No new sources in `poc/apb_uvc/` evidenced |
| IMP-002 | Proxy base and concrete adapters | NOT_STARTED | No compile evidence |
| IMP-003 | Non-parameterized UVM APB components | NOT_STARTED | No compile evidence |
| IMP-004 | Single APB UVC 32/64 dual-instance test | NOT_STARTED | No simulation evidence |
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

- [ ] **APB-001 — Review protocol contract:** Select APB revision, optional pins, reset details, supported address/data widths, and 4-state transport semantics. Produce a testable signal table and acceptance matrix.
- [ ] **APB-002 — Review BFM connection legality:** Diagram ordinary signal-port wiring of two BFM interfaces to one `apb_if` instance; specify driver/monitor clocking and monitor-to-HVL return path. Note simulator/version.
- [ ] **APB-003 — Generate minimal HDL + compile:** `apb_if.sv`, two BFMs, example HDL top and HDL filelist. Save exact command/log and fix language restrictions.
- [ ] **APB-004 — Generate HVL types/proxies/agent + compile:** Update manifest and run a targeted smoke.
- [ ] **APB-005 — Run APB POC:** 32-bit and 64-bit instances concurrently, read/write, waits, passive observation, reset and error where applicable, negative tests.
- [ ] **APB-006 — Independent reviews:** ChatGPT and Gemini review the same pinned commit, record findings and rerun failing tests.

## Validation evidence

| Stage | Tool/version | Command | Result | Log | Commit |
|---|---|---|---|---|---|
| APB SV syntax/style | UNKNOWN | NOT RUN | NOT RUN | — | — |
| APB HDL compile | UNKNOWN | NOT RUN | NOT RUN | — | — |
| APB UVM compile/elaboration | UNKNOWN | NOT RUN | NOT RUN | — | — |
| APB 32/64 simulation | UNKNOWN | NOT RUN | NOT RUN | — | — |
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
