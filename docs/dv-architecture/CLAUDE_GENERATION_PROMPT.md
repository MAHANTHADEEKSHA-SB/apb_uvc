# Claude — generation brief (separate from project state)

Develop an original, reproducible SystemVerilog/UVM proof of concept for a reusable parameter-independent UVC. Public DVCon papers are **engineering references**, not code to reproduce. Treat the accepted ADRs and project contract as authoritative design constraints, and challenge them explicitly when you find a correctness concern.

## Always begin a session

1. Read `AGENTS.md`, `ARCHITECTURE_CONTRACT.md`, `WORK_STATUS.md`, and `REVIEW_FEEDBACK.md` first, then the relevant ADRs.
2. Inspect source files, `git status`, branch and commit. Explain inconsistencies; never guess.
3. State the next smallest work item and its acceptance test before generating code.
4. Preserve existing work. Do not rewrite completed code without an identified reason.

## Initial POC objective

- Two concurrent physical bus-width instances (32 and 64), sharing UVM driver/monitor/agent class definitions without width parameter ripple.
- Each instance has one signal interface with signals/modports, one driver BFM and one monitor BFM, separate abstract drive/observe APIs, parameterized HVL concrete adapters, and one per-agent configuration object distributed through `uvm_config_db`.
- Prefer SV interface BFMs with ordinary typed signal ports for initial wiring. Highlight portability limitations and require actual compiler testing.
- Correct UVM packagings/imports, source/filelist order, multi-instance wiring, passive operation, no silent width truncation, and race-free monitor publication.
- Testbench includes an independently specified tiny DUT model, directed tests, negative fault-injection tests, exact invocations and observed logs.

## Work pattern

**Explore:** Evaluate conflicting technical possibilities; identify spec/tool assumptions and trade-offs. Don't add optional abstractions automatically.

**Design:** Show file manifest, package dependency graph, transaction representation and integration flow; reconcile with accepted ADRs.

**Implement:** Generate in small compile-sized slices. Update `WORK_STATUS.md` immediately after each slice, marking actually generated source separately from compiled/simulated source.

**Review:** Write a self-review of known limitations; ask independent reviewers to work against the same commit SHA using `REVIEW_FEEDBACK.md`.

**Validate:** Run checker → compiler → simulation → fault injection, as tools permit. Publish exact tool versions and commands; never invent successful results.

**Handoff:** Before tokens/context run low or the task changes, fill the handoff block in `WORK_STATUS.md` and record open risks. If Git writes are authorized, commit source plus docs to the agreed feature branch. The next AI should be able to continue with **no hidden chat context**.

## Restrictions

- No confidential source copying; original implementation only.
- No bypassing or silently weakening the architecture contract.
- No fabricated commits, compilation results, simulation results, coverage, passing tests or verified emulator compatibility.
- No direct pin access from packet-level scoreboard or predictor.
- No assumption that `UVM_PASSIVE` prevents compilation.
- No silent recompilation of unneeded optional agents when separate source groups are feasible.
- Do not make irreversible Git changes or push to protected branches without authorization.

If existing decisions turn out to be wrong, propose an ADR amendment with justification and a minimal counterexample. Do not conceal the discrepancy to keep generating.