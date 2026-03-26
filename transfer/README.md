# Cross-Agent Transfer Experiments

## What Is Transfer?

Transfer means taking an improvement pattern that works for one agent and applying the same structural change to a different agent operating in a different domain.

The core insight from HyperAgents (Meta, 2025): agents improve not just through domain-specific training but through structural patterns in how they approach problems. These patterns are domain-agnostic and can be extracted, documented, and applied elsewhere.

**Example:** Ada's structured code review checklist (multi-step, explicit criteria per category) is a pattern, not a code review tool. That same pattern applied to Patsy's incident triage might yield similar improvements in thoroughness and autonomy.

Transfer experiments test this hypothesis concretely.

## The Framework

A transfer experiment has three components:

### 1. The Source Pattern
A specific structural change that improved a source agent's scores. Must be:
- Documented with before/after golden set scores
- Described structurally (not domain-specifically)
- Abstract enough to apply elsewhere

### 2. The Target Agent + Task
An agent where the same structural pattern has not yet been applied. Must have:
- An existing golden set with baseline scores
- A plausible connection to the source pattern (not just "make it better")
- A clear hypothesis for why the pattern might help

### 3. The Measurement
Before and after scores on the target agent's golden set, focused on the dimensions the source pattern improved.

## How to Run a Transfer Experiment

### Step 1: Pick an Experiment
Read an experiment file from `experiments/`. Each one documents a specific transfer to attempt.

### Step 2: Establish the Before Baseline
Run the golden set against the target agent. Score all tasks using the standard rubric in `METHODOLOGY.md`. Record scores in the experiment file.

If scores already exist in `results/transfer-log.md` for this agent, use those as the baseline.

### Step 3: Apply the Pattern
Follow the experiment's "Applying the Pattern" section. This is the manual step: editing the agent's system prompt, adding a skill, or changing workflow instructions.

### Step 4: Run the Golden Set Again
Score the same tasks with the same rubric. Keep task inputs identical.

### Step 5: Compute the Delta
Calculate the change in target dimensions (usually autonomy and success).

Use `scripts/run-transfer-experiment.sh` to automate scoring extraction and logging:
```bash
./scripts/run-transfer-experiment.sh experiments/structured-checklist-transfer.md
```

### Step 6: Log Results
The script writes to `results/transfer-log.md`. Add a short summary of what you observed qualitatively.

## Measuring Success

Each experiment defines its own success threshold. The general criteria:

| Result | Criteria |
|--------|----------|
| Strong transfer | Target dimensions improve by 0.5+ on average |
| Weak transfer | Improvement exists but below 0.5 |
| Neutral | No change within noise margin (+-0.2) |
| Regression | Scores drop on any dimension by 0.3+ |

Score changes smaller than 0.3 are within normal run-to-run variance and should not be treated as meaningful.

A "successful" transfer does not mean the pattern works identically. It means the structural insight translated across domains.

## Important Constraints

- **Do not change the golden set tasks during an experiment.** Inputs must be identical before and after.
- **Score independently.** Do not read the before scores when scoring the after run.
- **Wait at least 24 hours between runs.** This prevents contamination from conversation context.
- **Log failures.** A failed transfer (no improvement) is valuable data. Record it.

## Current Experiments

| File | Source Agent | Target Agent | Pattern | Status |
|------|-------------|--------------|---------|--------|
| `structured-checklist-transfer.md` | Ada | Patsy | Structured multi-step checklist | Not started |
| `memory-pattern-transfer.md` | Rita | Signora | Systematic option evaluation | Not started |

## Designing New Experiments

Use `template.md` to create a new experiment. Before designing:
1. Identify a pattern that demonstrably improved a source agent (requires documented before/after scores)
2. Identify a target agent where that pattern is absent
3. Write a clear hypothesis for why it would help
4. Define specific success metrics before running

Speculative experiments (no documented source improvement) are allowed but must be labeled as such.
