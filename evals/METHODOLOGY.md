# Evaluation Methodology

## Scoring Rubric (1-5 Scale)

### Task Success
| Score | Definition |
|-------|------------|
| 5 | Perfect execution. No corrections needed. Output ready to use/deploy. |
| 4 | Minor issues. Small tweaks needed (typo, formatting, non-functional). |
| 3 | Partial success. Core task done but significant gaps or errors. |
| 2 | Mostly failed. Some useful output but needs major rework. |
| 1 | Complete failure. Wrong approach, harmful output, or refused valid task. |

### Autonomy
| Score | Definition |
|-------|------------|
| 5 | Fully autonomous. No clarifying questions, no retries, figured out context. |
| 4 | One clarifying question or minor retry, but reasonable. |
| 3 | Multiple rounds of clarification or 2-3 retries needed. |
| 2 | Excessive hand-holding. Needed step-by-step guidance. |
| 1 | Could not proceed without constant intervention. |

### Efficiency
| Score | Definition |
|-------|------------|
| 5 | Minimal tokens/time for the task complexity. Clean, focused execution. |
| 4 | Slight overhead but reasonable. Minor tangents. |
| 3 | Notable waste. Explored wrong paths before finding the right one. |
| 2 | Significant waste. Long detours, repeated attempts, excessive tool calls. |
| 1 | Extreme waste. Burned tokens on irrelevant work or loops. |

## Automated Metrics

These are collected programmatically, not scored manually:

### Per-Session Metrics
- **Token count:** Input + output tokens (from session_status)
- **Cache hit rate:** % of cached tokens (efficiency indicator)
- **Wall clock time:** Start to final response
- **Tool call count:** Number of tool invocations
- **Error rate:** Failed tool calls / total tool calls

### Per-Agent Aggregate Metrics (Weekly)
- **Sessions count:** Total sessions in the period
- **Avg tokens per session:** Mean token usage
- **Task completion rate:** % of tasks scored 4+
- **Cost estimate:** Based on Opus pricing ($15/$75 per M input/output tokens)
- **Incidents:** Production issues caused by agent output

## Evaluation Process

### Weekly Review (15 min, every Friday)
1. Review that week's agent sessions (start with Ada, highest volume)
2. Score 3-5 representative tasks per agent using the rubric
3. Log in `results/YYYY-WXX.md`
4. Run `scripts/collect-metrics.sh` for automated numbers
5. Update `dashboards/weekly-report.md`

### Monthly Review (30 min, first Monday)
1. Compare weekly scores for trends
2. Identify regressions (score drops after changes)
3. Note which task types score lowest (training opportunities)
4. Update golden sets if task mix has shifted

## Golden Set Design Principles

Each golden set should include:
- **5 routine tasks** (common, should be trivially correct)
- **5 challenging tasks** (complex, tests limits)
- **3 edge cases** (ambiguous, incomplete info, conflicting requirements)
- **2 regression checks** (tasks that previously failed, now should pass)

Total: ~15 tasks per agent, refreshed quarterly.

## What Counts as a "Task"

A task is one coherent request/mission, even if it takes multiple messages:
- "Fix the Laravel log permission issue on rwmom" = 1 task
- "Review this PR" = 1 task
- "Research insurance options for Civiasco" = 1 task
- "What's the weather?" = too trivial, skip

Minimum complexity threshold: would take a human >5 min to do manually.

## imp@k Metrics

Inspired by Meta's HyperAgents paper, which defines improvement@k as the gain an agent achieves
over k iterations of a task. Our adaptation applies the same idea to time and skill additions.

### imp@week

imp@week is the change in an agent's average score from one week to the next.

```
imp@week = avg_score(current_week) - avg_score(previous_week)
```

Interpretation:
- Positive value: the agent improved this week
- Near zero (+/-0.1): stable performance
- Negative value: the agent regressed this week

Trend categories:
- **Improving:** imp@week > +0.1
- **Stable:** imp@week between -0.1 and +0.1
- **Regressing:** imp@week < -0.1

Computed by: `scripts/compute-impk.sh`

### imp@skill

imp@skill measures the performance change after a skill is added or modified.
It isolates the effect of a single skill on an agent's scoring.

```
imp@skill = avg_score(after_skill_deploy) - avg_score(before_skill_deploy)
```

Workflow:
1. Run `scripts/track-skill-impact.sh --before <skill> <agent>` before deploying
2. Deploy or update the skill
3. Run `scripts/track-skill-impact.sh --after <skill> <agent>` to record the delta
4. Results are stored in `results/skill-impacts.json`

A positive imp@skill means the skill measurably improved that agent's performance.
A near-zero result means the skill had no observable effect on eval scores.
A negative result is worth investigating (unexpected regression).

### Baseline Week

The first week's scores are the baseline. imp@week for week 1 is always "baseline" (no delta).
imp@skill can still be computed in week 1 if a before/after snapshot is taken.

## Baseline

First week's scores establish the baseline. All future comparisons are against this.
No score is "bad" in week 1. It's just where we start.
