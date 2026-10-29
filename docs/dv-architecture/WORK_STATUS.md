# Work status / cross-model checkpoint

**Updated (UTC/offset):** 2026-10-29 (time not recorded)
**Updated by:** ChatGPT — documentation handoff initialization
**Active implementer:** UNASSIGNED
**Repository URL:** https://github.com/MAHANTHADEEKSHA-SB/apb_uvc
**Branch:** feature/dv-architecture-handoff, created from dev
**Baseline SHA:** aa3f1af8bc4c6a0c03f74aaad094ca382fc7ee85. **Latest SHA:** check branch HEAD on GitHub.
**Working tree state:** Remote GitHub changes visible; local worktree not inspected.
**Project phase:** Architecture documented; implementation POC not yet evidenced
**Latest acceptance gate:** NOT RUN

> STATUS IN THIS FILE IS A CHECKPOINT, NOT SELF-VALIDATING EVIDENCE. Always inspect Git and logs before relying on it.

## Currently established

| ID | Deliverable / decision | Status | Evidence |
|---|---|---|---|
| DOC-001 | ADR-001 HVL concrete proxy placement | ACCEPTED_FOR_POC | `ADR-001-HVL-PROXY-PLACEMENT.md` |
| DOC-002 | ADR-002 separate APIs, 2 BFMs / 1 pin interface | LOGICAL_DESIGN_SELECTED | `ADR-002-SEPARATE-DRIVE-OBSERVE-APIS.md` |
| DOC-003 | Architecture and handoff document templates | GENERATED | These Markdown files; **not** a compiled design |
| IMP-001 | Package/filelist/architecture POC sources | NOT_STARTED | No generated SV source evidenced in this pack |
| IMP-002 | 32-bit + 64-bit SV/UVM compile | NOT_STARTED | No compile log |
| IMP-003 | Protocol simulation and directed tests | NOT_STARTED | No simulator log |
| IMP-004 | Independent reviewer pass and findings | NOT_STARTED | `REVIEW_FEEDBACK.md` only contains a blank template/open risks |

## Source manifest (update when source exists)

| Path | Purpose | Exists in actual repo? | State | Tested? |
|---|---|---|---|---|
| `tb/interfaces/simple_bus_if.sv` | Pin interface | UNKNOWN | NOT_STARTED | NO |
| `tb/bfm/simple_bus_driver_bfm_if.sv` | Drive BFM | UNKNOWN | NOT_STARTED | NO |
| `tb/bfm/simple_bus_monitor_bfm_if.sv` | Observe BFM | UNKNOWN | NOT_STARTED | NO |
| `uvc/simple_bus/api/*` | Abstract API pair | UNKNOWN | NOT_STARTED | NO |
| `uvc/simple_bus/adapter/*` | Specialized adapters | UNKNOWN | NOT_STARTED | NO |
| `uvc/simple_bus/agent/*` | Driver/monitor/agent/sequencer | UNKNOWN | NOT_STARTED | NO |
| `tb/top/*` | HDL/HVL integration | UNKNOWN | NOT_STARTED | NO |
| `sim/filelists/*` | Simulator compilation order | UNKNOWN | NOT_STARTED | NO |
| `tests/*` | Directed and negative tests | UNKNOWN | NOT_STARTED | NO |

`UNKNOWN` means the real repository has not been inspected; **it does not mean the file is missing**.

## Next 5 tasks (priority order)

- [ ] **TASK-001:** Inspect actual repo/branch/commit and reconcile source inventory with this document. Acceptance: paths and SHA recorded; uncommitted changes documented.
- [ ] **TASK-002:** Resolve first POC transport/payload choice and write a small interface/BFM top-level connection proposal. Acceptance: SV legal connection spelled out, unsupported-width behavior specified.
- [ ] **TASK-003:** Generate source and compile filelists for both 32- and 64-bit instances. Acceptance: exact compiler invoked successfully; log preserved.
- [ ] **TASK-004:** Run directed transactions and passive observation tests with a reproducible command. Acceptance: logs show 32/64 instances and checks.
- [ ] **TASK-005:** Independent ChatGPT/Gemini review on the **same pinned SHA**, issue log updated, fixes prioritized and revalidated.

## Last session changes

- Added a stable architecture contract, status checkpoint, multi-model entrypoint, independent review log, and separate generation prompt.
- No SystemVerilog code has been produced or simulated by this documentation update.
- Existing ADR-001/ADR-002 and directory architecture preserved from prior package.

## Known blockers / unknowns

- No verified current Git repository URL/branch/SHA.
- Simulator/tool availability and version have not been established here.
- BFM-to-pins wiring and monitor return transport have not passed a real compile/simulation.
- Payload representation beyond initial 32/64 POC is undecided.

## Validation evidence (never fill with guesses)

| Stage | Tool and version | Exact command | Result | Artifact / log | Commit |
|---|---|---|---|---|---|
| Architecture regex checker | NOT RUN | — | NOT RUN | — | — |
| SV syntax/style lint | NOT RUN | — | NOT RUN | — | — |
| UVM compile/elaboration | NOT RUN | — | NOT RUN | — | — |
| 32/64 simulation | NOT RUN | — | NOT RUN | — | — |
| Fault injection | NOT RUN | — | NOT RUN | — | — |

## Before handing over to another AI — fill this block

```text
HANDOFF FROM: <Claude | ChatGPT | Gemini | engineer>
BRANCH: <actual branch>
COMMIT: <actual full SHA or UNCOMMITTED>
GIT STATUS: <clean | file list of uncommitted modifications>
CHANGED FILES: <paths and short summary>
WHAT IS WORKING: <only proven features and exact supporting tests>
WHAT IS NOT WORKING: <failures with symptoms and log references>
UNVALIDATED ASSUMPTIONS: <list>
APPROVED ADRS CHANGED?: <no | explicit approved amendment>
CURRENT TASK: <ID / status / expected behavior>
NEXT EXACT STEP: <single command/file change/test to run>
OPEN REVIEW FINDINGS: <IDs from REVIEW_FEEDBACK.md>
TOOLS + VERSIONS: <actual values or UNKNOWN>
```

## Checkpoint integrity

- Do not update status on the basis of model memory alone. Check actual files and Git SHA.
- Generated but uncompilable code is `GENERATED` or `BLOCKED`, not `COMPILED`.
- If all work happens in an uncommitted worktree, capture `git status --short` and changed paths; do not mislabel it a committed checkpoint.
- Commit docs and source together when authorized, avoiding history rewrite.