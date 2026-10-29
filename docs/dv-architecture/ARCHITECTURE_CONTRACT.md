# Architecture contract — parameter-independent UVM POC

**Contract version:** 0.6 (2026-10-29)
**Purpose:** Stable cross-model decision record. This is **not** a complete DUT specification.
**Change policy:** Accepted rules may be amended only with a recorded decision, rationale, impact, and user approval. Work progress belongs in `WORK_STATUS.md` instead.

## Decision status legend

- **ACCEPTED_FOR_POC** — agreed for the proof of concept, still subject to measurements and executable validation.
- **PROPOSED** — current preference, may change after evidence/review.
- **UNRESOLVED** — spec/tool decision required before implementation is claimed complete.

## Accepted for POC (not universal UVM laws)

**ADR-001 — HVL-side concrete proxies [ACCEPTED_FOR_POC]**
- Keep drivers, monitors, agents, environment, and tests free of *interface-width parameter ripple*; verify this with simultaneous 32-bit and 64-bit instances.
- Use width-independent abstract APIs on HVL side and width-specialized concrete adapters on HVL side; BFM virtual interface types remain correctly specialized.
- Explicit per-instance binding in the integration layer. No mandatory factory-based creation of concrete proxies.
- Do not silently clip/extend transaction data. Explicitly select the logical transaction transport format and 4-state requirements.
- Scoreboards/reference models work at packet/event level, not via direct DUT virtual-interface access.
- Exceptions are possible but must be justified and reviewed, not hidden.

**ADR-002 — two capability APIs and two BFMs [LOGICAL_DESIGN_SELECTED, PHYSICAL_WIRING_UNRESOLVED]**
- Separate *abstract drive* and *abstract observe* APIs; UVM driver sees drive API only; UVM monitor sees observe API only.
- Two separate low-level BFMs (drive and monitor) share **one physical signal interface instance**. The interface owns signals/modports and possibly clocking blocks; BFMs own drive/sample protocol tasks and timing.
- Two parameterized concrete HVL adapters bind typed handles to their respective BFMs.
- Per-instance `bus_agent_cfg` holds the two abstract handles and active/passive configuration. Integration/top constructs concrete adapters and sets config; agent gets config once and passes handles to children.
- Passive mode must not drive. Distinguish simulator compilation, HDL elaboration and UVM component creation.
- A reactive subordinate driver can legitimately sample request/handshake signals: 'drive API' means authority to respond, **not** a prohibition on all reads.

## Proposed POC physical wiring [PROPOSED — NEEDS COMPILER TEST]

- Implement driver and monitor BFMs as parameterized SV **interfaces**, each exposing tasks, attached through **ordinary signal ports** to the same shared pin interface in `hdl_top`.
- This avoids a known virtual-interface portability concern when one interface contains a port referencing another interface (see 2024 DVCon Section III-D). Do **not** generate `interface drv_bfm(bus_if.mp pins)` plus a virtual handle to drv_bfm and assert it is portable.
- Alternative harness/bind wiring may be explored in a separate comparison experiment.
- If module BFMs are proposed instead, describe a valid callable transport path; a module instance is not a virtual interface.
- Actual emulation compatibility is **UNRESOLVED** until emulation tools validate the chosen HDL/HVL transport.

## Other working defaults (reviewable, not fixed by DVCon)

- A simple deterministic translation can live in a scoreboard `write_*()` helper; a standalone predictor is optional. Separate stateful prediction when complexity/reuse requires it.
- Group related features in one scoreboard where this remains maintainable; split unrelated features into separate checkers/scoreboards.
- Build a UVC per meaningful protocol/interface when justified, not one full agent for every individual status bit. Use simple monitor/assertion where sufficient.
- A monitor must publish transactions at a **defined handshake/acceptance boundary**. Any reset policy must follow a written DUT reset contract; never assume all pending transactions flush or drain.
- Packages and filelists separate optional UVCs so unused verification code can be **omitted from compilation**. `is_active` alone is a runtime behavior choice.

## Component ownership

| Layer | Owns | Must not silently do |
|---|---|---|
| `tb/interfaces` | Pins, modports, optional clocking blocks | Hide significant protocol sequencing in undocumentable top glue |
| `tb/bfm` | Timed driving/sampling and signal-level protocol operations | Construct UVM transactions in synthesizable/emulation-target code |
| `uvc/*/api` | Width-independent drive/observe contracts | Expose wrong-capability operations |
| `uvc/*/adapter` | Typed BFM binding and width/representation conversion | Silently truncate or bind wrong physical instance |
| `uvc/*/agent` | UVM driver, monitor, sequencer and instance configuration | Depend unnecessarily on physical bus widths |
| `env/scoreboards` | Expected/actual matching and transaction-level checks | Sample raw DUT pins |
| `env/reference_models` | Complex stateful prediction if needed | Duplicate DUT implementation as oracle |
| `sim/filelists` | Build-dependent source selection | Always compile unused optional UVCs without justification |

## Open technical decisions [UNRESOLVED]

- Chosen transaction payload representation for widths beyond 64 bits (fixed maximum, bytes, packed chunks, or another format), plus X/Z semantics.
- Monitor BFM → HVL adapter delivery mechanism and event ordering (polling, task call, FIFO, callback, etc.).
- Clocking block location, race-free sampling/driving, and reset synchronization.
- Exact simulator, UVM library, supported package order and versioned compilation commands.
- Whether the optional high-level compile partitions provide measurable build/runtime savings.
- Official protocol-specific reset/handshake rules once a real bus is selected.

## POC acceptance criteria

1. Two simultaneous interface specializations: 32-bit and 64-bit, same source definitions for core UVM components.
2. Correct independent routing through two BFM interface pairs to two physical pin interfaces; intentional binding failures are reported.
3. Passive-mode observe path works; no driving activity; optionally omit drive-side sources where build supports it.
4. Directed data integrity, width edges, reset, and relevant handshake cases; deliberate DUT fault injection causes test failure.
5. Lint is informative, but **compiler + simulator + logs** establish actual execution evidence; log tool versions.
6. All claimed features have requirements, test names, and concrete results. No untested emulator claims.

## Background references and limits

- DVCon 2013, Wayne Yun / Shihua Zhang, *Deploying Parameterized Interface with UVM*: class abstraction and parameter-specialization alternatives.
- DVCon 2018, Frank Verhoorn / Michael Baird, *Common Challenges and Solutions to Integrating a UVM Testbench in Place of a Legacy Monolithic Testing Environment*, Section II: parameter-agnostic proxy/BFM adaptation.
- DVCon 2024, Salman Tanvir / David Crutchfield / Markus Brosch, *Working within the Parameters that SystemVerilog has constrained us to*, Sections III-C and III-D: polymorphic interface, HVL adapters, and HDL/HVL separation.

These are public technical references. **Specific directory choices and separated APIs are project decisions, not DVCon mandates.** Respect confidentiality, copyright licences and applicable patent obligations.