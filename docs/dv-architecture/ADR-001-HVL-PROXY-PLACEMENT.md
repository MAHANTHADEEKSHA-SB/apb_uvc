# ADR-001 — HVL-side concrete proxy placement

**Status:** Accepted for first proof of concept (revisit after measured results); **amended A1 on 2026-10-29**
**Decision date:** 2026-10-29
**Scope:** One standalone APB UVC POC at `poc/apb_uvc/`; two bus-width instances of the same UVC. This is not a universal rule for other protocols.

## Amendment A1 — width pair (2026-10-29, approved by repository owner)

- **Reason:** ARM IHI 0024D §2.1.2 and Table 2-1 define `PWDATA`/`PRDATA` widths of 8, 16 or 32 bits only, in every APB revision. A DW=64 instance would validate a non-standard interface (`REVIEW_FEEDBACK.md` RISK-007).
- **Change:** the width-independence demonstration uses **AW=32/DW=32 and AW=32/DW=16**. Every "64-bit instance" requirement below now reads "16-bit instance".
- **DW=64 retained as a non-standard extension:** off by default; enabled only by the HDL parameter `ALLOW_NONSTANDARD_DW=1` on the instance and `apb_agent_cfg.allow_nonstandard_width=1`. It may be tested, but it must never be reported as APB-compliant.
- Everything else in this ADR is unchanged.

## Context
For the APB UVC POC, SystemVerilog's parameterized virtual interfaces have specialization-specific types. When drivers, monitors, agents, environments and tests explicitly depend on those types, interface parameters can ripple through the UVM hierarchy. We want a 32-bit and a 16-bit instance (DW=16 per ADR-001 Amendment A1) coexisting in the same simulation with one shared definition of each core UVM component.

## Decision
1. Define non-parameterized, protocol-semantic **drive** and **observe** base APIs on the HVL side. Separate these contracts by capability; a passive monitor should not receive driving privileges by default.
2. Implement **parameterized concrete adapters** in a separate HVL adapter package or set of packages. Each concrete adapter binds a correctly specialized `virtual interface`/BFM handle and translates the common API into BFM operations.
3. Keep parameterized HDL interfaces and BFM tasks/functions in the HDL layer. The HDL layer contains no UVM class objects; any monitor-to-HVL callback/transport arrangement must be reviewed for emulation/tool compatibility, not presumed portable.
4. Non-parameterized UVM drivers/monitors hold base API handles. The integration/top layer creates and configures specialized adapters and fails clearly on missing handles or incompatible width configurations.
5. Start with **explicit construction and typed binding** in top integration, not abstract-class factory registration/overrides. Factory-based selection can be added if a real need arises and UVM/tool support is validated.
6. Record and test transport representation, legal width ranges, 2-state/4-state semantics, and truncation/extension policy. Do not silently truncate.
7. Build 32-bit and 16-bit instances (DW=16 per ADR-001 Amendment A1) concurrently. Verify independent routing, correctness, error cases, and no parameter ripple in core UVM classes.

## Alternatives considered
| Alternative | Benefit | Tradeoff / disposition |
|---|---|---|
| Width-parameterized driver/monitor/agent/env | Simple typed direct VIF; viable for fixed small environments | Parameter propagation; not chosen for reusable POC |
| Non-parameterized maximum-footprint interface | Simple common interface type | Unused signals, potential tie-offs and debug overhead; not chosen |
| Proxy class scoped inside parameterized HDL interface | Local access to HDL parameters without separate typed adapter | Class inside HDL BFM hinders emulation-compatible partitioning; simulation-only option |
| HVL-side parameterized concrete proxy (chosen) | Separation of HDL/HVL and common non-parameterized UVM APIs | Requires explicit instance construction/binding, width adaptation and monitor return path |
| `interface class` alternative | Can express an API contract | Simulator support and HDL binding design must be assessed; may be useful later |

## Architectural boundary
```text
HVL (one APB UVC, two width specializations):
  UVM sequence -> driver -> drive_api_base -> drive_adapter #(DW) --typed virtual BFM--+
  UVM monitor <- observe_api_base <- observe_adapter #(DW) <--monitor transport-------+-- HDL BFM #(DW) <-> DUT pins

  HVL integration top: constructs adapters, binds each exact BFM specialization,
                       routes correct base handles to agent configuration.
HDL:
  Parameterized synthesizable-where-needed driver and monitor BFMs / signal-facing interfaces.
```

## APB UVC deliverable and source/package ownership

The **one transferable UVC** includes all of the following; do not split APB BFMs or pins into global TB directories:

```text
poc/apb_uvc/
  hdl/apb_if.sv                         # physical APB signals/modports
  hdl/apb_driver_bfm_if.sv              # timed master-drive BFM interface
  hdl/apb_monitor_bfm_if.sv             # passive monitor BFM interface
  hvl/types/apb_transaction.sv
  hvl/api/apb_drive_proxy_base.sv
  hvl/api/apb_monitor_proxy_base.sv
  hvl/adapter/apb_drive_proxy.sv
  hvl/adapter/apb_monitor_proxy.sv
  hvl/config/apb_agent_cfg.sv
  hvl/agent/{apb_driver,apb_monitor,apb_sequencer,apb_agent}.sv
  hvl/pkg/{apb_api_pkg,apb_uvc_pkg,apb_adapter_pkg}.sv
  hvl/sequences/
  hvl/coverage/
  filelists/{apb_hdl,apb_hvl,apb_poc}.f
  examples/{apb_example_slave,apb_hdl_top,apb_hvl_top}.sv
  tests/
  README.md
```

The examples and tests demonstrate integration; they are not mandatory for consumers of the APB UVC core. The GitHub repo already has a flat-layout APB UVC: **leave those original files untouched**; this POC lives under `poc/apb_uvc/`. The interface and BFM interface declarations compile as HDL units and are **not placed inside class packages**. Demonstrate DW=32 and DW=16 (DW=16 per ADR-001 Amendment A1) as **two instances of the same source definitions**. Monitor transport, package order and signal port connections require executable validation.

## Contract requirements
- Base APIs express transaction semantics, not arbitrary raw pin pokes unless justified.
- A driver cannot use a raw `virtual interface` directly under this ADR.
- Scoreboards/reference models consume only transaction/event objects, not physical DUT handles.
- Preserve X/Z values where checking requires them; do not blanket-convert to `bit`.
- The monitor must sample race-free according to a documented clocking protocol.
- No silent width clipping, unintended sign extension, or bus instance cross-connection.
- API handle setup and errors must be deterministic and diagnosable.

## Risks and counterarguments
- One more layer increases code and debugging hops. Benchmark against a small direct-VIF implementation.
- The return path from HDL monitor BFM to HVL is **not** solved by simply introducing an observe adapter; choose concrete callback/polling/FIFO approach with the target tools.
- Proxies do **not** automatically yield synthesis/emulation compatibility. Ensure each HDL task/transport construct is supported by the chosen platform.
- Fixed maximum-width transactions are simple but limited. A dynamic or chunked representation may be better for many widths.
- Formal type compatibility still matters; a `virtual if #(32)` cannot substitute for `virtual if #(16)`.

## POC acceptance gates
1. Same core UVM driver/monitor/agent/env/test class declarations serve concurrent 32- and 16-bit instances (DW=16 per ADR-001 Amendment A1).
2. Verified per-instance binding and isolation; swapping physical handles is caught in tests/config checks.
3. Zero silent truncation and correct round-trip payload including width-specific edge cases.
4. Monitor capture works with real simulator; no scheduling races in tests.
5. Lint, compilation, simulation and injected-fault test results are recorded with exact tool versions/logs.
6. Optional-feature filelists demonstrate a reduced compile set without unresolved dependencies.
7. Review exceptions and measured overhead before adopting it for every future UVC.

## References from uploaded DVCon sources
- Wayne Yun and Shihua Zhang, *Deploying Parameterized Interface with UVM*, DVCon 2013: Section III, class abstraction, concrete class associated with parameterized interface, and implementation styles (poster slides 6–10).
- Frank Verhoorn and Michael Baird, *Common Challenges and Solutions to Integrating a UVM Testbench in Place of a Legacy Monolithic Testing Environment*, DVCon 2018: Section II, parameter-agnostic interface proxies and common-width BFM forwarding.
- Salman Tanvir, David Crutchfield and Markus Brosch, *Working within the Parameters that SystemVerilog has constrained us to*, DVCon 2024: Section III-C interface-local polymorphic proxy; Section III-D emulation-compatible HVL concrete proxy and factory-free top-level construction.

*These sources support the alternatives and trade-offs. The exact folder structure, separated drive/observe APIs, and POC gates are our engineering choices, not requirements mandated by the papers.*