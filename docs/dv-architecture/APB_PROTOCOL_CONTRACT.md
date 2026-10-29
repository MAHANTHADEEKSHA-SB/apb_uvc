# APB protocol contract — APB-001 (single APB UVC POC)

**Status:** PROPOSED — defaults for review; no SV source generated or compiled against this contract yet.
**Date:** 2026-10-29
**Task:** APB-001 (`WORK_STATUS.md`)
**Normative source:** Arm *AMBA APB Protocol Specification*, ARM IHI 0024D (ID041221, 09 April 2021), referred to below as **[IHI]**. The PDF is Arm copyright and is not stored in this repository.

## How to read this document

Every rule carries one of three tags. Only **[IHI §x]** rules are protocol requirements.

| Tag | Meaning |
|---|---|
| **[IHI §x]** | Requirement or definition taken from the cited section/table of IHI 0024D |
| **[ASSUMPTION]** | Our proposed default where IHI 0024D is silent; must be approved, may change |
| **[DECISION]** | Project decision already taken by the repository owner |

---

## 1. Revision strategy

- **[DECISION 2026-10-29]** One APB UVC must be usable for **APB2, APB3, APB4 and APB5** interfaces. Every feature exists in the UVC; an instance enables only what its interface has. Unused features stay inactive.
- **[DECISION 2026-10-29]** Default instance configuration is **APB4** with `PSTRB` and `PPROT` present.
- The revision names are defined by [IHI Preface, "APB Revisions"]: APB2 = AMBA 2 (IHI 0011A), APB3 = Issue B (adds `PREADY`, `PSLVERR`), APB4 = Issue C (adds `PPROT`, `PSTRB`), APB5 = Issue D (adds wake-up, user signals, parity).

### Proposed mechanism [ASSUMPTION]

1. `apb_if` declares the **APB5 superset** of pins from [IHI Table B-1] and [IHI Table B-2]. Widths remain SV parameters, so this is *not* the "maximum-footprint interface" rejected by ADR-001; only feature pins are a superset.
2. **Feature presence is per-instance runtime configuration** in `apb_agent_cfg` (revision + per-feature flags), validated against the legality matrix in §2 before the run phase. The same compiled image can therefore test an APB3 and an APB4 completer.
3. The configuration is pushed down to both BFMs through the proxies (a `configure()` call at start of simulation), so HDL drive/sample code knows which pins are live.
4. Absent **Requester outputs** are driven to 0 ([IHI A.1]: signals not required to be valid are recommended driven to zero). Absent **Completer inputs** are replaced inside the monitor/driver BFMs by the defaults of [IHI Table B-1] ("Optional signals have a default that should be used for any un-driven inputs"): `PREADY`=1, `PSLVERR`=0, `PPROT`=0b000.
5. SV cannot declare zero-width ports, but [IHI §2.1] defines width property 0 as "signal not present". Physical user-signal widths are therefore `max(W,1)` with a separate presence flag.

---

## 2. Feature / signal legality matrix

Codes from [IHI Table B-1/B-2]: **Y** mandatory, **N** must not be present, **O** optional, **OO** optional for output ports and mandatory for inputs, **C** must be present if property True, **OC** optional but only if property True.

The UVC is a **Requester** (master). "OO" therefore means: our Requester always has the input; if a Completer lacks the output, the integrator ties the input to the default.

### 2.1 Base and optional signals [IHI Table B-1]

| Signal | Width | Dir (Requester view) | Default | APB5 | APB4 | APB3 | APB2 | `apb_agent_cfg` control |
|---|---|---|---|---|---|---|---|---|
| `PCLK` | 1 | in | — | Y | Y | Y | Y | — |
| `PRESETn` | 1 | in | — | Y | Y | Y | Y | — |
| `PADDR` | `ADDR_WIDTH` | out | — | Y | Y | Y | Y | — |
| `PPROT` | 3 | out | 0b000 | O | O | N | N | `has_pprot` |
| `PSELx` | 1 per Completer | out | — | Y | Y | Y | Y | — |
| `PENABLE` | 1 | out | — | Y | Y | Y | Y | — |
| `PWRITE` | 1 | out | — | Y | Y | Y | Y | — |
| `PWDATA` | `DATA_WIDTH` | out | — | Y | Y | Y | Y | — |
| `PSTRB` | `DATA_WIDTH/8` | out | — | O | O | N | N | `has_pstrb` |
| `PREADY` | 1 | in | 0b1 | OO | OO | OO | N | implied by revision (≥APB3) |
| `PRDATA` | `DATA_WIDTH` | in | — | Y | Y | Y | Y | — |
| `PSLVERR` | 1 | in | 0b0 | OO | OO | OO | N | implied by revision (≥APB3) |
| `PWAKEUP` | 1 | out | — | C (`Wakeup_Signal`) | N | N | N | `has_pwakeup` |
| `PAUSER` | `USER_REQ_WIDTH` | out | — | OC | N | N | N | `user_req_width` (0 = absent) |
| `PWUSER` | `USER_DATA_WIDTH` | out | — | OC | N | N | N | `user_data_width` (0 = absent) |
| `PRUSER` | `USER_DATA_WIDTH` | in | — | OC | N | N | N | `user_data_width` |
| `PBUSER` | `USER_RESP_WIDTH` | in | — | OC | N | N | N | `user_resp_width` (0 = absent) |

### 2.2 Parity check signals [IHI Table B-2, Table 5-1]

Present only on APB5 with `Check_Type = Odd_Parity_Byte_All` ([IHI §5.2]; Check_Type False/undeclared means no check signals). `apb_agent_cfg` control: `check_type` ∈ {`APB_CHECK_NONE`, `APB_CHECK_ODD_PARITY_BYTE_ALL`}.

| Check signal | Covers | Width | Dir | Check-enable term [IHI Table 5-1] | Presence |
|---|---|---|---|---|---|
| `PADDRCHK` | `PADDR` | ceil(`ADDR_WIDTH`/8) | out | `PSEL` | C |
| `PCTRLCHK` | `PPROT`, `PWRITE` | 1 | out | `PSEL` | C |
| `PSELxCHK` | `PSELx` | 1 per `PSELx` | out | `PRESETn` | C |
| `PENABLECHK` | `PENABLE` | 1 | out | `PSEL` | C |
| `PWDATACHK` | `PWDATA` | `DATA_WIDTH/8` | out | `PSEL & PWRITE` | C |
| `PSTRBCHK` | `PSTRB` | 1 | out | `PSEL & PWRITE` | C |
| `PREADYCHK` | `PREADY` | 1 | in | `PSEL & PENABLE` | C |
| `PRDATACHK` | `PRDATA` | `DATA_WIDTH/8` | in | `PSEL & PENABLE & PREADY & !PWRITE` | C |
| `PSLVERRCHK` | `PSLVERR` | 1 | in | `PSEL & PENABLE & PREADY` | OC |
| `PWAKEUPCHK` | `PWAKEUP` | 1 | out | `PRESETn` | C (+`Wakeup_Signal`) |
| `PAUSERCHK` | `PAUSER` | ceil(`USER_REQ_WIDTH`/8) | out | `PSEL` | OC |
| `PWUSERCHK` | `PWUSER` | ceil(`USER_DATA_WIDTH`/8) | out | `PSEL & PWRITE` | OC |
| `PRUSERCHK` | `PRUSER` | ceil(`USER_DATA_WIDTH`/8) | in | `PSEL & PENABLE & PREADY & !PWRITE` | OC |
| `PBUSERCHK` | `PBUSER` | ceil(`USER_RESP_WIDTH`/8) | in | `PSEL & PENABLE & PREADY` | OC |

*Spec note:* [IHI Table B-2] lists `PADDRCHK` width as `ADDR_WIDTH/8`; [IHI Table 5-1] and [IHI §5.3] give ceil(`ADDR_WIDTH`/8) with a partial most-significant check bit. This contract uses **ceil()**.

### 2.3 Configuration legality checks (`apb_agent_cfg::validate()`) [proposed]

`validate()` fails with `uvm_fatal` (not a warning) when any of these is true. Each check cites its source.

| ID | Illegal configuration | Source |
|---|---|---|
| CFG-01 | `has_pprot` or `has_pstrb` with revision APB2/APB3 | [IHI Table B-1] "N" |
| CFG-02 | `has_pwakeup`, any user width > 0, or `check_type != NONE` with revision < APB5 | [IHI §3.6.1, §3.7.1, §5.2, Table B-3] |
| CFG-03 | `ADDR_WIDTH` outside 1..32 | [IHI Table 2-1] "PADDR can be up to 32 bits wide" |
| CFG-04 | `DATA_WIDTH` not in {8, 16, 32} | [IHI §2.1.2] — see open question **Q1** for DW=64 |
| CFG-05 | Configured user width larger than the physical `apb_if` parameter | physical consistency |
| CFG-06 | Configured widths differ from the bound BFM's parameters (cross-wiring) | ADR-001 §4 |

Exceeding the *recommended* user-signal widths ([IHI Table 2-1]: `PAUSER` ≤ 128, `PWUSER`/`PRUSER` ≤ `DATA_WIDTH/2`, `PBUSER` ≤ 16) is a `uvm_warning`, because the spec only recommends these limits.

---

## 3. Parameters and widths

| Parameter (HDL) | Legal range | Source |
|---|---|---|
| `ADDR_WIDTH` | 1..32 | [IHI Table 2-1] |
| `DATA_WIDTH` | 8, 16, 32 | [IHI §2.1.2]; read and write buses must have the same width |
| `USER_REQ_WIDTH`, `USER_DATA_WIDTH`, `USER_RESP_WIDTH` | ≥ 1 physical (presence via cfg; 0 = absent) | [IHI §2.1, §3.7.2] |
| `NUM_SEL` | ≥ 1, default 1 [ASSUMPTION] | [IHI Table 2-1]: one `PSELx` per Completer |

`NUM_SEL`: [IHI Table 2-1] has the Requester generate one `PSELx` per Completer. The proposal keeps a `PSEL[NUM_SEL-1:0]` vector (with one `PSELxCHK` per bit) and a transaction `sel` index. Milestone 1 tests only `NUM_SEL = 1` (see **Q2**).

---

## 4. Transfer rules for the driver BFM and the monitor checks

These IDs are the traceability keys for assertions, coverage and tests.

| ID | Rule | Source |
|---|---|---|
| APB-R01 | All signals are timed against the rising edge of `PCLK` | [IHI Table 2-1, §3.1, §3.3] |
| APB-R02 | IDLE (`PSELx`=0) is the default state | [IHI §4.1] |
| APB-R03 | SETUP: `PSELx`=1, `PENABLE`=0 for exactly one cycle, then always ACCESS | [IHI §4.1] |
| APB-R04 | ACCESS: `PENABLE`=1. `PADDR`, `PPROT`, `PWRITE`, `PWDATA` (writes), `PSTRB`, `PAUSER`, `PWUSER` must not change from SETUP through every ACCESS cycle. `PSELx` and `PENABLE` remain asserted while `PREADY`=0 | [IHI §4.1, §3.1.2, §3.3.2] |
| APB-R05 | ACCESS exits when `PREADY`=1: to IDLE, or directly to SETUP for a following transfer. `PENABLE` deasserts at the end of the transfer | [IHI §4.1, §3.1.1] |
| APB-R06 | `PREADY` may take any value while `PENABLE`=0; no check applies there | [IHI §3.1.2] |
| APB-R07 | Every transfer takes ≥ 2 cycles; wait states range from zero upwards | [IHI §1.1, §3.3.2] |
| APB-R08 | `PSTRB[n]` qualifies `PWDATA[8n+7:8n]`; `PWDATA` must be valid on active lanes when `PSEL` is asserted | [IHI §3.2, A.1] |
| APB-R09 | On reads the Requester drives all `PSTRB` bits LOW | [IHI §3.2, Table 2-1] |
| APB-R10 | `PRDATA` and `PRUSER` are valid only when `PSEL & PENABLE & PREADY & !PWRITE` | [IHI §3.3.1, §3.7.2, A.1] |
| APB-R11 | `PSLVERR` and `PBUSER` are valid only in the last cycle (`PSEL & PENABLE & PREADY`). `PSLVERR` LOW otherwise is recommended, not required | [IHI §3.4, §3.7.2, A.1] |
| APB-R12 | A read error may return invalid data; the monitor still reports the data, with the error flag | [IHI §3.4] |
| APB-R13 | `PSEL` and `PWAKEUP` must always be valid (never X/Z) | [IHI A.1] |
| APB-R14 | Signals not required to be valid are recommended driven to zero | [IHI A.1] |
| APB-R15 | `PADDR` is a byte address; unaligned is permitted but the result is UNPREDICTABLE | [IHI §2.1.1] |
| APB-R16 | `PPROT[0]` normal/privileged, `[1]` secure/non-secure, `[2]` data/instruction | [IHI Table 3-2] |
| APB-R17 | `PWAKEUP`: synchronous and glitch-free; may assert before, during or after `PSELx`; if `PWAKEUP` and `PSELx` are both HIGH in a cycle it stays asserted until `PREADY`. Recommended ≥ 1 cycle before `PSELx` and deasserted when no more transfers are required. Asserting then deasserting without a transfer is permitted but not recommended | [IHI §3.6.2] |
| APB-R18 | A Completer may wait for `PWAKEUP` before `PREADY`; a never-asserted `PWAKEUP` can deadlock | [IHI §3.6.2] |
| APB-R19 | `PAUSER` is valid with `PSEL` and identical in SETUP and every ACCESS cycle; `PWUSER` likewise for writes | [IHI Table 3-5] |
| APB-R20 | Odd parity; each check bit covers ≤ 8 payload bits (`chk[n]` ↔ `payload[8n+7:8n]`); single-bit control checks are the inversion of the signal; driven correctly in every cycle the check-enable term is true, over all payload bits including inactive lanes; covered signals that are absent count as LOW | [IHI §5.3, Table 5-1] |
| APB-R21 | Completer behaviour on a parity error is not prescribed; the monitor reports it and the UVC does not judge the Completer's reaction | [IHI §5.4] |
| APB-R22 | Not pipelined: one transfer at a time per interface | [IHI §1.1, §2.1.2] |

### UVC policies built on top of the rules [ASSUMPTION]

| ID | Policy | Default |
|---|---|---|
| POL-01 | Unaligned `PADDR` (APB-R15) is a driver error unless `cfg.allow_unaligned` | error |
| POL-02 | Wait-state watchdog: transfer ends with status `TIMEOUT` and `uvm_error` after `cfg.max_wait_cycles` ACCESS cycles; 0 disables | 1024 |
| POL-03 | Idle-cycle value policy for Requester outputs (APB-R14) | drive zero |
| POL-04 | `PWAKEUP` lead before SETUP / hold after last transfer (APB-R17) | 1 / 1 cycles |
| POL-05 | Recommended-only behaviours (`PSLVERR` LOW outside completion, APB-R11) are reported at `UVM_INFO`/warning, never as errors | warning |

---

## 5. Reset semantics

IHI 0024D only says that `PRESETn` is active-LOW and normally connected to the system bus reset [IHI Table 2-1], that IDLE is the default state [IHI §4.1], that `PSEL`/`PWAKEUP` must always be valid [IHI A.1], and that `PSELxCHK`/`PWAKEUPCHK` are checked whenever `PRESETn` is HIGH [IHI Table 5-1]. **Everything below is [ASSUMPTION] for review.**

| ID | Behaviour |
|---|---|
| RST-1 | While `PRESETn`=0 the driver BFM drives `PSEL`=0, `PENABLE`=0, `PWAKEUP`=0 and all other Requester outputs to 0 |
| RST-2 | Reset assertion is recognised immediately (asynchronously); deassertion is recognised at the first `PCLK` rising edge that samples `PRESETn`=1 |
| RST-3 | A transfer in flight when reset asserts is abandoned. The sequence item completes with status `RESET_ABORTED` and is not retried |
| RST-4 | The monitor discards a partially observed transfer: no transaction is published. Reset entry/exit is reported through a separate observe-API event |
| RST-5 | First SETUP after reset is no earlier than the first rising edge after deassertion (`cfg.post_reset_idle_cycles`, default 1) |
| RST-6 | Protocol and X/Z checks are inactive while `PRESETn`=0. `PSEL`/`PWAKEUP` X/Z checks (APB-R13) start at the first reset deassertion, which allows time-0 X before the first reset |
| RST-7 | X/Z on `PRESETn` after the first reset deassertion is an error |

---

## 6. Transaction representation (HVL, not width-parameterized)

`apb_transaction` extends `uvm_sequence_item`. One class serves every instance width.

| Field | Type [ASSUMPTION] | Notes |
|---|---|---|
| `dir` | `apb_dir_e` {`APB_READ`, `APB_WRITE`} | |
| `addr` | `logic [`APB_MAX_ADDR_WIDTH`-1:0]` | max 32 per [IHI Table 2-1] |
| `wdata`, `rdata` | `logic [`APB_MAX_DATA_WIDTH`-1:0]` | max 32 per [IHI §2.1.2] (Q1) |
| `strb` | `logic [`APB_MAX_DATA_WIDTH`/8-1:0]` | |
| `prot` | `logic [2:0]` | |
| `auser`, `wuser`, `ruser`, `buser` | `logic [`APB_MAX_*_USER_WIDTH`-1:0]` | default maxima 128 / 32 / 32 / 16, overridable by `+define+` |
| `sel` | `int unsigned` | index into `PSEL[NUM_SEL-1:0]` |
| `slverr` | `bit` | observed `PSLVERR` |
| `status` | `apb_status_e` {`APB_OK`, `APB_SLVERR`, `APB_RESET_ABORTED`, `APB_TIMEOUT`} | |
| `idle_cycles_before` | `rand int unsigned` | 0 means back-to-back (APB-R05) |
| `wait_states`, `start_cycle`, `end_cycle` | observation metadata | filled by the monitor |
| `bus_data_width`, `bus_addr_width`, `instance_id` | observation metadata | which bits are meaningful, and which instance produced it |

### Lossless and 4-state rules

- **No silent narrowing.** On HVL → BFM conversion, the drive adapter checks that every bit at or above the bound bus width (`addr`, `wdata`, `strb`, user fields) is 0. Any other value is a `uvm_error` and the item is not driven.
- **No sign extension.** All payload fields are unsigned `logic` vectors. On BFM → HVL conversion the observe adapter zero-extends and records `bus_data_width`.
- **4-state preserved.** The monitor captures X/Z verbatim; nothing is converted to `bit`.
- **Driver input check.** X/Z in `addr`, `dir`, `prot`, `strb` or `sel` is a `uvm_error` before driving. X/Z in `wdata` is allowed only when `cfg.allow_x_wdata` is set (for fault injection).
- The macro maxima are a single compile-time choice per simulation image, documented in the README once code exists. A dynamic/chunked representation is not used because APB widths are bounded by the spec.

---

## 7. Monitor transport proposal (RISK-002) [ASSUMPTION]

- The monitor BFM samples through a clocking block (`@(posedge PCLK)`, input skew `#1step`) and reconstructs transfers in an always-running HDL process, independent of HVL timing.
- A transfer is **published once**, at the `PCLK` edge where `PSEL & PENABLE & PREADY` is sampled HIGH (APB-R05). The completed transfer goes into a bounded HDL queue of plain packed values; overflow is an error.
- The HVL observe adapter calls a blocking BFM task `get_transfer(output ...)` from the UVM monitor's `run_phase`, then builds the `apb_transaction`. No UVM class objects exist on the HDL side (ADR-002 §6).
- The monitor works whether or not the driver BFM is enabled, because it only reads pins.
- This is a proposal until compile + simulation evidence exists on the target simulator.

## 8. Driver BFM behaviour [ASSUMPTION]

- Drives on the `PCLK` rising edge through a clocking block. It enters ACCESS after one SETUP cycle and holds every APB-R04 signal stable until `PREADY` is sampled HIGH (or the APB2 default of `PREADY`=1 applies).
- Back-to-back: if the next item has `idle_cycles_before == 0`, ACCESS goes straight to SETUP (APB-R05).
- **Drive release:** when the driver BFM is not enabled (passive instance) its outputs are `'z`, and `apb_if` uses resolved nets. A passive instance therefore cannot contend with another Requester on the same bus (ADR-002 acceptance "no drive activity while configured passive").

---

## 9. Package and compile dependencies (proposed)

```text
HDL compilation units (no UVM, no packages required):
  hdl/apb_if.sv            hdl/apb_driver_bfm_if.sv            hdl/apb_monitor_bfm_if.sv
        ^ ordinary signal ports wired in examples/apb_hdl_top.sv (ADR-002 §7)

HVL packages:
  uvm_pkg
    └─> apb_api_pkg       (hvl/types, hvl/api: enums, apb_transaction, drive/observe proxy bases)
          ├─> apb_uvc_pkg      (hvl/config, hvl/agent, hvl/sequences, hvl/coverage)
          └─> apb_adapter_pkg  (hvl/adapter: width-specialized proxies; references the
                                BFM interface types via virtual interface handles)

Integration (examples/):
  apb_hdl_top  : instantiates apb_if + both BFMs per instance + apb_example_slave
  apb_hvl_top  : imports uvm_pkg, apb_api_pkg, apb_uvc_pkg, apb_adapter_pkg;
                 constructs adapters, fills one apb_agent_cfg per instance, uvm_config_db::set once, run_test()
```

Compile order: `uvm_pkg` → HDL interfaces → `apb_api_pkg` → `apb_uvc_pkg` → `apb_adapter_pkg` → examples/tests. `apb_uvc_pkg` must not import `apb_adapter_pkg`; nothing in the core imports example or test code.

## 10. File manifest and milestone split

| Step (`CLAUDE_GENERATION_PROMPT.md`) | Files | Features implemented |
|---|---|---|
| 2 HDL | `hdl/apb_if.sv`, `hdl/apb_driver_bfm_if.sv`, `hdl/apb_monitor_bfm_if.sv`, `examples/apb_example_slave.sv`, `examples/apb_hdl_top.sv`, `filelists/apb_hdl.f` | Full APB5 pin superset declared; APB2/3/4 behaviour implemented; APB5 pins driven/treated per defaults |
| 3 HVL API | `hvl/types/apb_types.sv`, `hvl/types/apb_transaction.sv`, `hvl/api/apb_drive_proxy_base.sv`, `hvl/api/apb_monitor_proxy_base.sv`, `hvl/pkg/apb_api_pkg.sv` | |
| 4 HVL concrete | `hvl/adapter/apb_drive_proxy.sv`, `hvl/adapter/apb_monitor_proxy.sv`, `hvl/pkg/apb_adapter_pkg.sv` | |
| 5 UVM | `hvl/config/apb_agent_cfg.sv`, `hvl/agent/{apb_driver,apb_monitor,apb_sequencer,apb_agent}.sv`, `hvl/sequences/*.sv`, `hvl/coverage/apb_coverage.sv`, `hvl/pkg/apb_uvc_pkg.sv`, `filelists/{apb_hvl,apb_poc}.f`, `examples/apb_hvl_top.sv` | |
| 6 Tests | `tests/apb_poc_test.sv`, `tests/apb_fault_injection_test.sv`, `scripts/run_poc.sh` | M1 tests: APB3/APB4 |
| later M2 | same files | APB5 `PWAKEUP` + user signals |
| later M3 | same files + `assertions/` | APB5 parity generation/checking + parity fault injection |

`hvl/types/apb_types.sv` (enums, macros) is an addition to the DIRECTORY_ARCHITECTURE plan. It is needed so enums are shared by transaction, proxies and cfg.

## 11. Smallest runnable task and acceptance test

**APB-003a (step 2):** the HDL files in the step 2 row above, with two instances in `apb_hdl_top`.

Acceptance:
1. slang elaboration of `apb_hdl_top` with both instances: **0 errors** (log stored with SHA).
2. HDL-only directed smoke without UVM, on a simulator: per instance, one write and one read-back with 0 and 2 wait states. The monitor queue must receive exactly the expected transfers with correct values and no extra publications.
3. Negative control: a deliberately broken BFM (e.g. `PADDR` changed during a wait state) must be caught by the monitor check.

Item 1 can run in this container now. Items 2–3 need a simulator (**Q3**).

---

## 12. Open questions (need owner decision)

| ID | Question | Recommendation |
|---|---|---|
| **Q1** | **IHI 0024D allows only DATA_WIDTH 8/16/32** [IHI §2.1.2, Table 2-1], but ADR-001 §3 / acceptance gates require a DW=64 instance. | Amend ADR-001: prove width independence with **DW=32 + DW=16** (spec-legal); optionally keep DW=64 as an explicitly labelled *non-standard extension* behind `cfg.allow_nonstandard_width` / `+define+APB_ALLOW_NONSTANDARD_WIDTH`, never the default |
| Q2 | Multi-`PSELx` (`NUM_SEL` > 1) in scope? | Parameter present, default 1; multi-select tests deferred |
| Q3 | Target simulator / UVM version. In-container options: slang (elaboration only, available) and Verilator ≥ 5.04x built from source (simulation; build needs approval) | Use slang + Verilator here for evidence; record the owner's commercial simulator when known |
| Q4 | Implement parity in M1 or later? | Pins + config in M1; generation/checking in M3 |
| Q5 | Approve the reset assumptions RST-1..7 and policies POL-01..05 | — |
