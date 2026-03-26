# Transfer Experiment: Systematic Evaluation Pattern

**Source agent:** Rita (Research)
**Target agent:** Signora (Orchestration)
**Pattern:** Systematic evaluation of options against explicit criteria before committing to a choice
**Hypothesis:** Signora's routing decisions are fast but sometimes suboptimal. Applying Rita's systematic source evaluation pattern to routing decisions will improve decision quality on ambiguous requests without significantly increasing latency.
**Status:** Not started
**Created:** 2026-03-26

---

## The Source Pattern

Rita's research methodology improved after she adopted a systematic source evaluation process before deciding which sources to use. The pattern:

1. List all candidate sources for the question
2. Evaluate each source against explicit criteria: recency, authority, relevance, potential bias
3. Select 2-3 sources based on criteria, not habit or speed
4. Note why excluded sources were excluded

Before this change, Rita defaulted to the same 2-3 sources for everything. She was fast but missed better sources when the question was unusual. The systematic evaluation step slowed her down slightly on simple questions but improved coverage on hard ones.

**Note:** This experiment requires Rita's documented before/after scores. If those do not exist, label this as "speculative." Run it anyway. The result is informative either way.

---

## The Structural Pattern (Domain-Agnostic)

Extracted from Rita's research approach, independent of domain:

> When choosing between multiple options before acting:
> 1. Enumerate all candidate options explicitly (at least 3, even if some seem unlikely)
> 2. Define the criteria for selection before evaluating (not after)
> 3. Evaluate each candidate against all criteria, briefly
> 4. Select based on the evaluation, not first instinct
> 5. State the selection and the reason in one line before proceeding

---

## Before State

### Rita's Current State (Source)

Rita applies systematic source evaluation when answering research questions. Before the pattern, her routing through sources was habitual. After the pattern, she catches more edge cases and produces better-sourced answers on unusual topics.

**Rita's golden set scores** (for reference, not scored here):
- Unknown. Populate from `results/transfer-log.md` when available.

### Signora's Current State (Target)

Signora's current routing behavior for ambiguous requests:
- Tends to route to the first matching agent by role description
- Does not enumerate alternatives before deciding
- On multi-agent-capable tasks (e.g., "research and implement"), she tends to pick one agent rather than coordinating two
- Inconsistent on tasks that overlap between Ada and Patsy's domains

**Signora's baseline scores** (to be filled in before running):

| Task | Description | Success | Autonomy | Efficiency |
|------|-------------|---------|----------|------------|
| OR1 | Route an unambiguous request | ? | ? | ? |
| OR2 | Route an ambiguous ops+code task | ? | ? | ? |
| OR3 | Coordinate two agents in sequence | ? | ? | ? |
| OR4 | Decline a request outside all agents' domains | ? | ? | ? |
| OR5 | Handle a request with conflicting agent matches | ? | ? | ? |

These tasks need to be defined as a golden set for Signora before this experiment can run. See "Prerequisites" below.

---

## The Transfer: What to Apply to Signora

Add the following to Signora's routing logic or system prompt, under a section called "Routing Decision Protocol":

```
When deciding how to handle an incoming request:

1. CANDIDATES: List all agents that could plausibly handle this request, even partially.
2. CRITERIA: What matters for this request? (speed, depth, tool access, domain fit, risk)
3. EVALUATION: For each candidate, rate fit against the criteria in one sentence.
4. SELECTION: Choose the best fit or combination. If two agents are both useful, coordinate them.
5. RATIONALE: State the selection and reason before delegating.

Do not skip to delegation without completing steps 1-3.
For unambiguous requests (one clear match, no alternatives), a brief mental check is sufficient.
For ambiguous or multi-domain requests, work through all 5 steps explicitly.
```

This applies Rita's systematic source evaluation pattern to routing decisions instead of research source selection.

---

## Prerequisites

Signora does not currently have a formal golden set. Before running this experiment:

1. Create `golden-sets/signora-orchestration.md` with at least 10 tasks:
   - 4 routine routing tasks (single clear agent match)
   - 4 challenging routing tasks (ambiguous domain, multi-agent, or conflicting)
   - 2 edge cases (outside all domains, or requiring novel coordination)
2. Score a baseline run against this golden set
3. Record baseline in `results/transfer-log.md`

This is a prerequisite, not part of the transfer experiment itself. The experiment cannot run without a baseline.

---

## Success Metrics

The experiment is a success if Signora's scores on ambiguous and multi-domain routing tasks improve by 0.5+ on the Success dimension.

**Primary target tasks:**
- OR2 (Ambiguous ops+code task): +0.5 on Success
- OR3 (Coordinate two agents): +0.5 on Success AND +0.5 on Autonomy
- OR5 (Conflicting agent matches): +0.5 on Success

**Secondary (should not regress):**
- OR1, OR4: no dimension drops by more than 0.3

**Hypothesis for mechanism:** Explicit enumeration of candidates forces Signora to consider coordination options she currently skips. The criteria step prevents fast pattern-matching that routes to the wrong agent when a request is superficially ops-shaped but has a code component (or vice versa).

---

## Running the Experiment

### Before phase

1. Confirm Signora's golden set exists at `golden-sets/signora-orchestration.md`
2. Score all tasks from the golden set
3. Record scores in the baseline table above and in `results/transfer-log.md`

```bash
./scripts/run-transfer-experiment.sh experiments/memory-pattern-transfer.md --phase before
```

### Apply the pattern

1. Open Signora's system prompt or orchestration skill
2. Add the "Routing Decision Protocol" block above
3. Do not change any agent routing rules or available agents
4. Wait at least 24 hours before the after run

### After phase

5. Score Signora's golden set with identical task inputs
6. Do not reference before scores during scoring
7. Record scores in `results/transfer-log.md`

```bash
./scripts/run-transfer-experiment.sh experiments/memory-pattern-transfer.md --phase after
```

8. Compute deltas. The script handles this.

### Analysis

9. Did OR2, OR3, OR5 improve? Did OR1 and OR4 regress?
10. If the routing protocol slows down OR1 (simple tasks), that is an acceptable cost if OR3/OR5 improve. The protocol has a carve-out for unambiguous requests.
11. If Efficiency drops significantly on all tasks: the protocol is too heavy. Revise the carve-out criteria to trigger less often.
12. Write a qualitative observation in `results/transfer-log.md`.

---

## Expected Challenges

- **Latency on simple tasks:** The evaluation step adds tokens. Signora might over-apply it on obvious requests. Monitor Efficiency on OR1 and OR4.
- **Missing the golden set:** This experiment cannot run until Signora's golden set is created. That is a blocker, not a problem with the experiment design.
- **Proxy for real performance:** Signora's routing quality is hard to measure in isolation. The golden set tasks are synthetic. Supplement with observations from real sessions after the change.

---

## Rollback

If the experiment causes a regression:
1. Remove the "Routing Decision Protocol" block from Signora's configuration
2. Run a verification pass on the tasks that regressed
3. Log the rollback in `results/transfer-log.md`
