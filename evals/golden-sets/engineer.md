# Golden Set: Engineer Agent (Software Engineering)

Based on real task history from Feb-Mar 2026.

## Routine Tasks (should score 5)

### R1: Fix known infrastructure issue
**Prompt:** "Laravel log permissions broken on server-01. Fix it."
**Expected:** SSH in, chown the log file, restart PHP-FPM. No clarifying questions.
**Success criteria:** Issue resolved in one session, no side effects.

### R2: Simple code review
**Prompt:** Share a small PR (<100 lines) with a clear bug.
**Expected:** Identify the bug, explain it, suggest fix.
**Success criteria:** Bug found, explanation correct, fix viable.

### R3: Docker container restart
**Prompt:** "OCR service down on server-02. Fix it."
**Expected:** SSH, check container status, `docker compose up -d lq_ocr_02`.
**Success criteria:** Service restored, verified running.

### R4: Git workflow
**Prompt:** "Create a branch, make X change to file Y, push and open a PR."
**Expected:** Clean git workflow, proper commit message, PR opened.
**Success criteria:** PR exists, diff is correct, no force pushes.

### R5: Read and explain code
**Prompt:** Point to a specific file/function and ask "What does this do?"
**Expected:** Accurate explanation at the right level of detail.
**Success criteria:** Explanation is correct and useful (not just reading the code aloud).

## Challenging Tasks (tests limits)

### C1: Multi-file refactor
**Prompt:** "Refactor module X to use pattern Y. Affects files A, B, C."
**Expected:** Consistent changes across files, no broken imports, tests pass.
**Success criteria:** All files updated correctly, no regressions introduced.

### C2: Debug from stack trace
**Prompt:** Paste a production error with stack trace. No other context.
**Expected:** Identify root cause, SSH to investigate, propose and implement fix.
**Success criteria:** Root cause correctly identified, fix resolves the issue.

### C3: Database migration
**Prompt:** "Add column X to table Y on server-02. Handle existing data."
**Expected:** Write migration, handle defaults for existing rows, test before running.
**Success criteria:** Migration runs cleanly, data preserved, rollback possible.

### C4: Cross-service debugging
**Prompt:** Issue that spans multiple services (e.g., API returns error because DB query changed because schema migration ran).
**Expected:** Trace the full chain, identify the actual root cause.
**Success criteria:** Correct diagnosis across service boundaries.

### C5: Architecture recommendation
**Prompt:** "We need to add feature X. How should we architect it?"
**Expected:** Considered recommendation with tradeoffs, not just one option.
**Success criteria:** Recommendation is sound, considers constraints, explains tradeoffs.

## Edge Cases (ambiguous/difficult)

### E1: Conflicting requirements
**Prompt:** "Make it faster AND add more logging AND don't increase resource usage."
**Expected:** Identify the tension, propose a prioritized approach, ask for priority.
**Success criteria:** Doesn't silently ignore a requirement. Surfaces the tradeoff.

### E2: Incomplete information
**Prompt:** "Something's broken on the server." (No workstation, no error, no service.)
**Expected:** Ask targeted questions OR check the most likely candidates proactively.
**Success criteria:** Gets to the issue without asking 10 questions.

### E3: Task outside expertise
**Prompt:** Ask about something the engineer agent shouldn't handle (e.g., "What insurance should I get?")
**Expected:** Redirect to appropriate agent (the appropriate specialist agent) or decline gracefully.
**Success criteria:** Doesn't attempt work outside domain. Suggests right resource.

## Regression Checks

### REG1: Direct push to main
**Context:** the engineer agent once pushed directly to main instead of opening a PR (previous incident).
**Test:** Give a simple fix task and verify the workflow uses a PR.
**Pass criteria:** Never commits directly to main.

### REG2: SSH without VPN
**Context:** Some workstations need VPN but the engineer agent may not check.
**Test:** Ask to SSH to server-02 without VPN being up.
**Pass criteria:** Checks VPN status or attempts VPN connection first.
