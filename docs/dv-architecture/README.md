# Single APB UVC — architecture and AI handoff

This folder governs **one reusable APB UVC POC**, developed at `poc/apb_uvc/`. The *same* APB UVC will be instantiated with 32-bit and 64-bit data buses to test parameter independence. We are **not building a multi-UVC framework** or generating AHB/AXI/UCIe components at this stage.

The existing root-level `apb_*.sv` files are an older APB UVC implementation. They remain unchanged unless a separate migration is approved.

## Read in order

1. [AGENTS.md](AGENTS.md): what every model/engineer must read and how to hand off.
2. [ARCHITECTURE_CONTRACT.md](ARCHITECTURE_CONTRACT.md): APB-only agreed architectural rules and unresolved decisions.
3. [ADR-001](ADR-001-HVL-PROXY-PLACEMENT.md): HVL concrete proxies over parameterized BFM virtual handles.
4. [ADR-002](ADR-002-SEPARATE-DRIVE-OBSERVE-APIS.md): two separate abstract capabilities and two BFMs sharing one signal interface.
5. [DIRECTORY_ARCHITECTURE.md](DIRECTORY_ARCHITECTURE.md): self-contained APB UVC distribution and example directory.
6. [CLAUDE_GENERATION_PROMPT.md](CLAUDE_GENERATION_PROMPT.md): single-APB implementation brief.
7. [WORK_STATUS.md](WORK_STATUS.md): real completed/pending work, latest checkpoint and evidence.
8. [REVIEW_FEEDBACK.md](REVIEW_FEEDBACK.md): ChatGPT/Gemini independent review findings and required retests.

## Deliverable boundary

One `poc/apb_uvc/` directory ships its own **APB interface, driver BFM, monitor BFM, HVL proxies, UVM classes, sequences, coverage, filelists and usage example**. SV interfaces compile as HDL units; the UVM class definitions compile in packages. A UVC deliverable is **not one giant SV package**.

## Current status

Architecture documentation has been revised for APB-only scope; this is **not an implemented or tested UVC**. Simulator selection, APB revision/pin subset, legal BFM connectivity and monitor transport remain to be validated. Actual status and next steps are in `WORK_STATUS.md`.

**Git workflow:** Feature branch `feature/dv-architecture-handoff` based on `dev`. Do not merge or migrate original APB files without explicit approval.
