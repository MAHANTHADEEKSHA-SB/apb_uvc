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
- **Evidence 2026-10-29 (approved T1, `evidence/APB-003b/`):** slang 12.1.0 elaborates the portable HDL smoke at `3dfd30a` with 0 errors and 0 diagnostics. That design already uses the ADR-001 shape at HDL level: one parameterized class with **two specializations** (DW=32, DW=16; three with DW=64), each holding typed `virtual apb_*_bfm_if #(…)` handles bound to the BFMs, which have ordinary signal ports.
- **Evidence 2026-10-29 (approved T1 + T3, `evidence/APB-004/`, commit `386e64d`):** `filelists/apb_poc.f` elaborates with tops `apb_hdl_top` and `apb_hvl_top`; the HVL adapters (`hvl/adapter/*`) have two specializations each (three with the DW=64 extension) and project code reports 0 errors and 0 warnings. This line replaces a status written before UVM 1.2 was available (corrected 2026-11-17).
- **Status:** OPEN — elaboration evidence exists; simulation evidence is still needed for run-time behaviour.

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
- **Evidence 2026-10-29 (approved T1+T3, `evidence/APB-004/`, commit `386e64d`):** slang 12.1.0 + UVM 1.2 elaborates the full POC (standard and DW=64) with **0 errors and 0 warnings in project code**. The first run found 2 × `-Wshift-count-overflow` in `apb_drive_proxy.sv` (full-width shift in the lossless check), fixed generically in `386e64d`. The run still exits with 1 error inside the UVM library (RISK-012).
- **Status:** OPEN until the UVM run is clean (RISK-012) and the UVM tests have run on a simulator.

### RISK-012 — UVM 1.2 has no `timescale; mixing is an error under slang
- **Status:** OPEN; T5 not approved — the owner paused open-source compilation and will check runs manually (`DECISION_LOG.md` D-010).
- slang 12.1.0 reports `MissingTimeScale` at `<UVM>/src/uvm_pkg.sv:28` ("design element does not have a time scale defined but others in the design do"). UVM 1.2 deliberately ships without a time scale; every project file declares `` `timescale 1ns/1ps ``.
- **Classification:** library / language rule, not a project source bug. Not worked around in the sources: no edits to UVM, no removal of project time scales, no shim file.
- **Proposed resolution:** owner approval to add slang's `--timescale 1ns/1ps` (default for design elements without one; the counterpart of every simulator's `-timescale` compile option). Commercial-simulator flows (T4) will need the same decision for their own option.
- **Evidence required:** the T1 UVM command with the approved option, errors=0.

## Review findings — static flow review, 2026-11-17

The owner asked on 2026-11-16 for a check of "the flow and things", with freedom to suggest significant changes (`DECISION_LOG.md` D-017). Paths are relative to `poc/apb_uvc/` unless they start with `docs/`.

**Common to RV-001..RV-008**
- Reviewers: Claude (Claude Code session), by reading the sources. The same assistant wrote them, so this is **not** an independent review; APB-006 stays open.
- Reviewed branch and full SHA: `feature/apb-005-passive-reset-apb3-tests` at `b406d6a9c75aca158671f304257ce9a5ba346710` (same tree as `dev`).
- Evidence: reasoning from the cited lines and text searches. **No simulator, compiler, elaborator or lint tool was run**, so every scenario below is NOT RUN and a simulation may refute it.
- Corrective actions are PROPOSED and none is implemented. Fix commit, retest and closure decision: none yet; add them to the finding when it is fixed.

**Overall:** no blocking defect was found by reading. For APB4 traffic that starts on a clock edge, the drive, observe and configuration flows agree with `APB_PROTOCOL_CONTRACT.md`. The findings are about what the UVM tests cannot detect, about reset, and about two conventions that will break the next planned tests.

### RV-001 — UVM tests do not tie the drive path to the observe path
- Status: OPEN
- Severity: MAJOR
- APB revision / width configuration: all
- File(s) and line(s): `tests/apb_poc_scoreboard.sv:36-65`, `tests/apb_poc_env.sv:39-44`, `tests/apb_poc_seqs.sv:28-47`, `hvl/agent/apb_driver.sv:51-62`, `hvl/types/apb_transaction.sv:136-148`
- Requirement / architecture ADR: ADR-001 gates 2 and 3 (isolation, zero silent truncation, round-trip payload); RISK-003; VER-03
- Failing scenario: a change that alters data the same way in both directions still passes `apb_poc_test`. Examples: the drive adapter narrows `wdata`; the driver returns a wrong `rdata` to the sequence. The scoreboard is fed only by the monitor and builds its memory model from the *observed* writes, so it proves that the bus is self-consistent, not that the bus carried what the sequence asked for.
- Evidence: `apb_transaction::do_compare()` is never called; `apb_driver::num_sent` and `apb_monitor::num_observed` are never compared; no sequence or test reads `rdata` from a completed item; the monitor's analysis port is the only one. The HDL smoke test does make these checks (`tests/apb_hdl_smoke.sv:83-95` and `:165-186`), but it calls the BFMs directly, so the HVL adapters, the subject of ADR-001, are not covered by them.
- Corrective action: (1) `apb_driver` publishes each completed item on an analysis port; (2) a comparator in `tests/` matches every completed item with status OK or SLVERR to exactly one observation, in order, with `compare()`, accepts either arrival order within a time step, and at the end of the test requires empty queues and equal counts; (3) the directed sequence checks read-back data against the pattern it wrote; (4) a negative control, for example a drive-proxy double that flips one data bit, proves the comparator fires (VER-03).

### RV-002 — `strb` is encoded differently in a request and in an observation when PSTRB is absent
- Status: OPEN
- Severity: MAJOR (blocks the planned APB2/APB3 integration test)
- APB revision / width configuration: APB2 and APB3, and any instance with `has_pstrb = 0`
- File(s) and line(s): `hvl/types/apb_transaction.sv:69`, `hvl/adapter/apb_drive_proxy.sv:164-168`, `hdl/apb_monitor_bfm_if.sv:229`, `tests/apb_poc_scoreboard.sv:55-57`
- Requirement / architecture ADR: IHI 0024D Table 3-1 (without PSTRB every write is a full-width write); DATA-04 (one encoding); `APB_PROTOCOL_CONTRACT.md` section 6
- Failing scenario: on an instance without PSTRB a write request must carry every lane set (constraint and adapter check), but the monitor reports the same transfer with `strb = 0`. The fixture scoreboard updates its model only on set lanes, so it models no write; once an HDL top ties the fixture's `PSTRB` to `PWRITE`, every read-back mismatches. The RV-001 comparison would also fail on every write.
- Evidence: the cited lines. The two conventions have never met, because every instance in the tests is APB4 with PSTRB.
- Corrective action: the monitor BFM reports every lane set for a write when PSTRB is absent (`{STRB_WIDTH{PWRITE}}`, the Table 3-1 tie-off); state the convention in contract section 6; sample `cp_strb` only when the instance has PSTRB.

### RV-003 — The reset flow does not yet meet RST-2, RST-4 and RST-5
- Status: OPEN
- Severity: MAJOR (design input for the planned reset test; needs the owner's decision on Q5)
- APB revision / width configuration: all
- File(s) and line(s): `hdl/apb_monitor_bfm_if.sv:98-99` and `:259-274`, `hvl/api/apb_monitor_proxy_base.sv:38-40`, `hvl/agent/apb_driver.sv:51-62`, `hdl/apb_driver_bfm_if.sv:196-199`, `examples/apb_hdl_top.sv:39-50`, `tests/apb_poc_scoreboard.sv`, `hvl/coverage/apb_coverage.sv`
- Requirement / architecture ADR: `APB_PROTOCOL_CONTRACT.md` section 5 (RST-2 assertion recognised immediately, RST-4 reset reported through an observe-API event, RST-5 idle after reset); ADR-002 required check on reset and in-flight transfers
- Failing scenarios:
  1. *Reset pulse that does not span a PCLK rising edge.* The driver BFM aborts at once, but the monitor BFM reads `PRESETn` only through its clocking block. It never sees the reset, reports a false `PSEL_DROPPED_IN_ACCESS` or `SETUP_NOT_FOLLOWED_BY_ACCESS`, and counts neither the reset nor the aborted transfer.
  2. *Reset while the driver waits for an item.* `wait_for_reset_release()` runs only at start-up and after an item that ended `RESET_ABORTED`. After a reset that asserts and releases between two items, the next item starts with no `post_reset_idle_cycles`.
  3. *Item requested while reset is asserted.* `do_transfer()` returns `RESET_ABORTED` immediately, so an item that never reached the bus is consumed and not retried. RST-3 only speaks of a transfer in flight.
  4. *No reset information reaches HVL.* The observe API offers `get_reset_count()` only and the BFM's `aborted_count` is not exposed. The fixture clears its memory on reset; the scoreboard model and the coverage cannot follow.
  5. *Tests cannot call `pulse_reset_a/b`.* The UVM tests are in a package, and a package may not contain hierarchical references (IEEE 1800-2017 clause 26.2). Only a module such as `apb_hvl_top` can make that call.
- Evidence: reasoning from the cited lines. One more case to design for: a reset asserted in the same time step as a completing rising edge is a completed transfer for the monitor (it samples before the edge) and `RESET_ABORTED` for the driver.
- Corrective action (depends on Q5; write it into contract sections 5 and 7 before coding): (a) the monitor BFM latches reset asynchronously and consumes the latch at its next sample, so a short pulse is counted and the partial transfer discarded; (b) reset entry and exit are queued in the monitor BFM, delivered through a new blocking observe-API task and published by `apb_monitor` on a separate analysis port; (c) RST-5 is enforced inside the driver BFM (cycles since release), so it also holds between items and for HDL-only users; (d) decide whether an item requested during reset waits for the release (recommended) or aborts; (e) the scoreboard clears its model and the coverage samples the reset phase on the reset event; (f) a reset-control class constructed in `apb_hvl_top` gives tests a legal way to pulse reset.

### RV-004 — The driver BFM can change its outputs between clock edges
- Status: OPEN
- Severity: MINOR
- APB revision / width configuration: all
- File(s) and line(s): `hdl/apb_driver_bfm_if.sv:205-214`, `hvl/agent/apb_driver.sv:55-56`
- Requirement / architecture ADR: APB-R01; `APB_PROTOCOL_CONTRACT.md` section 8 ("drives on the PCLK rising edge"); HDL-05
- Failing scenario: `do_transfer()` is called between two clock edges with `idle_cycles == 0`, for example by a sequence that waits for a delay or an event before its next item (the default constraint gives about one random item in three `idle_cycles == 0`). `repeat (0) @(cb)` does not wait, so the SETUP values are scheduled at the call time and change in the middle of a cycle.
- Evidence: reasoning from the cited lines. The existing tests do not show it, because every item is requested in the time step in which the previous one completed. A Completer that samples on the rising edge still sees one SETUP cycle, so this is a timing-discipline defect rather than a protocol failure in a zero-delay simulation.
- Corrective action: the BFM records the time of the latest PCLK rising edge and `do_transfer()` waits for one `@(cb)` when it is called at any other time; add a directed test with a delay between two items.

### RV-005 — Random traffic never sends sparse strobes, and some implemented behaviour has no test
- Status: OPEN
- Severity: MINOR
- APB revision / width configuration: APB4 and later (strobes); all (policies)
- File(s) and line(s): `hvl/types/apb_transaction.sv:70`, `hvl/sequences/apb_random_seq.sv:4-6` and `:33`, `hvl/coverage/apb_coverage.sv:37-39`
- Requirement / architecture ADR: IHI 0024D 3.2; VER-03; `CLAUDE_GENERATION_PROMPT.md` required checks
- Failing scenario: the transaction's soft constraint makes every write full-width unless a sequence overrides it. `apb_random_seq` does not, although its header says strobes are randomized, so the `STRB_PARTIAL` coverage bin is reached only by the one directed lane-0 write.
- Evidence: the cited lines. Implemented but exercised by no test: POL-01 (unaligned address rejected or allowed), POL-02 (wait-state watchdog, `APB_ST_TIMEOUT`), `allow_x_wdata`, `APB_ST_NOT_ENABLED`, and a DW=8 instance (legal per IHI 0024D 2.1.2; one strobe lane is a corner for the lane arithmetic).
- Corrective action: a knob in `apb_random_seq` for the share of sparse-strobe writes, used when the instance has PSTRB; directed tests for POL-01 and POL-02 (the fixture gives up to 3 wait states, so `max_wait_cycles = 2` trips the watchdog); a DW=8 instance in the HDL top.

### RV-006 — Integration needs 57 named port connections per bus
- Status: OPEN
- Severity: SUGGESTION
- APB revision / width configuration: all
- File(s) and line(s): `examples/apb_hdl_top.sv:60-121`, repeated for instances B and C
- Requirement / architecture ADR: ADR-002 decision 7 and its "second experiment" (harness); ADR-002 acceptance on cross-instance leakage; HDL-02
- Failing scenario: every integrator repeats 26 driver-BFM and 31 monitor-BFM connections per bus. A BFM connected to the wrong bus of the same width compiles, and CFG-06 cannot see it because it compares widths only.
- Evidence: the cited lines; `apb_hdl_top.sv` is 320 lines, 213 of them port connections.
- Corrective action (needs a note in ADR-002 and a wording change in HDL-02): add a small module to the reusable core, for example `hdl/apb_bfm_harness.sv`, with one `apb_if` port, that instantiates both BFMs and makes the connections once. The BFM interfaces keep their ordinary signal ports and still have no interface-typed port, so virtual handles to them stay legal. Integration becomes one `apb_if` and one harness instance, and the same module can be attached to a design with `bind`.

### RV-007 — Smaller consistency items
- Status: OPEN
- Severity: MINOR
- APB revision / width configuration: all
- Items (location, problem, proposed change):
  1. `hvl/types/apb_transaction.sv:54-56` — `c_fit_bus` shifts by the full operand width at run time on AW=32 and DW=32 buses. LANG-05 forbids that pattern and `386e64d` removed it from the adapter; here no tool can warn, because the shift amount is a variable. Proposed: masks computed in `set_bus_context()` and constraints of the form `(addr & ~mask) == 0`.
  2. `hdl/apb_driver_bfm_if.sv:119-137`, `hdl/apb_monitor_bfm_if.sv:119-128`, `hvl/config/apb_agent_cfg.sv:84-98` — the feature-legality rules are written three times and already differ (the monitor BFM has no M2/M3 limit). Proposed: one pure function in `apb_bfm_pkg` that returns an error code, used by all three.
  3. `hvl/agent/apb_agent.sv:29-48` — the agent never sets `uvm_agent::is_active`, so `get_is_active()` answers `UVM_ACTIVE` for a passive agent. Proposed: `is_active = cfg.is_active;` after `validate()`.
  4. `hdl/apb_driver_bfm_if.sv:221-222`, `hdl/apb_monitor_bfm_if.sv:331-336`, `hvl/adapter/apb_monitor_proxy.sv:113` — X/Z on `PSLVERR` at completion is treated as "no error" (status OK) and is not counted; X/Z on `PWDATA` in a strobed lane is not checked (APB-R08, APB-R11, RISK-008). Proposed: two new `apb_mon_error_e` codes, each with a negative test (HDL-08).
  5. `tests/apb_poc_test.sv:29-35` — a UVM fatal, including the global timeout, ends the run before `report_phase`, so no `TEST_RESULT` line is printed and the `UVM_FATAL` term of the count is never reached. Proposed: print the FAIL line from `pre_abort()`; until then a missing line must be read as a failure.
  6. `.gitignore:1` — names `scripts/run_hdl_smoke.sh`, which `40f385b` deleted. Proposed: correct the comment.

### RV-008 — Execution status is repeated in several documents and already disagrees
- Status: OPEN (the resume command, the current-branch pointer and RISK-001 were corrected on 2026-11-17)
- Severity: MINOR
- File(s) and line(s): `README.md:5`; `docs/dv-architecture/APB_PROTOCOL_CONTRACT.md:211`, `:250-253`, `:269`; `docs/dv-architecture/README.md:27`
- Requirement / architecture ADR: DOC-04; handoff precedence in `docs/dv-architecture/AGENTS.md`
- Failing scenario: after the approved elaboration at `386e64d` these lines still say that nothing was compiled, and after pull request #4 `WORK_STATUS.md` still sent the next session to a deleted branch. Every new session has to work out which statement is current.
- Evidence: text search on 2026-11-17.
- Corrective action: keep execution status in `WORK_STATUS.md` only; the README files and the contract link to it and stop restating it; add "update *Resume here* for the state after the merge" to the pre-commit checklist. Two process suggestions for the owner: give a pull request the title of its main change (pull request #4 added the whole UVC under a `docs(dv)` title), and let the installed review bot also review pull requests into `dev` (it skipped #4 because `dev` is not the default branch), which gives a first automatic pass before APB-006.

### Points to watch in the first simulation (not defects)
- Back-to-back transfers in the UVM flow: the IDLE values and the next SETUP values are scheduled in the same time step but in different delta cycles, so a waveform may show a zero-width 1→0→1 pulse on `PSEL` at the completion edge. Values at the clock edges are correct.
- At a completion edge the driver BFM and the monitor BFM each wake on their own clocking-block event; which one runs first is not defined. Nothing depends on the order today (`tests/apb_hdl_smoke.sv:162-163` already drains the monitor after the driver); the RV-001 comparator must accept both orders.

### Question for the owner (not a finding)
- Is emulation-friendliness of the BFMs a goal? The HVL-side proxy split is usually chosen for it, but the BFMs use `fork`/`disable fork`, a named event, a dynamic queue and strings, which emulation flows generally do not accept. If it is a goal, decide before M2 and M3 add more BFM code; if it is not, say so in the contract.

## Closed findings

_None yet._
