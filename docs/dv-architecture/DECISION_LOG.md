# DECISION_LOG — owner decisions for the single APB UVC POC

Every decision the repository owner has made, in one place, so a new session, model or engineer can pick up the context without the chat history. Decisions here override everything except later owner decisions (precedence in `CODING_GUIDELINES.md`).

**Rules for this file (DOC-02):** add an entry the moment the owner decides something, with the date, the owner's words (paraphrased if long), and where it is applied. Never edit an old entry's meaning; supersede it with a new entry and mark the old one *Superseded by D-xxx*.

| ID | Date | Decision | Applied in |
|---|---|---|---|
| D-001 | 2026-10-29 | Branch from `dev` with an industry-standard name and Conventional Commit messages. Working branch: `feature/apb-001-protocol-contract`. | Git history; `CODING_GUIDELINES.md` GIT-01/02 |
| D-002 | 2026-10-29 | The UVC must support **all APB revisions (APB2–APB5) and all features**; an instance enables only what its interface has ("if they don't use then don't use"). Default instance: **APB4** with `PSTRB` and `PPROT`. | `ARCHITECTURE_CONTRACT.md` (scope), `APB_PROTOCOL_CONTRACT.md` §1–2, `apb_bfm_pkg::apb_default_features()` |
| D-003 | 2026-10-29 | Width-independence pair is **DW=32 + DW=16**; **DW=64 kept only as an opt-in non-standard extension**. | ADR-001 Amendment A1; `APB_ENABLE_DW64_EXTENSION`, `ALLOW_NONSTANDARD_DW`, `allow_nonstandard_width` |
| D-004 | 2026-10-29 | Commercial simulators cannot be installed here; **EDA Playground is the owner's option** for simulation. | `WORK_STATUS.md` T4; `scripts/make_eda_bundle.py`; README |
| D-005 | 2026-10-29 | **No tool-specific workarounds; keep the code generic** ("it has to be generic as much as possible"). Verilator-driven edits C1–C5 were reverted; tool-neutral hygiene C6 kept. Restated with emphasis on 2026-10-29: no unapproved tool-specific workarounds of any kind. | `REVIEW_FEEDBACK.md` RISK-010; `ARCHITECTURE_CONTRACT.md` gate; `CODING_GUIDELINES.md` NN-01/NN-06 |
| D-006 | 2026-10-29 | **Toolchain approval gate** (merged from `dev`, PR #3): no simulator, compiler, elaborator or lint tool runs without explicit owner approval of tool, version and commands; everything else is NOT RUN. Bring `dev` in with stash → switch dev → pull → switch back → merge dev → stash pop. | `ARCHITECTURE_CONTRACT.md` v0.10; `CLAUDE_GENERATION_PROMPT.md`; merge commit `91c369f`; `CODING_GUIDELINES.md` NN-02 |
| D-007 | 2026-10-29 | Generate the HVL/UVM classes and keep `WORK_STATUS.md` updated so the work can move to a new session, model or LLM. | `poc/apb_uvc/hvl/**`, `examples/apb_hvl_top.sv`, `tests/**`; `WORK_STATUS.md` "Resume here" |
| D-008 | 2026-10-29 | **Approved T1** (slang 12.1.0 with the commands in `WORK_STATUS.md`) and **T3** (UVM library download), **UVM version 1.2**. | `WORK_STATUS.md` approval table; `evidence/APB-003b/`, `evidence/APB-004/` |
| D-009 | 2026-10-29 | UVM 1.2 source: the owner-named mirror **`https://github.com/gchinna/uvm-1.2`** (Accellera's host is blocked by the network policy). Kept outside the repository. | `WORK_STATUS.md` T3; `evidence/APB-004/README.md` (mirror check) |
| D-010 | 2026-10-29 | **Do not pursue the open-source compilation further for now;** the owner will check runs manually once the POC reaches the agreed point. T5 (`slang --timescale 1ns/1ps`) is therefore **not approved**; RISK-012 stays open. | `WORK_STATUS.md` T5 row; `REVIEW_FEEDBACK.md` RISK-012 |
| D-011 | 2026-10-29 | Before doing or adding any code, it must follow the **highest coding standard**, and the guidelines must make the discussed context portable to the next session or model. | `CODING_GUIDELINES.md` (this push); this file; read order in both `AGENTS.md` files |
| D-012 | 2026-10-29 | `CODING_GUIDELINES.md` is **mandatory** for every change under `poc/apb_uvc/`. | `CODING_GUIDELINES.md` header; pre-commit checklist §13 |
| D-013 | 2026-10-30 | Add the necessary comments to the necessary files before the session is closed, so the next session or model can follow the code. | Comment pass over 25 source files; `CODING_GUIDELINES.md` FMT-09 (required comments) and checklist; UVC README *Reading the code* |
| D-014 | 2026-10-30 | Commit with the owner's name, not "Claude": commits are authored and committed as Mahantha Deeksha S B (same email as the owner's own commits); AI assistance only as the `Co-Authored-By` trailer. The 25 earlier commits on this branch stay authored as Claude unless the owner approves a history rewrite (it needs a force-push, which `AGENTS.md` forbids, and changes every SHA cited in the docs). | `CODING_GUIDELINES.md` GIT-07; `WORK_STATUS.md` *Resume here* step 1; repository-local git identity |
| D-015 | 2026-10-30 | **Leave the old commits as they are**; only new commits use the owner's identity. No history rewrite and no force-push for authorship (resolves the open question in D-014). | `CODING_GUIDELINES.md` GIT-07; `WORK_STATUS.md` handoff |

## Defaults in force, not yet confirmed by the owner

These were proposed by the implementer and are implemented, but the owner has not explicitly accepted them. Treat them as defaults that may change.

| ID | Topic | Default in force | Where |
|---|---|---|---|
| Q2 | Multiple `PSELx` | `NUM_SEL` parameter present, default 1; only 1 tested | `APB_PROTOCOL_CONTRACT.md` §3 |
| Q4 | APB5 parity | Pins and config in M1; generation/checking in milestone M3 | `APB_PROTOCOL_CONTRACT.md` §2.2, §10 |
| Q5 | Reset and policies | RST-1..7 and POL-01..05 as written | `APB_PROTOCOL_CONTRACT.md` §4–5 |
| — | Monitor delivery | `get_transfer()` waits on a named event after checking the queue | `APB_PROTOCOL_CONTRACT.md` §7 |
| — | Driver reset abort | `fork…join_any` reset watcher, abandon at the reset edge | `APB_PROTOCOL_CONTRACT.md` §8 |
| — | File extensions | Package-included class files keep `.sv` (approved directory plan); `.svh` for define headers only | `CODING_GUIDELINES.md` FILE-03 |
