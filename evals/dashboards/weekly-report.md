# Agent Evaluation Dashboard

_Last updated: 2026-03-26 (Week 13 — Baseline)_

## Summary

| Agent | Sessions | Avg Success | Avg Autonomy | Avg Efficiency | Trend |
|-------|----------|-------------|--------------|----------------|-------|
| Ada 🔬 | 98 | — | — | — | Baseline |
| Patsy 🩹 | 17 | — | — | — | Baseline |
| Rita 🧠 | 13 | — | — | — | Baseline |
| Signora 🎭 | 100 | — | — | — | Baseline |

_Scores will populate after first manual review (Week 13 Friday)._

## Weekly Trend

| Week | Ada Success | Patsy Success | Rita Success | Signora Success | Total Incidents |
|------|-------------|---------------|--------------|-----------------|-----------------|
| W13 (baseline) | — | — | — | — | 76 keyword mentions |

## Key Insights

### Week 13 (Baseline)
- Framework established. Golden sets defined for Ada, Patsy, Rita, Signora.
- Automated metrics collection working.
- Manual scoring process defined (15 min Friday review).
- Cost tracking not yet integrated (pending Anthropic console access or API).

## Cost Tracking

_Not yet automated. Manual entry from Anthropic billing console._

| Week | Ada | Patsy | Rita | Signora | Others | Total |
|------|-----|-------|------|---------|--------|-------|
| W13 | — | — | — | — | — | — |

## imp@k Tracking

_Updated by running `scripts/compute-impk.sh` after each weekly review._

### imp@week (Weekly Performance Delta)

| Agent | W13 | W14 | W15 | W16 | Trend |
|-------|-----|-----|-----|-----|-------|
| Ada | baseline | -- | -- | -- | -- |
| Patsy | baseline | -- | -- | -- | -- |
| Rita | baseline | -- | -- | -- | -- |
| Signora | baseline | -- | -- | -- | -- |

Trend indicators: up improving, -> stable, down regressing

### imp@skill (Skill Impact Records)

_Updated by running `scripts/track-skill-impact.sh --after <skill> <agent>`._

| Agent | Skill | Before Avg | After Avg | imp@skill | Week |
|-------|-------|------------|-----------|-----------|------|
| -- | -- | -- | -- | -- | -- |

_Full history in `results/skill-impacts.json`._

## Methodology

- **Scoring:** 1-5 scale across Success, Autonomy, Efficiency
- **Source:** `evals/METHODOLOGY.md`
- **Golden sets:** `evals/golden-sets/`
- **Automated collection:** `evals/scripts/collect-metrics.sh`
- **imp@week:** `evals/scripts/compute-impk.sh`
- **imp@skill:** `evals/scripts/track-skill-impact.sh`
- **Review cadence:** Weekly (Friday), Monthly (first Monday)
