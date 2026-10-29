# Evidence — APB-004 (approved slang elaboration with UVM 1.2)

| Item | Value |
|---|---|
| Approval | Owner approved **T1** (slang 12.1.0) and **T3** (UVM 1.2) on 2026-10-29; UVM source named by the owner: `https://github.com/gchinna/uvm-1.2` |
| UVM checkout | `a3cb91138ffdf73e76cdc022905ab589247d0632` (outside the repository, referred to as `<UVM>` in the logs) |
| Source commit | `386e64d5130748329f8148507837819e7d9f6456` (clean tree) |
| Tool | slang 12.1.0+42710c788 via pyslang (PyPI), wrapper `poc/apb_uvc/scripts/slang_elab.py` (reports slang's own error/warning counts) |
| Scope | Parse + elaboration only; nothing simulated |

## UVM source check (the owner-named mirror)

Accellera's site is blocked by the environment network policy, so the mirror could not be byte-compared with the official tarball. Checked instead:
- 3 commits (2018-12-04): an initial commit, the import, and "fix line breaks", which changes `README.md` only.
- `release-notes.txt`: "Accellera UVM 1.2 Release Notes", repository state `UVM_1_2_RELEASE-1-gd6e87e2`. `uvm_version_defines.svh`: `UVM_MAJOR_REV 1`, `UVM_MINOR_REV 2`.
- Apache-2.0 `LICENSE`/`NOTICE`; 145 SV files in the standard `src/` layout; `bin/` Perl helpers and `src/dpi` C files as in the official kit (none executed).
- One non-Accellera file, `src/tags` (ctags output, as stated in the mirror's README); it is not SystemVerilog and is not compiled.
- No `$system` calls in the SV sources.

## Results

| Run | Command (from repository root) | Result | Log |
|---|---|---|---|
| HDL smoke, standard | `python3 -I poc/apb_uvc/scripts/slang_elab.py -F poc/apb_uvc/filelists/apb_hdl_smoke.f --top apb_hdl_smoke` | **PASS**: errors=0 warnings=0 | `logs/slang_hdl_std.log` |
| HDL smoke, DW=64 | same `+define+APB_ENABLE_DW64_EXTENSION` | **PASS**: errors=0 warnings=0 | `logs/slang_hdl_dw64.log` |
| UVM POC, standard | `python3 -I poc/apb_uvc/scripts/slang_elab.py +incdir+<UVM>/src <UVM>/src/uvm_pkg.sv -F poc/apb_uvc/filelists/apb_poc.f --top apb_hdl_top --top apb_hvl_top` | **FAIL (cause in the UVM library)**: errors=1 warnings=2 | `logs/slang_uvm_std.log` |
| UVM POC, DW=64 | same `+define+APB_ENABLE_DW64_EXTENSION` (the project's own switch) | **FAIL (cause in the UVM library)**: errors=1 warnings=2 | `logs/slang_uvm_dw64.log` |

In both UVM runs **every diagnostic is inside the UVM library; our sources have 0 errors and 0 warnings**:
- error `MissingTimeScale` at `<UVM>/src/uvm_pkg.sv:28`: "design element does not have a time scale defined but others in the design do". UVM 1.2 ships without a ``timescale`; every project file declares `1ns/1ps`. Classification: **library / language rule**, not a project source bug. Proposed fix: owner approval to add slang's `--timescale 1ns/1ps` (the default timescale for elements that declare none, the counterpart of the `-timescale` compile option every simulator has). Not applied: it is not in the approved command.
- 2 × warning `-Wempty-body` in `<UVM>/src/base/uvm_resource.svh:1666` and `<UVM>/src/seq/uvm_sequencer.svh:171`: third-party library code, intentional idiom; no action.

## Earlier run in this session (before commit 386e64d)

The first UVM run on `3dfd30a` also reported 2 × `-Wshift-count-overflow` in `hvl/adapter/apb_drive_proxy.sv` (`req.addr >> ADDR_WIDTH` with ADDR_WIDTH = 32). Fixed in `386e64d` by a generic bit-loop check (source quality; no tool-specific code). The wrapper then printed a raw diagnostic total of 2020, which included suppressed diagnostics; `386e64d` changed it to slang's reported counts.
