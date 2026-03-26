# Transfer Experiment Template

Copy this file to `experiments/<short-name>.md` and fill in each section.

---

# Transfer Experiment: [Pattern Name]

**Source agent:** [Agent name and domain]
**Target agent:** [Agent name and domain]
**Pattern:** [One-sentence description of the structural pattern]
**Hypothesis:** [Why should this pattern help the target agent? Be specific about the mechanism.]
**Status:** Not started / In progress / Complete / Abandoned
**Created:** YYYY-MM-DD

---

## The Source Pattern

Describe what the source agent does and what changed when the pattern was applied. Include:
- What the agent was doing before
- What structural change was made
- What improved as a result (with scores if available)

If this is a speculative experiment (no documented improvement in the source agent), say so here.

---

## The Structural Pattern (Domain-Agnostic)

Extract the pattern from its domain. Write it as a general procedure that could apply anywhere.

> When [type of situation]:
> 1. [Step 1]
> 2. [Step 2]
> 3. [Step 3]
> ...

The domain-agnostic description is the key deliverable here. If you cannot write it without mentioning the source domain, you have not fully extracted the pattern yet.

---

## Before State

### Source Agent's State (for reference)
Brief description of the source agent's scores or behavior before and after the pattern. Reference `results/transfer-log.md` for specific numbers.

### Target Agent's Current State

Describe what the target agent currently does in the area the pattern would affect. Be specific about the failure mode you are trying to fix.

**Target agent's baseline scores** (fill in before running):

| Task ID | Description | Success | Autonomy | Efficiency |
|---------|-------------|---------|----------|------------|
| [ID] | [Task description] | ? | ? | ? |
| [ID] | [Task description] | ? | ? | ? |
| [ID] | [Task description] | ? | ? | ? |

List only the tasks you expect the pattern to affect, plus 2-3 tasks you expect to remain stable (control group).

---

## The Transfer: What to Apply to the Target Agent

Write the exact change to make. This should be copy-pasteable into a system prompt or skill file.

Include a section heading for where it belongs in the target agent's configuration.

```
[Exact text to add to the target agent's system prompt or skill]
```

Explain how this maps to the domain-agnostic pattern above.

---

## Prerequisites

List anything that must be true before this experiment can run:
- [ ] Target agent has a golden set at `golden-sets/[agent-name].md`
- [ ] Baseline scores have been recorded in `results/transfer-log.md`
- [ ] Source pattern has been documented (even if scores are not available)
- [ ] [Any other blockers]

---

## Success Metrics

State the specific threshold for success:

**Primary target tasks:** [Task IDs] must improve by [threshold] on [dimensions]
**Secondary tasks (must not regress):** [Task IDs] must not drop by more than 0.3 on any dimension

Explain the mechanism: why would this pattern cause improvement on those specific tasks?

---

## Running the Experiment

### Before phase

1. Score the target agent's relevant golden set tasks
2. Record scores in the table above
3. Record in `results/transfer-log.md`

```bash
./scripts/run-transfer-experiment.sh experiments/[this-file].md --phase before
```

### Apply the pattern

1. [Specific steps to apply the change]
2. Wait at least 24 hours before the after run

### After phase

3. Score the same tasks with identical inputs
4. Do not reference before scores during scoring

```bash
./scripts/run-transfer-experiment.sh experiments/[this-file].md --phase after
```

5. Review deltas. The script writes to `results/transfer-log.md`.

### Analysis

6. [What to look for in the results]
7. [When to keep the change vs. revert]
8. Write a qualitative observation in `results/transfer-log.md`

---

## Expected Challenges

List known risks or likely failure modes for this specific experiment.

---

## Rollback

How to undo the change if the experiment causes a regression.
