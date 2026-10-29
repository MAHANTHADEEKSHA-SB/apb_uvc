# AI contributor guide — single APB UVC POC

**Scope:** Exactly one APB master UVC developed under `poc/apb_uvc/`; its 32-bit and 16-bit configurations (ADR-001 Amendment A1) are different **instances of the same component**. The repository's root-level legacy APB sources are not targets of this POC. Do not generate other protocols/UVCs, a generic verification framework or bridge scoreboards.

## Mandatory read before changes

1. `docs/dv-architecture/ARCHITECTURE_CONTRACT.md`
2. `docs/dv-architecture/ADR-001-HVL-PROXY-PLACEMENT.md` and `ADR-002-SEPARATE-DRIVE-OBSERVE-APIS.md`
3. `docs/dv-architecture/DIRECTORY_ARCHITECTURE.md`
4. `docs/dv-architecture/WORK_STATUS.md`
5. `docs/dv-architecture/REVIEW_FEEDBACK.md`
6. `docs/dv-architecture/CLAUDE_GENERATION_PROMPT.md` when implementing.

## Required workflow

- Inspect actual branch, exact SHA, `git status --short`, source manifest and available tools before changing anything.
- Record APB revision, explicit signal subset, AW/DW widths, reset policy, API transaction encoding, clocking, and BFM-to-pin wiring before declaring compile readiness.
- Work on **one smallest testable APB milestone**; keep new code within `poc/apb_uvc/`. Do not touch original root-level APB UVC code.
- Preserve approved architectural decisions unless a documented, approved ADR amendment is provided. If a rule seems invalid, demonstrate a counterexample and propose change, don't silently sidestep it.
- Record all files changed, tool versions, exact compile/sim commands, logs, and failures in `WORK_STATUS.md`. Use **NOT RUN** instead of guessing.
- Record independent ChatGPT/Gemini issues with exact reviewed SHA, file/line, severity and retest evidence in `REVIEW_FEEDBACK.md`.
- Before context/token exhaustion, checkpoint the last known working stage, current task and next exact step. Other AIs must be able to resume from Git + Markdown alone.
- Commit only to an authorized feature branch, never force-push, overwrite shared history or merge without authorization.

## Validation philosophy

Architecture choices informed by public DVCon literature are **not** simulator proofs. SV syntax, package order, APB timing, passive operation, 32/16 isolation and fault detection require executed checks. Do not fabricate successful results, claim emulation compatibility, or bring confidential employer/client code into this repo.

**Handoff precedence:** actual checked-out code + executed logs establish observed behavior; accepted contract/ADRs establish intended design. Reconcile contradictions explicitly.
