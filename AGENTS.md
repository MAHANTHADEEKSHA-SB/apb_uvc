# GitHub repository AI guidance

This repository currently contains an existing flat-layout APB UVC. Do **not** move, replace, or refactor those files as part of the new architecture experiment.

For the **single APB UVC proof of concept** under `poc/apb_uvc/`, read [docs/dv-architecture/AGENTS.md](docs/dv-architecture/AGENTS.md) and its architecture contract, ADRs, directory plan, `WORK_STATUS.md`, and `REVIEW_FEEDBACK.md`.

The experimental APB UVC is self-contained: **one** signal interface, **two** separate BFM interfaces (driver/monitor), separate abstract/concrete HVL proxies, UVM components and filelists. DW=32 and DW=64 are **instances of the same UVC**, not other protocol UVCs.

Do not claim compilation or simulation passed without actual commands/logs. Do not modify the source outside `poc/apb_uvc/` unless separately approved. No force pushes or direct merges into `dev` or `main`.
