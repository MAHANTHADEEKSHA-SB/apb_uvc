# Architecture contract — single APB UVC POC

**Version:** 0.10 · **Date:** 2026-10-29
**Change in 0.8 (`dev`, PR #3):** toolchain selection and execution gate — no simulator/compiler runs without explicit user approval.
**Change in 0.8 (`feature/apb-001-protocol-contract`):** APB revision scope revised per owner decision (configurable APB2–APB5); protocol detail moved to `APB_PROTOCOL_CONTRACT.md`.
**Change in 0.9:** ADR-001 Amendment A1 (owner-approved) — width pair DW=32 + DW=16; DW=64 kept as a non-standard extension, off by default.
**Change in 0.10:** merge of both 0.8 lines; combined text only, no new decisions.
**Scope:** One reusable **APB UVC** developed under `poc/apb_uvc/`, comprising HDL signal interface, independent drive/monitor BFMs, HVL abstract and concrete proxies, UVM agent, coverage, sequences, filelists and demo. Existing flat-layout APB UVC files at the repository root are **not to be changed** by this milestone.

This contract describes *intended architecture*, not a claim that code has been generated, compiled, simulated or accepted by a simulator. Accepted decisions can change only by a recorded, reviewed ADR amendment. Execution status belongs in `WORK_STATUS.md`.

## Decision states

- **ACCEPTED_FOR_POC:** approved design to test, **not** proven implementation.
- **PROPOSED:** working choice to evaluate before coding.
- **UNRESOLVED:** requires specification, compiler, simulator, or engineering decision.

## ADR-001 — HVL concrete proxies [ACCEPTED_FOR_POC]

1. Use **separate abstract APB drive and monitor proxy APIs** whose types do not depend on the APB pin interface's `AW` or `DW`.
2. Implement concrete HVL proxy classes that specialize on physical bus width and hold correspondingly typed **virtual BFM interface** handles. Do not put concrete UVM class objects inside HDL BFM interfaces.
3. Core UVM driver, monitor, sequencer and agent are **not parameterized by AW/DW**. Demonstrate by creating two configurations of this *same UVC*: AW=32/DW=32 and AW=32/DW=16 (Amendment A1; DW=64 only as an opt-in non-standard extension).
4. Boundaries must reject missing handles, wrong bindings, unsupported widths and information loss. Define 4-state data transport before generation; no implicit casting/truncation.
5. Explicit adapter construction in integration code is preferred for the first POC; factory registration is not a requirement.

## ADR-002 — separate APIs; two BFMs share one signal interface [ACCEPTED LOGIC; WIRING PROPOSED]

1. One `apb_if` per bus instance owns physical signals, modports and optionally clocking blocks. **No protocol drive/receive tasks inside the signal interface.**
2. A separate parameterized **driver BFM interface** owns active APB master drive and handshake tasks.
3. A separate parameterized **monitor BFM interface** owns passive sampling and transfer reconstruction.
4. Both BFMs connect to the **same `apb_if` instance**, not to separate copies of pins. There must be no unintended multiple drivers.
5. Distinct non-parameterized abstract drive and observe proxy classes prevent monitor code using the drive capability through its configured API.
6. One per-instance `apb_agent_cfg` holds both base handles (drive handle optional when passive) and active/passive policy. The integration layer binds and registers cfg with a specific `uvm_config_db#(apb_agent_cfg)` path; the UVM agent retrieves once and passes handles to driver and monitor.
7. Initial BFM implementation: **SV interfaces with ordinary typed signal ports** mapped to shared `apb_if` pins in `examples/apb_hdl_top.sv`. Interface-typed interface ports plus virtual BFM handles are **not assumed portable** under the restriction described in DVCon 2024.
8. The exact monitor-to-HVL transport path and clock-edge scheduling need compile/simulation evidence. Modports alone are insufficient for race-free sampling.
9. Passive APB agent must still observe valid transfers, with no active drive from its agent. Compiling, elaborating, instantiating and activating components are distinct stages.

## APB-only functional scope [PROPOSED; document revision]

- First POC acts as an **APB master agent** with passive bus monitor and an independent, small example slave DUT. A reusable subordinate responder/driver is out of scope for milestone 1.
- **Owner decision 2026-10-29:** one UVC supports APB2, APB3, APB4 and APB5 (ARM IHI 0024D). Revision and optional features are per-instance configuration; unused features stay inactive. Default instance is APB4 with `PSTRB` (`DW/8` bits) and `PPROT`. The revision/feature legality matrix, pin list, reset assumptions and transaction format are defined in [APB_PROTOCOL_CONTRACT.md](APB_PROTOCOL_CONTRACT.md) (PROPOSED).
- **Resolved 2026-10-29 (ADR-001 Amendment A1):** IHI 0024D §2.1.2 allows `DATA_WIDTH` 8/16/32 only, so the demonstration pair is DW=32 + DW=16. DW=64 is a non-standard extension, enabled only explicitly and never reported as APB-compliant.
- Support one APB transfer at a time on each instance. Master drives setup then access, holds mandatory controls/data stable through `PREADY=0` wait states, and finishes only at `PSEL && PENABLE && PREADY`. Observed transaction publication must be aligned to completion.
- Cover read/write, idle, back-to-back, wait-state, reset, and error behavior where the chosen APB revision permits.
- Two widths (32/16) are test instances of **one source implementation**, not two protocol UVCs. Monitor transactions must not be silently narrowed.
- Reset drive/observation behavior must be documented explicitly; do not guess unspecified rules from a separate DUT/bridge project.
- One example slave DUT and tests live under `poc/apb_uvc/examples` and `tests`, distinct from reusable UVC core.
- UVC-local protocol assertions and coverage are allowed. DUT-specific mapping/prediction/scoreboards do **not** belong in this generic APB UVC core.
- No AHB, AXI, UCIe, reset-event UVC, multi-UVC environment or bridge in this phase.

## Packaging and boundaries

`poc/apb_uvc/` is the **reusable delivered unit**. It must carry `hdl/`, `hvl/`, `filelists/`, documentation, and sample integration. Its class packages and HDL interfaces remain **separate SystemVerilog compilation units**: an SV package cannot contain interface declarations.

| Layer in single UVC | Responsibility | Forbidden shortcut |
|---|---|---|
| `hdl/apb_if.sv` | Physical APB signals and modports/clocking | Mix in UVM class API or long drive task library |
| `hdl/apb_driver_bfm_if.sv` | Timed APB master drive | Access wrong interface instance |
| `hdl/apb_monitor_bfm_if.sv` | Passive APB observation | Drive APB pins or construct UVM class objects in HDL |
| `hvl/api/` + `types/` | Non-width-parameterized APB protocol APIs and transaction | Expose typed physical VIF through core UVM classes |
| `hvl/adapter/` | Width-specialized virtual BFM binding and conversion | Silently lose 4-state or upper data bits |
| `hvl/agent/` + `config/` | UVM APB agent and per-instance handle setup | Retrieve arbitrary global config or silently share instance cfg |
| `filelists/` | Separate HDL/HVL/core/demo compile units | Assume runtime `is_active` removes compile load |
| `examples/` + `tests/` | Demo slave, top, acceptance tests | Be mandatory dependencies of a delivered UVC core |

## Toolchain selection and execution gate [ACCEPTED_FOR_POC]

- **No default or automatically approved simulator.** Verilator, Questa, Xcelium, VCS, Icarus and other HDL toolchains are candidate tools, not instructions to execute.
- Before invoking any simulator/compiler for lint, compilation, elaboration, simulation or regression, the implementer must **present the selected tool/version, intended commands, and scope and obtain explicit user approval**. Installed tools, available licences, environment variables, and old conversation suggestions are not authorization.
- Non-executing discovery of available tools and version metadata is allowed; do not launch an unapproved simulator binary even for version discovery. Record an unknown version as **UNKNOWN**, not a guess.
- While toolchain approval is pending, source design and generation, manual/static reviews, package/filelist preparation and proposed test cases may proceed. All unexecuted lint, compile, simulation and regression stages must remain **NOT RUN** in `WORK_STATUS.md`.
- Do not distort a standards-compliant UVM/SystemVerilog architecture to satisfy a limitation of a tool not explicitly approved. After approval, classify failures as source bugs, language/standard violations, or tool limitations, with supporting evidence.
- Approval for one tool/command is not blanket approval for alternative tools or newly introduced execution workflows. Resolve conflicts before execution.

## Build and acceptance gates

1. Manifest and dependency graph are reviewable and consistent with `DIRECTORY_ARCHITECTURE.md`.
2. **After explicit toolchain approval**, a named simulator compiles the **same APB UVC class definitions** for 32-bit and 16-bit APB instances in one test (64-bit only as the optional extension, ADR-001 A1); until then, record NOT RUN.
3. Driver and monitor BFMs share each instance's single signal interface; no conflicting drivers, cross-wiring or invalid virtual interface types.
4. APB setup/access/wait-state behavior and monitor completion sampling pass directed tests; include intentional error/fault injection expected to fail.
5. Passive agent works as observer; tool-specific build variant may be demonstrated separately.
6. Accurate coverage/validation evidence shows tools, version, command, log and Git SHA. **No unexecuted pass claims**.
7. Compare implementation cost against a direct-virtual-interface baseline after a runnable POC. No claims of guaranteed performance or emulation compatibility.

## Unresolved before code generation

- APB revision and concrete signal set; reset polarity and semantics — **proposed** in `APB_PROTOCOL_CONTRACT.md`, awaiting review.
- Exact lossless transaction representation, constraints and 4-state policy for DW=32 and 16 (and the DW=64 extension).
- Detailed port direction/clocking rules; monitor BFM → HVL observation task design.
- Explicit user approval of simulator/toolchain/version and proposed execution commands; UVM version and compilation order of API/UVM/adapter package against interface definitions.
- Whether standalone filelists meet consumer integration requirements.

## Sources and limitations

Public DVCon papers inform the **proxy pattern and alternatives**, not our project names/directory mandates:
- Yun & Zhang (AMD), DVCon 2013, *Deploying Parameterized Interface with UVM*.
- Verhoorn & Baird, DVCon 2018, *Common Challenges and Solutions to Integrating a UVM Testbench in Place of a Legacy Monolithic Testing Environment*.
- Tanvir, Crutchfield & Brosch (Infineon), DVCon 2024, *Working within the Parameters that SystemVerilog has constrained us to*, especially Sections III-C/III-D.

Use original code only; no confidential employer/client IP, no guessed tool validation.
