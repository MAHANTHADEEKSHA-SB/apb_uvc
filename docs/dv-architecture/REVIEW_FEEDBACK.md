# REVIEW_FEEDBACK — one APB UVC POC

**Scope:** Independent reviews of the **single APB UVC** developed under `poc/apb_uvc/`. Both DW=32 and DW=64 are specializations of **the same UVC**. This log does not certify the existing root-level APB implementation.

## Independent evidence loop

1. Pin the exact feature-branch commit SHA before reviewing; read `ARCHITECTURE_CONTRACT.md`, ADR-001/002, and the APB revision/pin contract.
2. Claude (or implementing engineer) records generated files and actual compiler/simulator logs in `WORK_STATUS.md`.
3. ChatGPT reviews that commit independently for SV type legality, UVM architecture, APB timing, race-free monitor sampling and instance isolation; Gemini performs an independent review before seeing conclusions.
4. Record each concrete issue with file/line, reproduction or evidence, severity, proposed remedy, fix commit and retest result.
5. Re-run targeted checks **and** relevant regression; close only with proof or explicit approved waiver. LLM consensus without executed evidence is not a PASS.

## Review finding template

```markdown
### RV-XXX — Brief APB-specific title
- Status: OPEN | INVESTIGATING | FIXED_UNVERIFIED | CLOSED_VERIFIED | WAIVED_APPROVED
- Severity: BLOCKER | MAJOR | MINOR | SUGGESTION
- Reviewers:
- Reviewed branch and full SHA:
- APB revision / width configuration:
- File(s) and line(s):
- Requirement / architecture ADR:
- Failing scenario:
- Evidence (trace, test, compiler error, or concrete reasoning):
- Corrective action:
- Fix commit:
- Retest tool/version + exact command + log + result:
- Closure decision:
```

## Open design risks (not established implementation defects)

### RISK-001 — Two BFM SV interface binding legality
- **Status:** OPEN; **applies to** `hdl/apb_{driver,monitor}_bfm_if.sv`.
- Do the typed virtual BFM handles compile when two BFMs use **ordinary individual signal ports** wired to the same `apb_if` instance?
- **Evidence required:** compiler version, elaborated DW=32 and DW=64 instances, success/failure logs, port connection review. Do not use interface-typed BFM ports with virtual handles without validating the known SV portability restriction.

### RISK-002 — APB handshake scheduling and observation
- **Status:** OPEN.
- Does the master maintain correct `PSEL`, `PENABLE`, address/control/data through `PREADY=0` wait states? Does the monitor publish exactly once at `PSEL && PENABLE && PREADY` using race-free sampling?
- **Evidence required:** zero-wait, multiple-wait, back-to-back transfer and reset-at-boundary directed waveforms, assertion results.

### RISK-003 — Lossless width and per-instance isolation
- **Status:** OPEN.
- Is the same non-parameterized APB transaction/proxy API capable of representing DW=32 and DW=64 without loss? Are read data, write data, optional `PSTRB` and 4-state values handled correctly?
- **Evidence required:** edge patterns, upper 32 bits, deliberate cross-binding fault test and reported mismatch.

### RISK-004 — Passive UVC and deliverability
- **Status:** OPEN.
- Can a passive APB agent observe when its driver does not drive? Can a consumer build the reusable APB core without example DUT/tests or older repository source?
- **Evidence required:** passive simulation and independent filelist compile.

### RISK-005 — APB protocol revision contract
- **Status:** OPEN.
- Is the supported APB revision and pin subset documented and implemented consistently, including reset, `PSLVERR` and optional `PSTRB`/`PPROT`?
- **Evidence required:** revision declaration and traceability checklist in `poc/apb_uvc/README.md`.

### RISK-006 — Scope creep / misleading migration
- **Status:** OPEN pending code generation.
- Does any generated file create a second protocol UVC or modify the older root-level APB UVC without authorization?
- **Evidence required:** branch diff restricted to docs and new `poc/apb_uvc/` files.

### RISK-007 — DW=64 is outside ARM IHI 0024D
- **Status:** OPEN; needs owner decision (`APB_PROTOCOL_CONTRACT.md` Q1).
- IHI 0024D §2.1.2 and Table 2-1 state that `PWDATA`/`PRDATA` can be 8, 16 or 32 bits wide. ADR-001 §3 and the acceptance gates demonstrate width independence with a DW=64 instance, which no APB revision defines. A DW=64 test would therefore validate a non-standard interface, and `PSTRBCHK` granularity (Table 5-1, 1–4 bits) would also be exceeded.
- **Proposed remedy:** ADR-001 amendment — use DW=32 + DW=16 as the spec-legal pair; optionally keep DW=64 behind an explicit non-standard-extension switch, off by default.
- **Evidence required:** owner decision recorded; ADR-001 amended text; cfg check CFG-04 test.

### RISK-008 — APB5 superset pin interface versus ADR-001 "maximum-footprint" rejection
- **Status:** OPEN (design review).
- The owner requires all APB2–APB5 features in one UVC, so `apb_if` declares the APB5 pin superset with runtime presence flags. ADR-001 rejected a *width* maximum-footprint interface; widths here stay parameterized, but reviewers should confirm that the unused-pin, tie-off and debug costs are acceptable and that absent-input defaults (`PREADY`=1, `PSLVERR`=0, IHI Table B-1) cannot mask a real connection fault.
- **Evidence required:** a test where a present-but-unconnected `PREADY` (Z/X) is reported rather than defaulted.

## Closed findings

_None. No SV/UVM source has been generated, compiled or simulated as part of this documentation review._
