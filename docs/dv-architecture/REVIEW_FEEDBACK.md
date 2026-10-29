# REVIEW_FEEDBACK — one APB UVC POC

**Scope:** Independent reviews of the **single APB UVC** developed under `poc/apb_uvc/`. Both DW=32 and DW=16 (ADR-001 Amendment A1) are specializations of **the same UVC**. This log does not certify the existing root-level APB implementation.

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
- **Evidence required:** compiler version, elaborated DW=32 and DW=16 instances, success/failure logs, port connection review. Do not use interface-typed BFM ports with virtual handles without validating the known SV portability restriction.
- **Evidence 2026-10-29 (APB-003a revision `5060712`, superseded by the RISK-010 reverts; see `evidence/APB-003a/`):**
  - slang 12.1.0: the full HDL smoke elaborates with 0 errors and 0 warnings, both standard and with the DW=64 extension. Two BFM interfaces with ordinary signal ports share one `apb_if` per instance.
  - Verilator 5.020: the same design builds and simulates. Calling BFM tasks through a typed `virtual apb_*_bfm_if #(…)` handle works **for one specialization** (repro r1/r2).
  - **Tool defect found:** Verilator 5.020 aborts with an internal fault (`V3Broken`: broken `m_ifacep` link after `deadifyModules`) when **two specializations of a parameterized class** each declare a parameterized virtual-interface type (repro r3/r4). That is exactly the ADR-001 `drive_adapter #(DW)` pattern. A non-parameterized abstract base plus per-width non-parameterized concrete classes works (r6).
  - Verilator 5.020 also rejects a generic interface port bound to a hierarchical instance (`expected 'apb_driver_bfm_if' … is a different interface 'apb_driver_bfm_if__D10'`); binding the consumer into the instantiating module works.
  - **Consequence:** Verilator 5.020 cannot validate the ADR-001 adapter layer (step 4). Since the RISK-010 reverts, it cannot build the generic HDL smoke either (class runner, `fork` in the driver, `'z` release). Use slang for elaboration and a commercial simulator (EDA Playground) or a newer Verilator for simulation; do not change ADR-001 or the sources on the basis of a tool bug.
- **Status:** OPEN — the HVL adapters are now written (`hvl/adapter/*`, commit `30cf97d`) but never compiled. The first approved compile of `filelists/apb_poc.f` (two specializations of each adapter in one image) is the decisive check.

### RISK-002 — APB handshake scheduling and observation
- **Status:** OPEN.
- Does the master maintain correct `PSEL`, `PENABLE`, address/control/data through `PREADY=0` wait states? Does the monitor publish exactly once at `PSEL && PENABLE && PREADY` using race-free sampling?
- **Evidence required:** zero-wait, multiple-wait, back-to-back transfer and reset-at-boundary directed waveforms, assertion results.
- **Evidence 2026-10-29 (Verilator 5.020, `evidence/APB-003a/`):** 0-wait and 2-wait reads and writes, a back-to-back write→read (SETUP at completion cycle + 1), a `PSTRB` partial write and a `PSLVERR` read pass on DW=32, DW=16 and DW=64-extension instances. Every published transfer matches, the publication count is exact (no duplicates, checked 4 cycles after the last transfer) and the monitor error count is 0. Three injected faults (`PADDR` change in a wait state, ACCESS without SETUP, `PSEL` dropped while `PREADY` LOW) are each detected with the matching error code on the faulted instance only. A mutant with the `PADDR` stability check removed makes the fault-1 run FAIL.
- **Transport finding (Verilator 5.020 only):** with a named event, Verilator 5.020 never woke a `get_transfer()` caller that suspended in the same time step just before the publish. After RISK-010 the sources keep the standard named-event design (`while (queue empty) @(obs_ev)`), which is correct SystemVerilog; the Verilator behaviour is logged as a tool limitation, not coded around.
- The PASS results above were measured on the superseded revision `5060712`, which still had the workarounds. They do not apply to the current sources.
- **Not yet run:** reset at a transfer boundary or mid-transfer, any 4-state simulator.
- **Status:** OPEN (partially evidenced).

### RISK-003 — Lossless width and per-instance isolation
- **Status:** OPEN.
- Is the same non-parameterized APB transaction/proxy API capable of representing DW=32 and DW=16 (and the DW=64 extension) without loss? Are read data, write data, optional `PSTRB` and 4-state values handled correctly?
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
- **Status:** DECIDED 2026-10-29 — owner approved DW=32 + DW=16 with DW=64 as opt-in extension (ADR-001 Amendment A1). Remains OPEN until the CFG-04 check and the extension switch are implemented and tested.
- IHI 0024D §2.1.2 and Table 2-1 state that `PWDATA`/`PRDATA` can be 8, 16 or 32 bits wide. ADR-001 §3 and the acceptance gates demonstrate width independence with a DW=64 instance, which no APB revision defines. A DW=64 test would therefore validate a non-standard interface, and `PSTRBCHK` granularity (Table 5-1, 1–4 bits) would also be exceeded.
- **Proposed remedy:** ADR-001 amendment — use DW=32 + DW=16 as the spec-legal pair; optionally keep DW=64 behind an explicit non-standard-extension switch, off by default.
- **Evidence required:** owner decision recorded; ADR-001 amended text; cfg check CFG-04 test.

### RISK-008 — APB5 superset pin interface versus ADR-001 "maximum-footprint" rejection
- **Status:** OPEN (design review).
- The owner requires all APB2–APB5 features in one UVC, so `apb_if` declares the APB5 pin superset with runtime presence flags. ADR-001 rejected a *width* maximum-footprint interface; widths here stay parameterized, but reviewers should confirm that the unused-pin, tie-off and debug costs are acceptable and that absent-input defaults (`PREADY`=1, `PSLVERR`=0, IHI Table B-1) cannot mask a real connection fault.
- **Evidence required:** a test where a present-but-unconnected `PREADY` (Z/X) is reported rather than defaulted.

### RISK-009 — Verilator 5.020 cannot verify 4-state or drive-release behaviour
- **Status:** OPEN; needs a 4-state simulator run (e.g. EDA Playground, `poc/apb_uvc/README.md`).
- Verilator is 2-state and does not support `'z` driven into interface nets (`Unsupported LHS tristate construct: VARXREF`). Under `VERILATOR`, `apb_driver_bfm_if` therefore drives released outputs as 0. These are untested so far: the passive-instance release to `'z` (section 8), the monitor's X/Z checks (`PSEL_XZ`, `CONTROL_XZ`, `PREADY_XZ` — RISK-008), and the 4-state round trip of `PRDATA`.
- **Evidence required:** the same smoke plus a release/X-injection test on a 4-state simulator, with the tool version and log.

### RISK-010 — Source changes made for unapproved tools (toolchain gate rule 5)
- **Status:** DISPOSITIONED 2026-10-29 — owner: "no tool-specific workarounds; generic as much as possible". C1–C5 reverted and the `verilator lint_off` pragmas removed from the example slave; C6 kept as tool-neutral hygiene (owner may still veto). Closes once the reverted sources compile on an approved tool. Raised when the toolchain gate (`dev` PR #3) was merged.
- The gate forbids rewriting valid SystemVerilog/UVM solely for an unapproved tool's limitations. These edits were made while running slang 12.1.0 and Verilator 5.020 without explicit approval:

| ID | File | Change | Driven by | Standard-valid before? | Proposed disposition |
|---|---|---|---|---|---|
| C1 | `hdl/apb_driver_bfm_if.sv` | `` `ifdef VERILATOR `` makes released outputs read 0 instead of `'z` | Verilator: no `'z` into interface nets | yes | Keep only if Verilator is approved; otherwise remove (standard path unchanged either way) |
| C2 | `hdl/apb_driver_bfm_if.sv` | `fork…join_any` reset watchdog replaced by a per-`PCLK` reset check; an `always @(PRESETn)` block still idles the pins immediately | Verilator internal fault (V3Fork) | yes | Keep on its own merits (no dynamic processes, emulation-friendlier), **or** restore the fork version. Behavioural difference: `do_transfer()` returns `RESET_ABORTED` at the next `PCLK` edge, not at the reset edge |
| C3 | `hdl/apb_monitor_bfm_if.sv` | `get_transfer()` waits on `@(obs_tick or posedge PCLK)` (NBA toggle) instead of a named event | Verilator lost wake-up | yes | Keep the NBA toggle (deterministic same-step delivery); the `posedge PCLK` term is the Verilator workaround and can go if Verilator is not approved |
| C4 | `examples/apb_example_slave.sv` | Memory zero-filled at time 0 and no longer cleared by `PRESETn` | Verilator BLKLOOPINIT | yes | Example fixture only; keep or restore reset clearing |
| C5 | `tests/apb_hdl_smoke*.sv` | Width-parameterized class runner replaced by a module `bind`-ed into `apb_hdl_top`; width check moved from elaboration to run time | Verilator internal fault + generic-port limitation | yes | Test only; keep or restore the class runner |
| C6 | `hdl/*`, `examples/*`, `tests/*` | Named generate blocks, sign/width-clean comparisons, word-organised slave memory | slang warnings | yes | Lint hygiene, no behaviour change; propose keep |

- None of these touch an accepted ADR decision; the HVL adapters (ADR-001) are not written yet, and the Verilator class defect (RISK-001) has **not** been used to change ADR-001.
- **Applied disposition:**

| ID | Action taken |
|---|---|
| C1 | Reverted: released outputs are always `'z`; no `` `ifdef VERILATOR `` |
| C2 | Reverted: `fork…join_any` reset watcher restored (immediate `RESET_ABORTED`, RST-2) |
| C3 | Reverted: named event `obs_ev`; `get_transfer()` waits `while (queue empty) @(obs_ev)` |
| C4 | Reverted: example slave memory cleared by `PRESETn` again |
| C5 | Reverted: width-parameterized class runner with typed virtual BFM handles; `tests/apb_hdl_smoke_runner.sv` deleted |
| C6 | Kept: named generate blocks, sign/width-clean comparisons, word-organised slave memory |
| — | Removed `scripts/run_hdl_smoke.sh` (Verilator-specific runner that cannot build the generic sources) |
| — | Kept real test-bug fixes (they are not tool-specific): monitor count checked only after draining the expected observations; no initializer on a static variable in procedural code |

### RISK-011 — HVL/UVM layer written without any compilation
- **Status:** OPEN; raised 2026-10-29 for commits `30cf97d`..`5b217c9`.
- The transaction, proxy bases, adapters, UVM agent, sequences, coverage, HVL top and tests were written under the toolchain gate, with no tool approved. Only a static self-review was done (`WORK_STATUS.md` *Static self-review done*).
- Constructs most likely to need attention are listed in `WORK_STATUS.md` *First-compile watch list*. Each failure must be classified as source bug, standard violation or tool limitation, and fixed without tool-specific code.
- **Evidence required:** an approved elaboration of `filelists/apb_poc.f` (slang + UVM library, or a commercial simulator) with 0 errors, then the four UVM tests passing with logs and SHA.

## Closed findings

_None. No SV/UVM source has been generated, compiled or simulated as part of this documentation review._
