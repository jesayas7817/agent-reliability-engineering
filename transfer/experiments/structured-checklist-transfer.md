# Transfer Experiment: Structured Checklist Pattern

**Source agent:** Ada (Software Engineering)
**Target agent:** Patsy (Operations)
**Pattern:** Multi-step checklist with explicit criteria per category
**Hypothesis:** Patsy's incident triage is currently ad-hoc. Applying a structured checklist format (the same structure that improved Ada's code reviews) will improve Patsy's autonomy and task success on complex ops tasks.
**Status:** Not started
**Created:** 2026-03-26

---

## The Source Pattern

Ada's code reviews improved significantly after adding a structured multi-step checklist to her system prompt. The pattern:

1. Explicit categories to check (correctness, security, performance, style)
2. A required step for each category before moving to the next
3. Explicit criteria for what constitutes a pass vs. flag in each category
4. Summary step after all categories are checked

Before this change, Ada's code reviews were correct but inconsistent. She would sometimes miss security implications while focusing on correctness, or skip performance analysis on small PRs. The checklist enforced completeness.

**Note:** This experiment requires Ada's documented before/after scores from the checklist change. If those scores do not exist yet, label this experiment as "speculative" and still run it. A neutral or negative result is still useful.

---

## The Structural Pattern (Domain-Agnostic)

Extracted from Ada's code review pattern, independent of domain:

> When evaluating a complex multi-dimensional situation:
> 1. Enumerate the evaluation dimensions explicitly before starting
> 2. Work through each dimension in sequence, not in parallel
> 3. Apply explicit criteria (pass/flag/fail) per dimension
> 4. Produce a structured summary with one finding per dimension
> 5. Only recommend action after all dimensions are covered

---

## Before State

### Ada's Current State (Source)
Ada's golden set scores before the checklist pattern was applied:
- **R2 (Simple code review):** Success ?, Autonomy ?, Efficiency ?
- **C4 (Cross-service debugging):** Success ?, Autonomy ?, Efficiency ?

Fill in from `results/transfer-log.md` or from the original baseline evaluation.

### Patsy's Current State (Target)

Patsy's current incident triage approach is reactive and unstructured:
- She checks the reported symptom first, then follows the thread wherever it leads
- No explicit categories she works through
- On multi-workstation incidents (C1), she sometimes identifies the fix before fully assessing scope
- On security incidents (C4), she varies in what dimensions she covers

**Patsy's baseline scores** (from most recent golden set run):

| Task | Success | Autonomy | Efficiency |
|------|---------|----------|------------|
| R1 (Service health check) | ? | ? | ? |
| R2 (Log analysis) | ? | ? | ? |
| C1 (Multi-workstation incident) | ? | ? | ? |
| C4 (Security incident response) | ? | ? | ? |
| E2 (Ambiguous workstation) | ? | ? | ? |

Replace ? with actual scores before running the experiment. These are the control values.

---

## The Transfer: What to Apply to Patsy

Add the following to Patsy's system prompt or operational skill, under a section called "Incident Triage Protocol":

```
When triaging an incident or ops task, work through these dimensions in order:

1. SCOPE: Which systems are affected? Check all likely related systems, not just the reported one.
2. SEVERITY: Is this causing data loss, user impact, or just noise? Classify before acting.
3. CAUSE: What is the probable root cause? List hypotheses, then test the most likely one.
4. ACTION: What is the fix? Prefer reversible actions first.
5. VERIFICATION: After applying the fix, confirm the problem is resolved.
6. DOCUMENTATION: What happened, what was done, and what should change to prevent recurrence.

Do not skip steps. Do not jump to ACTION before completing SCOPE, SEVERITY, and CAUSE.
```

This is the structured checklist pattern applied to ops triage instead of code review.

---

## Success Metrics

The experiment is a success if, after applying the pattern, Patsy's scores on the following tasks improve by 0.5+ on average across the two target dimensions:

**Primary target tasks:**
- C1 (Multi-workstation incident): +0.5 on Autonomy AND/OR +0.5 on Success
- C4 (Security incident response): +0.5 on Autonomy AND/OR +0.5 on Success

**Secondary (should not regress):**
- R1, R2, R3, R4, R5: no dimension drops by more than 0.3

**Hypothesis for mechanism:** The checklist will prevent Patsy from jumping to fixes before assessing scope, which is the main autonomy failure mode on complex incidents (she over-clarifies when unsure what to check). Explicit criteria should also improve success by ensuring security incidents get a threat assessment before a remediation recommendation.

---

## Running the Experiment

### Before phase

1. Score Patsy's full golden set (all 15 tasks from `golden-sets/patsy-ops.md`)
2. Record scores in the table above
3. Also record in `results/transfer-log.md`

```bash
# Use the script to establish and log baseline
./scripts/run-transfer-experiment.sh experiments/structured-checklist-transfer.md --phase before
```

### Apply the pattern

1. Open Patsy's system prompt or operational skill file
2. Add the "Incident Triage Protocol" block above
3. Do not change anything else about Patsy's configuration
4. Wait at least 24 hours before the after run (prevents context contamination)

### After phase

5. Score Patsy's full golden set again with identical task inputs
6. Do not look at before scores until after scoring is complete
7. Record scores in `results/transfer-log.md`

```bash
./scripts/run-transfer-experiment.sh experiments/structured-checklist-transfer.md --phase after
```

8. The script will compute deltas and write a summary to `results/transfer-log.md`

### Analysis

9. Review the delta. Did C1 and C4 improve? Did any routine tasks regress?
10. If C1/C4 improved but R1-R5 stayed flat or improved: strong transfer, keep the change
11. If C1/C4 are flat but R1-R5 regressed: pattern is harmful in this domain, revert
12. Write a one-paragraph qualitative observation in `results/transfer-log.md`

---

## Expected Challenges

- **Verbosity regression:** Checklist patterns sometimes make agents more verbose on simple tasks. Watch Efficiency scores on R1-R5.
- **False positives on severity:** Patsy might start over-classifying routine tasks as incidents. Check tone and language in after-run outputs.
- **Pattern rigidity:** If Patsy applies the checklist to a trivial task (R5 DNS check), it may look silly. This is a calibration issue, not a failure of the pattern itself.

---

## Rollback

If the experiment causes a regression:
1. Remove the "Incident Triage Protocol" block from Patsy's configuration
2. Run a verification pass on the tasks that regressed
3. Log the rollback in `results/transfer-log.md`
