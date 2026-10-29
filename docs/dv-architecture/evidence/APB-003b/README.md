# Evidence — APB-003b (approved HDL elaboration, portable sources)

| Item | Value |
|---|---|
| Approval | Owner approved toolchain item **T1** (slang 12.1.0) on 2026-10-29 |
| Source commit | `3dfd30a3d737e5b2133cdee9d3f382f955db39a6` (clean tree) |
| Tool | slang 12.1.0+42710c788 via pyslang (PyPI), wrapper `poc/apb_uvc/scripts/slang_elab.py` |
| Scope | Parse + elaboration of the HDL smoke design (no simulation) |

| Command (from repository root) | Result | Log |
|---|---|---|
| `python3 -I poc/apb_uvc/scripts/slang_elab.py -F poc/apb_uvc/filelists/apb_hdl_smoke.f --top apb_hdl_smoke` | **PASS** — `SLANG_RESULT: errors=0 diagnostics=0` | `logs/slang_hdl_std.log` |
| same `+define+APB_ENABLE_DW64_EXTENSION` | **PASS** — `SLANG_RESULT: errors=0 diagnostics=0` | `logs/slang_hdl_dw64.log` |

What this shows: the current HDL sources (after the RISK-010 reverts: `fork…join_any` reset watcher, named-event hand-off, `'z` release, class-based smoke runner with two parameterized-class specializations holding typed virtual BFM handles) are legal SystemVerilog as judged by slang, with no warnings. It does **not** show run-time behaviour; nothing was simulated.
