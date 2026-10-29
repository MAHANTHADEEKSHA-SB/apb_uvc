# ADR-002 — Separate abstract drive and observe APIs

**Status:** Logical architecture selected for POC; BFM wiring still requires simulator validation
**Date:** 2026-10-29
**Depends on:** ADR-001 (HVL-side concrete proxies)

## Context
Our parameter-independent UVC must support active and passive instances, preserve a clear HDL/HVL boundary, and enable distinct bus-width specializations (32 and 64 bits initially). A monolithic proxy can expose both drive and observe operations, whereas two narrowly scoped APIs can enforce separation by capability. Neither placement nor number of API classes automatically solves the monitor data transport problem.

## Decision
1. Use separate **non-parameterized abstract drive and observe API classes** for each protocol UVC. The driver receives only the drive API; the monitor receives only the observe API.
2. Keep **parameterized concrete HVL adapters** per API and protocol BFM specialization, using a correctly typed virtual-interface/BFM handle in each adapter.
3. Use **one parameterized pin/signal interface** shared by **two BFMs**, one driver BFM and one monitor BFM. The pin interface holds signals, relevant modports and, if useful for race control, clocking blocks; it does **not** own protocol-drive/sample tasks. Those tasks and timing logic live in the respective BFMs.
4. Prefer BFM units implemented as SystemVerilog **interfaces**, so each HVL concrete adapter can hold a typed `virtual driver_bfm_if#(...)` or `virtual monitor_bfm_if#(...)` and call its tasks. A BFM implemented as a **module** does not automatically support this virtual-interface calling pattern; it would need a separate API/transport mechanism.
5. Use one **non-parameterized per-instance configuration object** to carry respective abstract handles and protocol configuration (e.g. active/passive, supported capabilities, logical instance name). Do not create an inherited common API solely to share configuration.
6. In passive mode, do not construct or bind the drive adapter unless needed by a specific supported mode; the monitor/observe adapter remains functional. In active mode, the agent creates driver/sequencer and monitor as appropriate.
7. Define monitor observation as a blocking `sample_transaction(output txn)` task or a validated callback/queue mechanism; select transport based on simulation/emulation/tool evidence. Avoid putting an unbounded `forever` loop inside an analysis `write()` function.
8. API calls are protocol-semantic where practical; pin-level helpers can exist if timing or reactive response requires them, but must be documented and tested.
9. Both API classes have explicit unbound/unsupported-operation failure semantics. Validate width, 4-state data preservation, per-instance isolation, and event ordering.
10. This is a **project-level default** for reusable protocol UVCs, not a mandate for every status flag, assertion checker, or trivial interface.

## BFM-to-pin-interface connection: important separate decision

Section III-D and Figures 13–16 of Tanvir, Crutchfield & Brosch (DVCon 2024) discuss the same logical combination: a signal interface, driver/monitor BFMs, HVL concrete proxies and non-parameterized base APIs. Their paper flags an IEEE 1800-2017 restriction: if a BFM **interface** has a port referencing another interface, creating a **virtual interface handle to that BFM interface** is not legal under the restriction cited. The authors report successful use in their tools despite warnings and propose a harness/upwards-reference variant. Therefore **do not treat `interface drv_bfm(bus_if.driver_mp pins)` + `virtual drv_bfm vif` as validated portable code.**

For the initial proof of concept we propose **BFM interfaces with ordinary typed signal ports** (individual inputs/outputs, not an interface-typed port), explicitly mapped to the shared signal interface in the HDL top. This adds wiring boilerplate but avoids the specific interface-port/virtual-interface issue. Signal connection directions must be checked. As a second experiment, explore the published harness/bind arrangement on the target simulator/emulator. Neither variant is claimed validated until it compiles and runs on our target tool.

## Configuration and ownership flow

1. HDL top elaborates `bus_if#(AW,DW)`, `bus_driver_bfm_if#(AW,DW)`, and `bus_monitor_bfm_if#(AW,DW)`; both BFMs connect to the **same** signal interface instance.
2. The HVL integration layer constructs one specialized concrete drive proxy and one specialized concrete observe proxy per agent instance and binds them to the corresponding **BFM virtual interface** types (not the raw `bus_if`).
3. Those concrete objects are assigned through polymorphism to two **base API handles** inside one per-instance `bus_agent_cfg` object.
4. The integration layer registers **the configuration object once** using `uvm_config_db#(bus_agent_cfg)::set` with an exact agent instance path before build-phase retrieval. The agent calls `get` once and passes the drive handle to its driver and observe handle to its monitor. Avoid redundant database lookups in every child.
5. For passive use, an observe-capable monitor always remains valid, while the driver BFM and driver component must not drive. If the physical driver BFM should be excluded entirely, that is an HDL elaboration/generate and build-filelist decision, **not** something `UVM_PASSIVE` accomplishes on its own.
6. **Monitor BFM code returns sampled value types/packed structs**, and the HVL layer constructs UVM class transactions. Avoid placing UVM class construction inside HDL BFMs when emulation compatibility matters.
7. The BFM sampling/driving schedule must be race-free; determine whether clocking blocks belong with pin declarations or BFM wrappers. Modports define access direction; they do not by themselves solve scheduling races.

## Alternatives and trade-offs
| Alternative | Benefits | Risks | Decision |
|---|---|---|---|
| Single drive+observe abstract proxy | Simpler class and wiring count; suitable for tiny BFMs | Too-wide API; passive code can call drive operations; difficult capability isolation | Not default |
| Separate drive and observe base APIs | Explicit responsibility and access control; flexible active/passive UVC; smaller contracts | Two adapters and two bindings; possible duplicated mechanics | **Chosen** |
| Hybrid common base plus specialized APIs | Shared metadata and optional capability type | Unnecessary inheritance, extra casts and API complexity for this POC | Defer until needed |

## Conceptual source layout
```text
uvc/simple_bus/
  item/simple_bus_txn.sv
  config/simple_bus_agent_cfg.sv
  api/simple_bus_drive_api.sv
  api/simple_bus_observe_api.sv
  adapter/simple_bus_drive_adapter.sv
  adapter/simple_bus_observe_adapter.sv
  agent/simple_bus_driver.sv
  agent/simple_bus_monitor.sv
  agent/simple_bus_agent.sv
  pkg/simple_bus_api_pkg.sv
  pkg/simple_bus_uvc_pkg.sv
  pkg/simple_bus_adapter_pkg.sv

tb/interfaces/simple_bus_if.sv  # physical signals/modports/optional clocking
tb/bfm/simple_bus_driver_bfm_if.sv  # driver tasks; signal-level bus access
tb/bfm/simple_bus_monitor_bfm_if.sv # monitor tasks; signal-level sampling
tb/top/hdl_top.sv
tb/top/hvl_top.sv
```

### Sketch, not production code
```systemverilog
virtual class bus_drive_api;
  pure virtual task send(bus_txn req);
endclass

virtual class bus_observe_api;
  pure virtual task receive(output bus_txn observed);
endclass

class bus_agent_cfg extends uvm_object;
  bus_drive_api drive_handle;
  bus_observe_api observe_handle;
  uvm_active_passive_enum is_active = UVM_ACTIVE;
endclass
```
`receive()` is intentionally a **task** to permit time-consuming monitor sampling; it must allocate/fill distinct transaction objects and use a validated BFM clocking strategy. Adapt these class definitions to actual package/import and constructor requirements before compiling.

## BFM-specific acceptance criteria

- Driver and monitor BFM interfaces share **the same** physical signal interface instance, not copies.
- Compile the selected BFM-to-signal connection form on the actual simulator. For the first POC use ordinary signal ports to avoid the IEEE restriction flagged in DVCon 2024.
- Check that there is exactly one intended driver of every direction-controlled bus signal, and no drive activity while configured passive.
- Confirm monitor can observe a transfer even while the driver BFM is disabled/omitted.
- Verify correctly specialized virtual BFM interface types are connected to the corresponding concrete proxy, with no cross-instance leakage.
- Document whether the HDL BFM interface port technique and/or harness variant passes the intended emulation flow; do not infer emulation support from SV simulation alone.

## Required checks before acceptance
- Concurrent 32-bit and 64-bit instances using the same non-parameterized agent/driver/monitor class definitions.
- Passive instance has no constructed driver/sequencer and no usable drive handle, but observes transfers correctly.
- A driver cannot invoke observe-only operations; a monitor cannot invoke drive-only operations through its API types.
- Drive and observe adapters bind to the intended physical BFM instance; intentional cross-wiring is detected.
- Race-free monitor collection and correct 2-state/4-state behavior for all supported widths.
- Reset and transaction observation contracts documented, including in-flight transfers.
- Compile, simulation, injected-fault tests and exact tool versions recorded. No assertion of emulator support without testing.
- Code-size/build-time tradeoff compared against one combined-proxy proof of concept, at least qualitatively.

## Challenges / limits
- Separate APIs do not imply two DUT interfaces or two HDL clocks. **Our chosen decomposition explicitly uses two BFM units sharing one signal interface.**
- Capability segregation is by the **type of handle**; any code with access to the concrete BFM may still be able to drive it. This is not a security boundary.
- A shared configuration object must not become a global singleton: each UVC instance gets its own binding and policy.
- A separate monitor API does not guarantee emulation-compatible callbacks. Determine exact transactor transport on the target tool.
- Some protocols require a reactive responder that both observes incoming handshakes and drives replies; structure it as a suitable drive-capable reactive agent rather than prohibiting mixed interactions.

## Source basis and originality
- DVCon 2013, Yun & Zhang, *Deploying Parameterized Interface with UVM*, Section III and slides 6–10: abstract access class/concrete adapter, different abstraction levels, and a combined drive/monitor API example.
- DVCon 2018, Verhoorn & Baird, *Common Challenges and Solutions...*, Section II: parameter-agnostic proxy and BFM forwarding.
- DVCon 2024, Tanvir, Crutchfield & Brosch, *Working within the Parameters...*, Sections III-C/III-D: interface-local and HVL-side concrete proxy alternatives.

**The separate drive/observe split, the shared per-instance configuration, the explicit-signal-port POC connection style, and the recommended file layout are our engineering decisions, not directives mandated by those papers.**