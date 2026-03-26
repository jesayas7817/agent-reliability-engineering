# Metrics

Quantitative tracking for agent performance over time. Goes beyond single-point evaluation to measure improvement velocity and the impact of changes.

## imp@k: The Improvement Metric

Inspired by Meta's HyperAgents paper (arXiv:2603.19461), which introduced improvement@k to measure how effectively a meta-agent generates improved variants within k iterations.

Our adaptation for production agent systems:

| Metric | What it measures | Formula |
|--------|-----------------|---------|
| **imp@week** | Weekly performance delta per agent | avg_score(week N) - avg_score(week N-1) |
| **imp@skill** | Performance change after adding a skill | avg_score(after) - avg_score(before) |

### Trend Categories

| imp@week | Trend | Meaning |
|----------|-------|---------|
| > +0.3 | Strong improvement | Something worked well, document what changed |
| +0.1 to +0.3 | Improving | Positive trajectory |
| -0.1 to +0.1 | Stable | No significant change |
| -0.3 to -0.1 | Regressing | Investigate what changed |
| < -0.3 | Strong regression | Roll back recent changes, review immediately |

## Scripts

### `collect-metrics.sh`

Gathers automated metrics from agent session logs and memory files.

```bash
# Last 7 days (default)
./scripts/collect-metrics.sh

# Specific end date
./scripts/collect-metrics.sh 2026-03-26
```

### `compute-impk.sh`

Calculates imp@week by comparing consecutive weekly result files.

```bash
# Auto-detect latest two weeks
./scripts/compute-impk.sh

# Specific week
./scripts/compute-impk.sh 2026-W14

# Compare two specific weeks
./scripts/compute-impk.sh 2026-W14 2026-W13
```

### `track-skill-impact.sh`

Measures the before/after impact of adding or modifying a skill.

```bash
# Before deploying a skill
./scripts/track-skill-impact.sh --before ada code-review-checklist

# After deploying and running evals
./scripts/track-skill-impact.sh --after ada code-review-checklist

# View results
./scripts/track-skill-impact.sh --list
```

Results stored in `results/skill-impacts.json`.

## Why This Matters

Single-point evaluation tells you "the agent scored 4.2 this week." That's useful but limited.

imp@k tells you "the agent improved by 0.5 after adding structured checklists to its code review skill." That's actionable. It tells you what to do more of and what to stop doing.

The HyperAgents paper showed that meta-level improvements (how agents improve) transfer across domains. Tracking imp@skill is how you discover which improvements have the broadest impact.
