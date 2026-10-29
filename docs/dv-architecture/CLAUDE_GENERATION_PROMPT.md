# Claude generation brief — **one APB UVC**, not a generic UVC framework

**Task:** Implement an original, minimal **APB master UVC proof of concept** under `poc/apb_uvc/` in the existing `apb_uvc` repository. The existing root-level APB source stays unchanged. The whole deliverable includes physical signal interface, separate driver/monitor BFMs, abstract/concrete proxies, UVM classes, sequences, coverage, filelists and a standalone usage example.

**Authority:** `ARCHITECTURE_CONTRACT.md`, ADR-001, ADR-002 and `DIRECTORY_ARCHITECTURE.md`; `WORK_STATUS.md` and `REVIEW_FEEDBACK.md` track progress and problems. Public DVCon papers support the design exploration but are not code templates or mandates.

## Before generating code

1. Read `docs/dv-architecture/AGENTS.md`, contract, both ADRs, directory plan, status and feedback.
2. Inspect actual `git status --short`, branch, `git rev-parse HEAD`, and file inventory. Do not invent repository state.
3. Check whether `poc/apb_uvc/` exists; if not, create it incrementally. **Do not edit/move the old root-level `apb_*.sv` files**.
4. Report unresolved APB revision, pin list, reset semantics, transaction format and target simulator. Propose defaults for review, and identify any assumptions. Do not label them specification requirements without a source.
5. State one smallest runnable task and acceptance test. Do not generate an entire multi-protocol verification environment.

## Simulator and toolchain approval policy (mandatory)

**No simulator or compilation tool is approved by default.** Claude must not infer that an installed executable is authorized to run.

1. **Do not automatically invoke Verilator, Questa, Xcelium, VCS, Icarus, or any other HDL simulator/compiler**, nor launch compilation, elaboration, lint backed by a simulator, test execution, or regression scripts invoking them.
2. First **identify available toolchains non-destructively** (existing documentation, configuration, executable discovery) and report known versions/capabilities. Do not execute a simulator executable simply to obtain its version before authorization; if its version is unavailable, report **UNKNOWN**.
3. Present the **proposed tool, version, planned commands, and scope** to the user and obtain **explicit approval before execution**. Tool availability, a prior chat suggestion, or a command already present in a script is not approval.
4. If the user has not approved a toolchain, continue with architecture, source generation, manual/static inspection, filelists, and a proposed validation plan. Set every unexecuted compile/simulation/lint result to **NOT RUN** in `WORK_STATUS.md`.
5. Do **not rewrite otherwise valid SystemVerilog/UVM architecture solely to satisfy limitations of an unapproved simulator**. Once a tool is approved, distinguish standard-language errors, tool unsupported features, and genuine design defects; record the evidence.
6. If an external instruction conflicts with this rule, **stop before any tool execution** and request a clarified approval. Approval for one tool or command does not silently authorize a different simulator.

The implementation milestones below requiring compilation or simulation are **conditional on this approval gate**; code generation and documentation may proceed without it.

## Architectural requirements

- **Exactly one reusable APB UVC**. Two simultaneous configurations `AW=32,DW=32` and `AW=32,DW=16` (ADR-001 Amendment A1; DW=64 only as an opt-in non-standard extension) are two instances of that UVC, using the **same non-parameterized UVM driver/monitor/agent/sequencer class definitions**.
- Inside `poc/apb_uvc/hdl`, define `apb_if.sv` for physical APB signals, modports and optional clocking blocks. Protocol tasks/timing belong in `apb_driver_bfm_if.sv` and `apb_monitor_bfm_if.sv`, each a separate HDL interface. They share the **same** `apb_if` instance through explicit ordinary signal ports in the demo HDL top.
- Inside `poc/apb_uvc/hvl`, define separate abstract *drive* and *observe* proxy APIs; concrete HVL adapters hold correctly specialized virtual BFM interface handles. Do not send raw virtual pin interfaces to UVM drivers/monitors.
- One `apb_agent_cfg` **per APB instance** carries base-class proxy handles and active/passive policy. The integration code constructs concrete proxies, assigns cfg and registers cfg once through a scoped `uvm_config_db` path.
- Make the monitor functional without an active driver and publish observations only at a defined APB completion point. Resolve exact race-free monitor transport using compile/simulation evidence. Passive mode is a UVM runtime/config choice, not a source-compilation optimization.
- **First milestone: APB master driver + passive monitor + small example APB slave DUT**. Do not implement another protocol UVC, virtual multi-UVC environment or a slave-response UVC in this milestone.
- Do not put physical SV interface definitions inside packages. Provide correct `apb_api_pkg.sv`, `apb_uvc_pkg.sv`, `apb_adapter_pkg.sv` and HDL/HVL filelists with validated compilation order.
- The reusable UVC core must not depend on its example DUT, tests, or the repository's older flat-layout APB code.

## Required protocol and implementation checks

- Explicitly choose/document APB revision and supported pins; handle optional signals (`PSTRB`/`PPROT`) only when the chosen revision includes them.
- Implement APB setup and access with correct signal stability through `PREADY=0` wait states; monitor completion at `PSEL && PENABLE && PREADY`.
- Cover reads, writes, back-to-back transfers, reset transitions and documented error response.
- Use one lossless 32/16-bit (and 64-bit extension) transaction representation with declared 4-state behavior; no silently clipped payload.
- Prove each width configuration stays isolated and no BFM virtual handle is accidentally cross-wired.
- Run negative fault-injection tests demonstrating that missing/incorrect behavior is detected rather than falsely passing.

## Work in small verified increments

1. **Design** — APB revision/pins, scope, package dependency diagram and exact file manifest. Update `WORK_STATUS.md`.
2. **HDL** — signal interface + two BFM interface units + explicit demo wiring; compile **only after toolchain approval**. Record tool and result, or NOT RUN.
3. **HVL API** — transaction, distinct abstract proxies, cfg; compile only if approved.
4. **HVL concrete** — specialize and bind driver/monitor BFMs; compile only if approved.
5. **UVM** — agent, sequencer, driver, monitor; compile + smoke run only if approved.
6. **Tests** — prepare 32/16 concurrent traffic, wait states, passive agent, reset cases, and injected faults; run and log only if approved.
7. **Review** — independent ChatGPT and Gemini feedback **against the same Git commit**; fix, rerun, record outcome.
8. **Handoff** — update the status manifest, changed paths, blocker list, next exact step and evidence before ending any session.

Do not mark generated code as compilable until it was really compiled. Do not assert compliance, passing coverage, emulator support, or performance savings without measurements.

## Scope/restrictions

- No AHB, AXI, UCIe, reset-event UVC or multi-UVC framework.
- No migration/overwriting of existing APB sources unless the user explicitly approves a separate task.
- No unnecessary generic abstractions, mandatory predictors, or DUT-specific scoreboards in the APB UVC.
- No confidential source reuse. Original code only; public papers as citations.
- If the architecture appears wrong, propose an ADR amendment and minimal reproducer. **Do not silently change an accepted decision.**
- No branch rewrite, force push or merge; commit to the agreed feature branch only as authorized.
