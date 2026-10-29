# Reusable SystemVerilog/UVM testbench architecture — design review v0.2

Status: **PROPOSED; not frozen**. This is a project design proposal, not a directory structure mandated by DVCon.

## 1. Principles and constraints

- Primary goal: reusable, understandable IP-to-subsystem verification, with explicit dependencies and selectable agents.
- Prevent unnecessary parameter ripple *when varying physical interface widths*. Do not ban parameterization everywhere: it may be appropriate for strongly typed components or performance reasons.
- BFMs/interface access live below UVM driver/monitor. Scoreboards and reference models consume transactions/events and have no direct pin/virtual-interface dependencies.
- Full UVC is **per meaningful protocol/interface**, not per individual signal. Use lightweight monitors, assertions, or event agents for standalone status/interrupt/reset signals.
- A separate predictor is **optional**: a deterministic one-to-one transformation can live in a pure helper called by scoreboard input `write_*`; stateful prediction is a reason to consider separate model ownership.
- Group related behavior in a common scoreboard; separate independent functions. Avoid monolithic scoreboards when feature-specific checkers improve clarity.
- Do not invent reset behavior. Define acceptance vs completion, partial transfers, pending-drain/abort/retention, reset-domain ownership, and callback ordering from the DUT specification.
- Compiled files and enabled components are two **different** concerns. A factory/config flag can prevent elaborating UVM objects, but does not in general remove compiled source from a compilation; optional compile filelists/packages are required for actual compile-load savings.

## 2. Proposed repository layout

```text
project/
├── README.md
├── docs/
│   ├── requirements/                 # DUT contracts, acceptance, reset, ordering
│   ├── architecture/                 # decisions, dependency diagram, alternatives
│   ├── verification_plan/            # feature -> tests/assertions/coverage traceability
│   └── references/                   # citations/links, no copied proprietary content
├── rtl/                              # example/mock DUT for public POC only
├── tb/
│   ├── common/                       # shared transaction types and utilities
│   ├── interfaces/                   # HDL interfaces (parameterized as needed)
│   ├── bfm/                          # signal-level drive/sample operations
│   ├── bind/                         # protocol SVA bind files, if needed
│   └── top/                          # HDL and HVL top / connection logic
├── uvc/
│   ├── simple_bus/
│   │   ├── item/                     # non-width-specific semantic transaction
│   │   ├── api/                      # abstract drive/observe access contracts
│   │   ├── adapter/                  # concrete specialization + virtual interface
│   │   ├── agent/                    # driver, monitor, sequencer, agent, cfg
│   │   ├── sequences/                # bus-level stimulus
│   │   ├── coverage/                 # only when enabled
│   │   └── pkg/                      # compilation unit / package
│   └── reset_events/                 # lightweight observer if needed
├── env/
│   ├── config/                       # environment composition & connections
│   ├── scoreboards/                  # packet/event-only comparison
│   ├── reference_models/            # optional stateful predictor
│   ├── coverage/                     # subsystem cross coverage
│   ├── virtual_sequences/            # scenario coordination
│   └── ral/                          # optional RAL
├── tests/                            # UVM tests
├── sim/
│   ├── filelists/                    # core.f, simple_bus.f, reset.f, ral.f etc.
│   ├── scripts/                      # lint/compile/elaborate/run invocation
│   └── waivers/                      # reviewed, documented exceptions
├── tools/                            # optional architecture checker and helpers
├── regress/                          # smoke and configuration matrices
├── ci/                                # CI jobs when available
└── results/                           # generated; gitignored
```

Folders need only be created when used; avoid empty scaffolding. Adapt names to project conventions. Keep HDL/HVL compile order in filelists and don't rely on directory order.

## 3. Logical connection diagram

```text
[AHB or other interface] -> [monitor/proxy] -> [transaction] ---+-> [scoreboard input]
[debug output interface] -> [monitor/proxy] -> [transaction] ----+-> [scoreboard actual]
[reset/status observer]   -> [reset event] ----------------------+-> [lifecycle check]

[sequences] -> [sequencer] -> [driver (base API)] -> [concrete adapter] -> [BFM] -> DUT

Expected-path: scoreboard helper (simple mapping) OR separate predictor (stateful mapping)
```

The scoreboard is packet/event-only; the reset monitor may be signal-aware. A protocol monitor's publication point must be specified; AHB address acceptance and completed data-phase transfers are not interchangeable.

## 4. Dependency and compile strategy

1. Build packages from base semantic items and abstract access APIs.
2. Compile HDL interfaces/BFMs and protocol assertion modules.
3. Compile concrete adapter specializations requiring virtual interfaces.
4. Compile core UVC agent classes and optional UVC features.
5. Compile environment and whichever checkers/models are enabled for this target.
6. Compile tests and TB tops, then elaborate and run.

Exact order depends on imports/package includes and simulator; package/specialization boundaries must be proven with a real compile.

Example filelist partition:

```text
sim/filelists/common.f
sim/filelists/simple_bus_core.f
sim/filelists/simple_bus_coverage.f   # optional
sim/filelists/reset_observer.f       # optional
sim/filelists/bridge_env.f
sim/filelists/bridge_tests.f
```

Selection happens **before compilation** at script/filelist level. Runtime `is_active` controls agent behavior, not source compilation.

## 5. Design-review decisions

| ID | Item | Draft choice | Status / reason |
|---|---|---|---|
| ADR-001 | Adapter pattern | Nonparameterized drive/observe APIs + parameterized HVL concrete adapters + HDL BFM | Accepted for POC; see ADR-001-HVL-PROXY-PLACEMENT.md. Revisit after compiler/emulator evidence |
| ADR-002 | Driver/monitor APIs | Distinct base APIs | Proposed. Avoid active drive methods leaking into passive monitors |
| ADR-003 | Transaction encoding | Maximum-width vector with explicit active-width validation for POC | Proposed. Alternative: dynamic byte arrays for unbounded widths; protect X/Z capture |
| ADR-004 | Predictor placement | No dedicated predictor for stateless one-to-one transform | Proposed. Helper function in scoreboard; re-evaluate for state/config/ordering |
| ADR-005 | Scoreboard partition | By related functionality, not per UVC | Proposed. Consider separate feature checkers for larger blocks |
| ADR-006 | Reset | Entirely DUT-spec-defined | Required. No inference from name `reset` alone |
| ADR-007 | Optional UVCs | Modular filelists + target-specific env construction | Proposed. Avoid compiling unused optional feature packages when possible |
| ADR-008 | POC scope | 32-bit and 64-bit concurrently on a simple mock bus | Proposed. Demonstrate multi-instance independence before real protocols |
| ADR-009 | Verification evidence | Compiler and runnable tests required | Required. AI agreement != proof |

## 6. Risks / unanswered questions before implementation

- Which simulator/UVM version is the first supported target?
- Which physical widths need true 4-state preservation? What is the upper bound?
- Can multiple traffic streams share one common transaction type without semantic loss?
- Does reset affect inputs, outputs, buffers, clocks, or independent domains?
- When does the monitor publish a packet? For AHB, define address/data acceptance and transfer completion separately.
- Does an output transaction always map one-to-one, in order, or can it be combined/retried?
- How will optional adapters/packages avoid compile-time circular dependencies?
- How are findings waived and tracked in Git?

## 7. Public technical background

- DVCon 2013, Yun & Zhang, *Deploying Parameterized Interface with UVM*: abstract/concrete interface adaptation and transaction independence.
- DVCon 2018, Verhoorn & Baird, *Common Challenges and Solutions...*: parameter-agnostic proxy interface, instance registration, and parameter-specific BFM mapping.
- DVCon 2024, Tanvir et al., *Working within the Parameters that SystemVerilog has constrained us to*: parameter ripple, emulation-compatible adapter relocation, factory/coverage tradeoffs.

These papers inform the evaluation; they do not dictate our entire directory hierarchy.

## ADR-002 addendum: physical interface vs BFMs

The selected POC has **one signal interface** plus **two BFM interfaces** per active protocol instance. Driver BFM owns driving tasks; monitor BFM owns passive collection. HVL drive/observe adapters point to their respective BFM virtual interfaces. A single per-agent cfg carries base-class handles and is registered through `uvm_config_db`.

**Important IEEE limitation:** Do not pass `bus_if.some_modport` as an interface-typed port of an interface BFM and then assume `virtual driver_bfm_if` is portable. DVCon 2024 III-D cites a restriction on declaring virtual interfaces for interfaces that themselves reference other interfaces through ports. The proposed POC uses explicit ordinary signal ports on BFM interfaces; the harness/bind alternative is a separate tool-validation experiment.

```text
tb/interfaces/example_bus_if.sv          # signals, modports, optional clocking blocks
tb/bfm/example_bus_driver_bfm_if.sv      # task-based driving interface
tb/bfm/example_bus_monitor_bfm_if.sv     # task-based sampling interface
uvc/example_bus/proxy/*                  # two abstract APIs + two concrete HVL adapters
uvc/example_bus/config/*                 # one per-agent cfg containing base handles
```