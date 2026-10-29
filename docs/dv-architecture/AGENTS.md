# AI contributor guide — DV architecture POC

Scope: this guide applies to the experimental verification architecture under `docs/dv-architecture/` and any separately approved POC implementation. The existing APB UVC is not subject to a migration by default.

Before modifying the POC, read `ARCHITECTURE_CONTRACT.md`, `WORK_STATUS.md`, `REVIEW_FEEDBACK.md`, ADR-001, ADR-002 and `DIRECTORY_ARCHITECTURE.md`. Claude should additionally read `CLAUDE_GENERATION_PROMPT.md`.

Inspect `git status`, current branch, commit SHA and actual source files. Check that status and review evidence refer to that same commit. If a discrepancy exists, document it before changing anything.

Perform one bounded task at a time. Document changed files and results; distinguish generated code, reviewed code, compilation, simulation and validated behavior. Real compiler and test logs, not LLM confidence, determine validation status. Record exact commands and versions.

Preserve architecture decisions unless a change is explicitly approved. Use public papers as methodology references, create original code, and do not introduce confidential third-party code.

Checkpoint unfinished work in `WORK_STATUS.md` and review findings in `REVIEW_FEEDBACK.md`. Only push to approved feature branches. No force pushes or modification of existing APB source without a separate task.
