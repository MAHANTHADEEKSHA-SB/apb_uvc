# APB UVC — target directory architecture (single-UVC POC)

**Status:** Target layout approved for APB-only proof of concept; exact compilation and BFM wiring require validation.
**Scope:** Exactly **one reusable APB UVC**. The 32-bit and 16-bit configurations (ADR-001 Amendment A1) are two instances of the same UVC, not two UVC products. No AHB, AXI, reset UVC, generic bus framework, or subsystem bridge scoreboard is in this milestone.

## Repository integration

The GitHub repository already contains an older, **flat-layout APB UVC** at its root. Do **not** move, delete, or rewrite that implementation as part of the POC. Put new code under `poc/apb_uvc/`; evaluate migration in a separate approved change.

```text
apb_uvc/                             # existing GitHub repository
├── AGENTS.md                         # directs AI contributors to governance docs
├── docs/
│   └── dv-architecture/
│       ├── README.md
│       ├── AGENTS.md
│       ├── ARCHITECTURE_CONTRACT.md
│       ├── DIRECTORY_ARCHITECTURE.md
│       ├── ADR-001-HVL-PROXY-PLACEMENT.md
│       ├── ADR-002-SEPARATE-DRIVE-OBSERVE-APIS.md
│       ├── CLAUDE_GENERATION_PROMPT.md
│       ├── WORK_STATUS.md
│       └── REVIEW_FEEDBACK.md
├── apb_*.sv                          # original UVC; unchanged by POC
└── poc/
    └── apb_uvc/                      # SELF-CONTAINED, TRANSFERABLE UVC ROOT
        ├── hdl/
        │   ├── apb_if.sv             # signals, modports, optional clocking blocks
        │   ├── apb_driver_bfm_if.sv  # timed APB master drive tasks
        │   └── apb_monitor_bfm_if.sv # passive APB sampling tasks
        ├── hvl/
        │   ├── types/
        │   │   └── apb_transaction.sv
        │   ├── api/
        │   │   ├── apb_drive_proxy_base.sv
        │   │   └── apb_monitor_proxy_base.sv
        │   ├── adapter/
        │   │   ├── apb_drive_proxy.sv
        │   │   └── apb_monitor_proxy.sv
        │   ├── config/
        │   │   └── apb_agent_cfg.sv
        │   ├── agent/
        │   │   ├── apb_driver.sv
        │   │   ├── apb_monitor.sv
        │   │   ├── apb_sequencer.sv
        │   │   └── apb_agent.sv
        │   ├── sequences/
        │   ├── coverage/
        │   └── pkg/
        │       ├── apb_api_pkg.sv
        │       ├── apb_uvc_pkg.sv
        │       └── apb_adapter_pkg.sv
        ├── assertions/               # optional APB protocol assertions
        ├── filelists/
        │   ├── apb_hdl.f
        │   ├── apb_hvl.f
        │   └── apb_poc.f
        ├── examples/
        │   ├── apb_example_slave.sv
        │   ├── apb_hdl_top.sv
        │   └── apb_hvl_top.sv
        ├── tests/
        │   ├── apb_poc_test.sv
        │   └── apb_fault_injection_test.sv
        ├── scripts/
        │   └── run_poc.sh            # add Windows equivalent if needed
        └── README.md                  # consumer integration + build instructions
```

**Directory policy:** Create paths as files are implemented, not empty placeholder folders. The UVC must be deliverable by copying `poc/apb_uvc/` (with UVM/simulator prerequisites documented). The demonstration DUT/top and POC tests are examples shipped alongside the reusable core, **not required by a consumer**.

## Ownership and compile boundary

| Ownership | Compiled / integrated as | What it contains |
|---|---|---|
| `hdl/apb_if.sv` | HDL interface unit | APB signals, modports, optional clocking blocks; no UVM classes and no APB transaction-drive tasks |
| `hdl/*_bfm_if.sv` | HDL interface units | Separate master-drive and passive-monitor timing/handshake tasks; each connected to **one shared** `apb_if` instance |
| `hvl/types` + `hvl/api` | API SV package | Non-parameterized APB transaction representation and separate abstract proxy APIs |
| `hvl/agent` + `hvl/config` | UVM SV package | Non-parameterized UVM driver, monitor, sequencer, agent, cfg |
| `hvl/adapter` | Width-specialized adapter package or compilation units | HVL concrete proxies holding correctly specialized virtual BFM interface handles |
| `filelists` | Build scripts | Explicit actual compilation dependency order; consumer can use HDL/HVL groups |
| `examples` + `tests` | Demo-only | Standalone smoke DUT, two width configurations, directed and negative tests |

SystemVerilog **interface definitions cannot live inside a class/package**. The *deliverable* is one APB UVC repository subtree, not a single `apb_uvc_pkg.sv`. Check package imports and compilation dependencies with the selected simulator; avoid circular package imports.

## Integration model: one UVC, two instances

```text
             APB UVC definition (single reusable codebase)
              ├── Instance A: DW=32, AW=32
              │   apb_if32 ─┬─ apb_driver_bfm_if #(32)
              │             └─ apb_monitor_bfm_if #(32)
              │                   ⇅ typed HVL adapters ⇅ base APIs
              │                      apb_agent_cfg A → UVM agent A
              └── Instance B: DW=16, AW=32
                  apb_if16 ─┬─ apb_driver_bfm_if #(16)
                            └─ apb_monitor_bfm_if #(16)
                                  ⇅ typed HVL adapters ⇅ base APIs
                                     apb_agent_cfg B → UVM agent B
```

One `apb_agent_cfg` per agent instance carries the two **base-class handles**. The integration layer constructs correctly specialized concrete proxies and registers the cfg using scoped `uvm_config_db`. The UVM driver must not import the physical APB interface type. Both BFM interfaces must refer to the **same pin interface instance** within each APB UVC instance. No cross-instance wiring.

## Signal interface versus BFMs

- `apb_if` owns APB pins and port-direction/clocking declarations; BFMs own timed operations and sampling. **Modports do not by themselves solve sampling races.**
- First experiment: BFMs are parameterized **SV interfaces with ordinary signal ports** mapped to `apb_if` signals in `apb_hdl_top`. Do not blindly use an interface-typed port in a BFM interface and then a virtual handle to that interface; ADR-002 documents the portability concern.
- Driver BFM is the active **APB master** for this initial POC. Monitor BFM observes transfers, including when the UVM agent is passive. An active APB subordinate/slave-response BFM is **out of scope**, not forbidden for a future approved extension.
- Do not promise that `UVM_PASSIVE` removes HDL BFM elaboration or compilation; it only changes component behavior. If truly omitting the drive BFM is desired, prove a build/elaboration variant.

## APB POC behavior to specify before code generation

- Identify the supported APB revision and optional pins explicitly (e.g. APB4 `PSTRB`, `PPROT`); don't fabricate APB fields or assume every APB variant includes them.
- Master must implement setup and access phases, hold required signals stable through wait states and sample completion at the valid `PSEL && PENABLE && PREADY` boundary.
- Include APB read and write, back-to-back transfers, inserted wait states, `PSLVERR` reporting if supported, reset and passive observation.
- For `DW`=32 and 16 (and the opt-in DW=64 extension), specify a lossless transaction representation, `PSTRB` relation if supported, and 4-state handling. Do not silently truncate wide data.
- The example slave is a POC fixture and must not be treated as the APB specification itself.

## Scope exclusions for milestone 1

No AHB/AXI/UCIe UVC; no debug bridge; no second protocol agent; no general-purpose environment framework, global common directory, mandatory standalone predictor, or DUT-specific scoreboard in the UVC core. Keep checking in protocol assertions/coverage and standalone example tests. Do not prematurely split every optional feature into independent packages without measured need.

## Validation and handoff

- First produce a dependency diagram, file manifest, and APB-specific acceptance criteria.
- Then incrementally generate and compile HDL interface/BFMs, API, adapters, UVM agent, example top, tests.
- Record exact commands/results in `WORK_STATUS.md`; review findings in `REVIEW_FEEDBACK.md`.
- A 32/16 dual-instance test demonstrates parameter independence; one-UVC deliverability is demonstrated by using only files in `poc/apb_uvc/` plus documented external prerequisites.
- No simulator/emulator support is claimed before actual execution.
