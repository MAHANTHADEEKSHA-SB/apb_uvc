# Independent review findings and feedback loop

**Principle:** Claude generates; ChatGPT and Gemini review the **same commit** independently. Agreement is helpful but never proof. Compiler, simulation, assertions and fault-injection results are separate evidence streams.

## Review workflow

1. Pin the exact branch + commit SHA; don't review an unnamed moving HEAD.
2. Reviewer 1 checks implementation against spec, SV/UVM semantics, accepted ADRs and missing edge cases **without first reading Reviewer 2's conclusions**.
3. Reviewer 2 repeats independently; record any different interpretation explicitly.
4. Consolidate findings into issues with IDs, severity, affected file/line, reproducible example or reasoning, and verification requirement.
5. Implementer proposes a fix on the feature branch and links the fix commit.
6. Re-run targeted tests plus regressions; attach actual logs.
7. A reviewer closes the issue only when the change and evidence answer the original finding, or documents an approved risk acceptance.

## Finding template (copy per issue)

```markdown
### RV-XXX — Short specific description
- Status: OPEN | INVESTIGATING | FIXED_UNVERIFIED | CLOSED_VERIFIED | WAIVED_APPROVED
- Severity: BLOCKER | MAJOR | MINOR | SUGGESTION
- Reviewers: <who reviewed independently>
- Reviewed branch/SHA: <actual commit>
- File(s)/line(s): <path:Lxx-Lyy>
- Requirement/ADR: <link to architecture contract or spec paragraph>
- Problem / failing case: <precise behavior, no generic speculation>
- Evidence: <compile error, trace, SVA, test, or technical reasoning>
- Proposed fix: <specific code or test change>
- Owner: <person/model>
- Fix commit: <SHA or PENDING>
- Retest: <tool/version, exact command, log, result; or NOT RUN>
- Resolution and reviewer sign-off: <record actual decision>
```

## Open architectural validation questions (not confirmed code bugs)

### RISK-001 — BFM interface virtual-handle legality
- Status: OPEN / DESIGN RISK
- ADR: `ADR-002-SEPARATE-DRIVE-OBSERVE-APIS.md`
- Question: Can the chosen SV signal-port BFM interfaces and virtual handles compile under the target tool, including multiple instances?
- Required evidence: compile and simulation on named simulator/version; ensure no interface-typed port issue.

### RISK-002 — HVL monitor return path and scheduling
- Status: OPEN / DESIGN RISK
- Question: Does the observe adapter collect sampled data race-free, without dropped events or unexpected blocking?
- Required evidence: clock-edge directed tests, back-to-back transfers, wait states, reset around sample boundary.

### RISK-003 — Correct width, data and isolation
- Status: OPEN / DESIGN RISK
- Question: Do two concurrent specializations preserve 4-state values and deliver packets to the correct agent?
- Required evidence: 32/64 data patterns, X/Z checks where applicable, cross-wire fault test.

### RISK-004 — Passive and optional build policy
- Status: OPEN / DESIGN RISK
- Question: Does passive mode prevent drive activity, and does source exclusion actually reduce the compilation unit set when chosen?
- Required evidence: passive simulation plus diff of explicit filelists/commands.

## Closed findings

_None recorded. Do not close risks solely on LLM agreement._