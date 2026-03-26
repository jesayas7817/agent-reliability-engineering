[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

# Agent Reliability Engineering

**The missing discipline for production AI agent systems.**

You have agents in production. They break. They regress. They hallucinate. They cost too much. They fail silently. And right now, you are managing all of this with vibes.

There is no SRE for AI agents. No established practice for measuring agent reliability, tracking performance over time, diagnosing failures systematically, or improving agents through structured feedback loops. Every team deploying agents is reinventing the wheel, poorly, in isolation.

This repo changes that.

**Agent Reliability Engineering (AgentRE)** is a discipline that applies Site Reliability Engineering principles to AI agent systems. It gives you concrete tools to measure, monitor, improve, and operate agents at production scale.

This is not a theoretical framework. It was built from 14 months of running 9 AI agents in daily production (engineers, ops agents, researchers, orchestrators) across real workloads. Every tool in this repo exists because we needed it.

---

## Table of Contents

- [Why This Exists](#why-this-exists)
- [The SRE-to-Agent Map](#the-sre-to-agent-map)
- [Repository Structure](#repository-structure)
- [Modules](#modules)
  - [evals/ : Evaluation Framework](#evals--evaluation-framework)
  - [metrics/ : The imp@k System](#metrics--the-impk-system)
  - [transfer/ : Cross-Agent Transfer Experiments](#transfer--cross-agent-transfer-experiments)
  - [self-improve/ : Self-Improvement Pipeline](#self-improve--self-improvement-pipeline)
  - [config-versioning/ : Git-Based Config Snapshots](#config-versioning--git-based-config-snapshots)
  - [patterns/ : Production-Tested Multi-Agent Patterns](#patterns--production-tested-multi-agent-patterns)
- [Quick Start](#quick-start)
- [Philosophy](#philosophy)
- [Academic and Industry Connections](#academic-and-industry-connections)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)

---

## Why This Exists

Site Reliability Engineering transformed how we operate web services. Before SRE, companies ran servers with tribal knowledge, ad-hoc monitoring, and firefighting. SRE gave us SLOs, error budgets, postmortems, runbooks, and capacity planning. It turned operations from chaos into engineering.

AI agents are at the same inflection point today.

Companies are deploying agents into production workflows: coding assistants, ops automation, research pipelines, customer-facing bots. These agents interact with real systems, make real decisions, and cost real money. But the operational practices around them are stuck in the "tribal knowledge and firefighting" era.

Consider what happens when an agent starts performing worse:

- **How do you know?** Most teams have no metrics beyond "it feels slower" or "users are complaining."
- **Why did it degrade?** Was it a model update? A prompt change? A shift in input distribution? Without config versioning and eval baselines, you are guessing.
- **How do you fix it?** Without structured improvement processes, you tweak prompts randomly and hope for the best.
- **How do you prevent recurrence?** Without postmortems and memory consolidation, the same failure modes appear again and again.

AgentRE answers all of these questions with concrete, lightweight tooling.

### What This Is

- A practical framework for operating AI agents reliably
- Evaluation rubrics, metrics systems, and improvement pipelines
- Git-tracked configuration management for agent identities and skills
- Battle-tested patterns from 9 agents in daily production since February 2025

### What This Is Not

- A chatbot framework (use LangChain, CrewAI, OpenClaw, or whatever you prefer)
- An agent hosting platform
- A replacement for your existing agent infrastructure
- An academic exercise

AgentRE sits on top of whatever agent system you already run. It is the operational layer.

---

## The SRE-to-Agent Map

The core insight: most SRE concepts have direct agent equivalents. The mapping is not forced; it is natural. Agents are services. They have inputs, outputs, reliability characteristics, and failure modes.

| SRE Concept | Agent Equivalent | What It Looks Like in Practice |
|---|---|---|
| **SLOs / SLIs** | Agent success rates, autonomy scores, efficiency metrics | "This agent should complete 85% of tasks without human intervention" |
| **Error Budgets** | Acceptable failure rates per agent type | "Research agents can hallucinate 5% of the time; ops agents get 0.5%" |
| **Incident Response** | Agent failure diagnosis and recovery | Structured triage: identify failure type, root cause, remediation |
| **Runbooks** | Skills (modular procedural knowledge) | SKILL.md files: self-contained procedures an agent can follow |
| **Toil Reduction** | The Rule of Three | First time: solve it. Second time: recognize the pattern. Third time: codify as a skill |
| **Capacity Planning** | Model selection, cost optimization, fallback chains | Choosing the right model for each task; routing to cheaper models for simple work |
| **Chaos Engineering** | Agent stress testing | Model outages, ambiguous inputs, context overflow, contradictory instructions |
| **Postmortems** | Memory consolidation | Daily logs distilled into curated long-term memory; lessons that persist |
| **Change Management** | Config versioning | Git-tracked SOUL.md, IDENTITY.md, skills; tagged with eval scores |
| **Monitoring / Alerting** | Eval trend tracking | Weekly reviews catch regressions before users notice |
| **On-call Rotation** | Escalation policies | When agent fails, who gets paged? What is the human fallback? |
| **Deployment Canaries** | Gradual config rollouts | Test prompt changes on one agent before fleet-wide deployment |

Let's walk through each mapping in detail.

### SLOs and SLIs for Agents

In traditional SRE, a Service Level Objective defines target reliability: "99.9% of requests complete in under 200ms." Service Level Indicators are the measurements that track progress toward that target.

For agents, the equivalent SLIs are:

| SLI | What It Measures | Example Target |
|---|---|---|
| **Success Rate** | Percentage of tasks completed correctly | > 85% for engineering agents |
| **Autonomy Score** | Tasks completed without human intervention | > 70% for ops agents |
| **Efficiency** | Resource usage relative to task complexity | < $0.50 per coding task |
| **First-attempt Resolution** | Tasks solved without retries or corrections | > 60% for research agents |
| **Time to Completion** | Wall-clock time for standard task types | < 5 min for routine ops tasks |

The key insight: you do not need all of these for every agent. Pick 2-3 SLIs per agent type that capture what "working well" means for that specific role.

### Incident Response for Agent Failures

Agent failures are different from service outages. They are often subtle: the agent completes the task but does it wrong. Or it completes the task correctly but takes 10x longer than it should. Or it succeeds on the surface but makes a decision that causes problems downstream.

AgentRE defines a failure taxonomy:

| Failure Type | Description | Severity | Example |
|---|---|---|---|
| **Hard Failure** | Agent cannot complete the task at all | P1 | Model API returns 500, agent crashes |
| **Wrong Output** | Agent completes task but result is incorrect | P1-P2 | Code compiles but has logic bugs |
| **Partial Completion** | Agent does some of the task, misses parts | P2 | Fixes the bug but forgets to update tests |
| **Excessive Cost** | Task completed but resource usage is unreasonable | P3 | $12 in API calls for a one-line fix |
| **Silent Regression** | Agent works but quality has degraded over time | P2 | Success rate dropped from 90% to 75% over a month |
| **Autonomy Failure** | Agent asks for help when it should not need to | P3 | Requests approval for routine, well-documented tasks |
| **Boundary Violation** | Agent takes actions outside its defined scope | P1 | Ops agent modifies production configs without approval |

Each failure type has a corresponding investigation template in the `evals/` module.

### From Runbooks to Skills

SRE runbooks are step-by-step procedures for handling known incidents. They encode operational knowledge so that on-call engineers do not have to rediscover solutions.

For agents, the equivalent is **Skills**: modular, self-contained procedural knowledge stored in a standard format (SKILL.md). A skill tells an agent exactly how to handle a specific class of tasks.

```
~/.agent/skills/
├── deploy-backend/
│   ├── SKILL.md          # What to do, step by step
│   ├── scripts/
│   │   └── deploy.sh     # Automation scripts
│   └── references/
│       └── api-docs.md   # Context the agent needs
├── fix-permissions/
│   └── SKILL.md
└── review-pr/
    ├── SKILL.md
    └── references/
        └── style-guide.md
```

The SKILL.md format:

```markdown
# Deploy Backend

## Description
Deploy the backend service to staging or production.

## Triggers
- "deploy backend"
- "push to staging"
- "release backend v*"

## Prerequisites
- SSH access to deployment server
- Git credentials configured
- Service health endpoint accessible

## Steps
1. Pull latest from main branch
2. Run test suite (abort if failures)
3. Build Docker image with version tag
4. Push to registry
5. SSH to target server
6. Pull new image and restart service
7. Verify health endpoint returns 200
8. Notify channel with deployment status

## Rollback
If health check fails after step 7:
1. SSH to target server
2. Revert to previous image tag
3. Restart service
4. Verify health endpoint
5. File incident report

## Notes
- Production deploys require explicit human approval
- Staging deploys can run autonomously
```

Skills are the agent equivalent of institutional knowledge. Without them, every agent session starts from zero. With them, agents improve cumulatively.

### The Rule of Three (Toil Reduction)

SRE defines "toil" as repetitive, automatable work that scales linearly with service size. The goal is to eliminate toil through automation.

For agents, the equivalent is the **Rule of Three**:

1. **First time:** Solve the problem manually. The agent figures it out.
2. **Second time:** Recognize the pattern. "I have seen this before."
3. **Third time:** Codify it as a skill. Now the agent (and all similar agents) can handle it automatically.

This is not just a philosophy. The `self-improve/` module implements it concretely: it tracks recurring task patterns and proposes skill creation when a pattern appears three or more times.

### Chaos Engineering for Agents

Traditional chaos engineering (Chaos Monkey, Gremlin) tests service resilience by introducing failures deliberately. For agents, the equivalent stress tests include:

| Chaos Test | What It Simulates | What You Learn |
|---|---|---|
| **Model Outage** | Primary model API returns errors | Does the fallback chain work? How graceful is degradation? |
| **Ambiguous Input** | Vague, contradictory, or incomplete task descriptions | Does the agent ask for clarification or guess badly? |
| **Context Overflow** | Tasks that exceed the model's context window | Does the agent handle truncation? Does it chunk correctly? |
| **Stale Context** | Outdated information in agent memory | Does the agent verify assumptions or act on stale data? |
| **Rate Limiting** | API throttling during multi-step tasks | Does the agent retry gracefully? Does it lose progress? |
| **Permission Denial** | Expected tool access revoked mid-task | Does the agent fail safely or attempt workarounds? |
| **Concurrent Tasks** | Multiple tasks assigned simultaneously | Does quality degrade? Does the agent prioritize correctly? |

You do not need to run all of these. Start with model outage and ambiguous input. Those two cover the most common real-world failure modes.

### Memory Consolidation (Postmortems)

SRE postmortems capture what went wrong, why, and how to prevent recurrence. They turn incidents into institutional knowledge.

For agents, the equivalent is **memory consolidation**: the process of distilling raw daily logs into curated long-term memory.

```
Day 1-7: Raw daily logs (memory/2026-03-19.md, etc.)
   ↓
Weekly review: Extract patterns, lessons, significant events
   ↓
Long-term memory: MEMORY.md (curated, distilled, actionable)
   ↓
Periodically: Prune outdated entries, reinforce important ones
```

Without memory consolidation, agents repeat the same mistakes. With it, they accumulate operational wisdom, just like a human engineer who writes things down.

---

## Repository Structure

```
agent-reliability-engineering/
│
├── README.md                     # You are here
├── LICENSE                       # MIT
│
├── evals/                        # Evaluation framework
│   ├── README.md                 # Eval system documentation
│   ├── rubrics/                  # Scoring rubrics (1-5 scale)
│   │   ├── success.md            # Task completion quality
│   │   ├── autonomy.md           # Independence from human help
│   │   └── efficiency.md         # Resource usage and speed
│   ├── golden-sets/              # Reference tasks per agent type
│   │   ├── engineer.yaml         # Coding agent test cases
│   │   ├── ops.yaml              # Operations agent test cases
│   │   ├── research.yaml         # Research agent test cases
│   │   └── orchestrator.yaml     # Orchestrator agent test cases
│   ├── templates/                # Weekly review templates
│   │   └── weekly-review.md      # 15-minute Friday review
│   └── scripts/                  # Automation
│       ├── collect-metrics.sh    # Gather eval data
│       └── generate-report.sh   # Weekly summary
│
├── metrics/                      # imp@k metrics system
│   ├── README.md                 # Metrics documentation
│   ├── schema.yaml               # Metric definitions
│   ├── examples/                 # Sample data
│   │   ├── imp-at-week.json      # Weekly performance delta
│   │   └── imp-at-skill.json     # Skill addition impact
│   ├── scripts/                  # Analysis tools
│   │   ├── calculate-imp.py      # Core metric calculation
│   │   ├── trend-detect.py       # Trend classification
│   │   └── visualize.py          # Simple charts
│   └── dashboards/               # Optional visualization configs
│       └── grafana.json          # Grafana dashboard template
│
├── transfer/                     # Cross-agent transfer experiments
│   ├── README.md                 # Transfer framework docs
│   ├── experiment-template.yaml  # Blank experiment scaffold
│   ├── verdict-criteria.md       # Transfer/Weak/Neutral/Regression
│   ├── examples/                 # Completed experiments
│   │   └── skill-decomposition-transfer.yaml
│   └── scripts/                  # Measurement tools
│       ├── before-measure.sh     # Pre-experiment baseline
│       └── after-measure.sh      # Post-experiment measurement
│
├── self-improve/                 # Self-improvement pipeline
│   ├── README.md                 # Pipeline documentation
│   ├── analyzer.py               # Eval data analysis
│   ├── proposal-template.md      # Improvement proposal format
│   ├── safety-rails.md           # What agents can and cannot modify
│   └── examples/                 # Sample proposals
│       └── add-retry-skill.md    # Example: proposing a new skill
│
├── config-versioning/            # Git-based config management
│   ├── README.md                 # Versioning documentation
│   ├── scripts/
│   │   ├── snapshot.sh           # Capture current config state
│   │   ├── diff.sh               # Compare two snapshots
│   │   └── rollback.sh           # Restore previous config
│   ├── schema.yaml               # Config file inventory
│   └── examples/
│       └── snapshot-2026-03-15/  # Example snapshot
│           ├── agent-ada/
│           │   ├── SOUL.md
│           │   ├── IDENTITY.md
│           │   └── skills.list
│           └── agent-signora/
│               ├── SOUL.md
│               ├── IDENTITY.md
│               └── skills.list
│
└── patterns/                     # Multi-agent pattern library
    ├── README.md                 # Pattern catalog overview
    └── PATTERNS.md               # Links to companion repo
```

---

## Modules

### evals/ : Evaluation Framework

The evaluation framework is the foundation of AgentRE. You cannot improve what you do not measure. But you also cannot measure everything, and trying to do so guarantees you will measure nothing consistently.

This framework is intentionally lightweight: three dimensions, a 1-5 scale, and 15 minutes per week.

#### The Three Dimensions

| Dimension | What It Measures | Scale |
|---|---|---|
| **Success** | Did the agent complete the task correctly? | 1 (failed) to 5 (perfect) |
| **Autonomy** | Did the agent work independently? | 1 (needed constant help) to 5 (fully autonomous) |
| **Efficiency** | Were time and resources used well? | 1 (wasteful) to 5 (optimal) |

#### Scoring Rubric: Success

| Score | Meaning | Example |
|---|---|---|
| **5** | Perfect execution. No corrections needed. | PR merged without changes. |
| **4** | Minor issues. Small corrections. | PR merged with 1-2 nit fixes. |
| **3** | Adequate. Notable gaps but core task done. | Code works but tests are missing. |
| **2** | Significant issues. Major rework required. | Wrong approach, needs redesign. |
| **1** | Failed. Task not completed or output unusable. | Agent hallucinated a nonexistent API. |

#### Scoring Rubric: Autonomy

| Score | Meaning | Example |
|---|---|---|
| **5** | Fully autonomous. No human input after initial task. | Deployed to staging, ran tests, reported results. |
| **4** | Minimal help. One clarifying question. | "Should I target Node 20 or 22?" |
| **3** | Moderate help. Needed guidance at a decision point. | "The tests are failing, should I fix or skip?" |
| **2** | Heavy assistance. Multiple interventions. | Needed help with 3+ steps of the process. |
| **1** | Could not proceed without constant hand-holding. | Asked for help at every step. |

#### Scoring Rubric: Efficiency

| Score | Meaning | Example |
|---|---|---|
| **5** | Optimal resource usage. Fast and cheap. | Completed in 2 min, $0.03 API cost. |
| **4** | Good efficiency. Minor waste. | Completed in 5 min, one unnecessary retry. |
| **3** | Acceptable. Some wasted effort. | Explored two wrong approaches before finding the right one. |
| **2** | Inefficient. Significant waste. | Used GPT-4 for a task that Haiku could handle. |
| **1** | Extremely wasteful. | $8 in API calls for a task worth $0.50. |

#### Golden Sets

Golden sets are curated collections of representative tasks for each agent type. They serve as regression tests: run the golden set periodically and compare scores over time.

```yaml
# golden-sets/engineer.yaml
name: Engineering Agent Golden Set
version: 2
agent_type: engineer
tasks:
  - id: eng-001
    name: "Fix off-by-one error"
    description: "Fix the off-by-one error in pagination logic (file: src/pagination.ts, line 42)"
    difficulty: easy
    expected_time: "< 3 min"
    success_criteria:
      - Bug is fixed
      - Tests pass
      - No unrelated changes
    tags: [bugfix, typescript]

  - id: eng-002
    name: "Add retry logic to API client"
    description: "Add exponential backoff retry to the HTTP client in src/api/client.py"
    difficulty: medium
    expected_time: "< 10 min"
    success_criteria:
      - Retry logic implemented with exponential backoff
      - Maximum retry count configurable
      - Tests cover retry scenarios
      - Existing tests still pass
    tags: [feature, python, resilience]

  - id: eng-003
    name: "Review PR with security issue"
    description: "Review PR #147. It contains an SQL injection vulnerability in the search endpoint."
    difficulty: hard
    expected_time: "< 15 min"
    success_criteria:
      - SQL injection identified
      - Clear explanation of the vulnerability
      - Suggested fix provided
      - No false positives
    tags: [review, security]

  - id: eng-004
    name: "Refactor module with circular dependency"
    description: "Refactor src/services/ to eliminate the circular dependency between auth.ts and user.ts"
    difficulty: hard
    expected_time: "< 20 min"
    success_criteria:
      - Circular dependency eliminated
      - All tests pass
      - No functionality changes
      - Clean commit history
    tags: [refactor, typescript, architecture]
```

Each agent type (engineer, ops, research, orchestrator) has its own golden set with 10-20 tasks spanning easy, medium, and hard difficulties.

#### The Weekly Review (15 Minutes, Every Friday)

```markdown
# Weekly Agent Review - Week of [DATE]

## Quick Scores (2 min)

| Agent | Tasks | Avg Success | Avg Autonomy | Avg Efficiency | Trend |
|-------|-------|-------------|--------------|----------------|-------|
| Ada   | 23    | 4.2         | 3.8          | 4.0            | ↑     |
| Rita  | 15    | 3.9         | 4.1          | 3.5            | →     |
| Bruno | 31    | 4.5         | 4.3          | 4.2            | ↑     |
| ...   | ...   | ...         | ...          | ...            | ...   |

## Notable Events (3 min)

- [ ] Any hard failures this week?
- [ ] Any new failure patterns?
- [ ] Any tasks that took unexpectedly long?
- [ ] Any tasks where the wrong agent was assigned?

## Improvements Applied (3 min)

- [ ] Skills added or updated?
- [ ] Config changes made?
- [ ] Model changes?
- [ ] What was the impact?

## Proposed Actions (5 min)

- [ ] Skills to create (Rule of Three candidates)?
- [ ] Config changes to test?
- [ ] Golden set updates needed?
- [ ] Anything to investigate deeper?

## imp@week Scores (2 min)

| Agent | imp@week | Classification |
|-------|----------|----------------|
| Ada   | +0.3     | Improving       |
| Rita  | +0.0     | Stable          |
| Bruno | +0.4     | Improving       |
| ...   | ...      | ...             |
```

That is it. Fifteen minutes. If you cannot sustain a practice in 15 minutes per week, you will not sustain it at all.

---

### metrics/ : The imp@k System

Traditional evaluation gives you a snapshot: "This agent scored 4.2 on success." That is useful but insufficient. What you really need to know is: **is this agent getting better or worse?**

The imp@k (improvement-at-k) metrics system tracks performance deltas over time. It is inspired by Meta's HyperAgents paper (arXiv:2603.19461), which introduced the concept of measuring self-improvement rates in agent systems.

#### Core Metrics

| Metric | Formula | What It Tells You |
|---|---|---|
| **imp@week** | `avg_score(this_week) - avg_score(last_week)` | Weekly performance trajectory |
| **imp@skill** | `avg_score(after_skill) - avg_score(before_skill)` | Impact of a specific skill addition |
| **imp@config** | `avg_score(after_change) - avg_score(before_change)` | Impact of a config change |
| **imp@model** | `avg_score(new_model) - avg_score(old_model)` | Impact of switching models |

#### Trend Classification

```
imp@week > +0.2  → Improving  ↑
imp@week ∈ [-0.2, +0.2] → Stable  →
imp@week < -0.2  → Regressing  ↓
```

Three consecutive weeks of regression triggers an investigation. Not a panic, an investigation. Maybe the tasks got harder. Maybe the model provider shipped an update. Maybe a skill is interfering with other skills. The point is: you notice.

#### Example: imp@skill Measurement

```json
{
  "experiment": "add-retry-skill-to-ada",
  "agent": "ada",
  "skill": "api-retry-handling",
  "measurement_window": "2 weeks before, 2 weeks after",
  "before": {
    "period": "2026-03-01 to 2026-03-14",
    "tasks_evaluated": 28,
    "avg_success": 3.8,
    "avg_autonomy": 3.5,
    "avg_efficiency": 3.2
  },
  "after": {
    "period": "2026-03-15 to 2026-03-28",
    "tasks_evaluated": 31,
    "avg_success": 4.3,
    "avg_autonomy": 4.0,
    "avg_efficiency": 3.9
  },
  "imp_at_skill": {
    "success": 0.5,
    "autonomy": 0.5,
    "efficiency": 0.7
  },
  "verdict": "Significant improvement across all dimensions",
  "notes": "API-related tasks improved most. No regression in non-API tasks."
}
```

#### Visualization

The metrics module includes simple visualization scripts. Nothing fancy. A line chart of weekly averages per agent is enough to spot trends:

```
Agent: Ada - Success Score (12 weeks)
5.0 |                              ·  ·
4.5 |              ·  ·  ·  ·  ·
4.0 |     ·  ·  ·
3.5 |  ·
3.0 |
    +--+--+--+--+--+--+--+--+--+--+--+--
     W1 W2 W3 W4 W5 W6 W7 W8 W9 W10 W11 W12
```

If you already run Grafana, there is a dashboard template in `dashboards/grafana.json`.

---

### transfer/ : Cross-Agent Transfer Experiments

One of the most interesting findings from Meta's HyperAgents paper is that improvements can transfer across domains. A meta-level skill learned by one agent type can benefit a completely different agent type.

The transfer module provides a framework for testing this systematically.

#### The Transfer Question

When you improve Agent A (say, by adding a skill for better error handling), does that same improvement help Agent B? The answer is not always obvious. Sometimes improvements are domain-specific. Sometimes they generalize. You need to measure.

#### Experiment Template

```yaml
# transfer/experiment-template.yaml
experiment:
  name: "[Descriptive Name]"
  date: "YYYY-MM-DD"
  hypothesis: "Improvement X from Agent A will transfer to Agent B"

source:
  agent: "[Source agent name]"
  agent_type: "[engineer|ops|research|orchestrator]"
  improvement: "[What was changed]"
  imp_at_skill: "[Measured improvement in source agent]"

target:
  agent: "[Target agent name]"
  agent_type: "[engineer|ops|research|orchestrator]"

baseline:
  period: "[Date range]"
  tasks_evaluated: 0
  avg_success: 0.0
  avg_autonomy: 0.0
  avg_efficiency: 0.0

treatment:
  period: "[Date range]"
  tasks_evaluated: 0
  avg_success: 0.0
  avg_autonomy: 0.0
  avg_efficiency: 0.0

transfer_score:
  success_delta: 0.0
  autonomy_delta: 0.0
  efficiency_delta: 0.0

verdict: "[Transfer|Weak Transfer|Neutral|Regression]"
notes: ""
```

#### Verdict Criteria

| Verdict | Criteria | Meaning |
|---|---|---|
| **Transfer** | All dimensions improved by > +0.2 | The improvement generalizes well |
| **Weak Transfer** | At least one dimension improved by > +0.2, none regressed | Partial generalization |
| **Neutral** | No significant changes in any dimension | Domain-specific improvement, does not generalize |
| **Regression** | Any dimension worsened by > -0.2 | The improvement actively hurts this agent type |

#### Example: Does Skill Decomposition Transfer?

```yaml
experiment:
  name: "Task Decomposition Skill Transfer: Engineer to Research"
  date: "2026-03-20"
  hypothesis: >
    Teaching the engineering agent to decompose complex tasks into
    subtasks will also help the research agent handle multi-step
    research questions.

source:
  agent: "Ada"
  agent_type: "engineer"
  improvement: "Added task-decomposition skill with structured subtask planning"
  imp_at_skill:
    success: +0.6
    autonomy: +0.4
    efficiency: +0.3

target:
  agent: "Rita"
  agent_type: "research"

baseline:
  period: "2026-03-01 to 2026-03-10"
  tasks_evaluated: 18
  avg_success: 3.7
  avg_autonomy: 3.9
  avg_efficiency: 3.4

treatment:
  period: "2026-03-11 to 2026-03-20"
  tasks_evaluated: 21
  avg_success: 4.1
  avg_autonomy: 4.0
  avg_efficiency: 3.6

transfer_score:
  success_delta: +0.4
  autonomy_delta: +0.1
  efficiency_delta: +0.2

verdict: "Weak Transfer"
notes: >
  Success improved significantly. The research agent now breaks
  complex queries into structured sub-questions, similar to how
  the engineering agent breaks tasks into subtasks. Autonomy
  gain was minimal, efficiency gain was borderline significant.
  The core pattern (decompose before executing) transfers, but
  the research-specific benefits are less pronounced than the
  engineering benefits.
```

Transfer experiments are the most advanced part of AgentRE. Start with evals and metrics first. Come back to transfer experiments once you have baseline data for multiple agent types.

---

### self-improve/ : Self-Improvement Pipeline

This is where it gets interesting. The self-improvement pipeline allows agents to analyze their own performance data, identify weaknesses, and propose improvements for human review.

**Critical safety note:** Agents propose. Humans approve. Always. No exceptions.

#### How It Works

```
┌─────────────────┐
│   Eval Data      │  Weekly scores, failure logs, task history
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Analyzer       │  Identifies patterns: recurring failures, score drops,
│                  │  tasks where the agent struggles consistently
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Proposal       │  Generates improvement suggestions:
│   Generator      │  new skills, config tweaks, prompt adjustments
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Human Review   │  Human evaluates proposals, approves or rejects
│                  │  with feedback
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Implementation │  Approved changes are applied
│   + Measurement  │  imp@skill / imp@config tracks impact
└─────────────────┘
```

#### Proposal Format

```markdown
# Improvement Proposal: [Title]

## Agent
[Agent name and type]

## Problem Identified
[What the data shows: specific scores, failure patterns, recurring issues]

## Evidence
- Task [ID]: Score 2/5 on success (failure reason: ...)
- Task [ID]: Score 2/5 on success (same failure pattern)
- Task [ID]: Score 3/5, partial completion due to same root cause
- Pattern frequency: 4 occurrences in past 2 weeks

## Proposed Solution
[Specific change: new skill, config modification, prompt addition]

## Expected Impact
- Success: +0.3 to +0.5 (fewer failures in [category])
- Autonomy: +0.2 (agent will not need to ask for help on [pattern])
- Efficiency: neutral (no expected change)

## Risk Assessment
- Low risk: change is additive (new skill), does not modify existing behavior
- Rollback: remove skill file, no config changes needed

## Implementation
[Concrete steps to implement this change]

## Measurement Plan
- Compare 2 weeks before vs. 2 weeks after
- Focus on tasks tagged [relevant tags]
- Run golden set tasks [IDs] before and after
```

#### Safety Rails

The self-improvement pipeline has explicit boundaries:

| Agents CAN propose | Agents CANNOT propose |
|---|---|
| New skills (SKILL.md files) | Changes to their own SOUL.md or IDENTITY.md |
| Config parameter adjustments | Changes to safety boundaries |
| New tool usage patterns | New external integrations |
| Prompt refinements | Permission escalations |
| Workflow optimizations | Changes to other agents' configs |

These rails are not arbitrary restrictions. They exist because identity and safety configurations require human judgment. An agent optimizing its own identity definition creates misaligned incentive structures. Keep the human in the loop for anything that changes what the agent *is*, not just what it *does*.

---

### config-versioning/ : Git-Based Config Snapshots

Agent configurations are code. Treat them that way.

Every agent has configuration files that define its identity, personality, skills, and operational parameters. When these change, you need to know what changed, when, and why, especially when performance shifts.

#### What Gets Versioned

```
agent-configs/
├── agent-ada/                  # Engineering agent
│   ├── SOUL.md                 # Core identity and personality
│   ├── IDENTITY.md             # Role definition
│   ├── skills/                 # Skill inventory
│   │   ├── deploy-backend/
│   │   │   └── SKILL.md
│   │   ├── review-pr/
│   │   │   └── SKILL.md
│   │   └── fix-tests/
│   │       └── SKILL.md
│   └── config.yaml             # Operational parameters
│
├── agent-signora/              # Orchestrator agent
│   ├── SOUL.md
│   ├── IDENTITY.md
│   ├── skills/
│   └── config.yaml
│
└── ...                         # One directory per agent
```

#### Snapshot Script

```bash
#!/bin/bash
# config-versioning/scripts/snapshot.sh
# Take a point-in-time snapshot of all agent configs

SNAPSHOT_DIR="snapshots/$(date +%Y-%m-%d-%H%M)"
mkdir -p "$SNAPSHOT_DIR"

for agent_dir in ~/.agents/*/; do
    agent_name=$(basename "$agent_dir")
    dest="$SNAPSHOT_DIR/$agent_name"
    mkdir -p "$dest"

    # Copy core config files
    cp -r "$agent_dir/SOUL.md" "$dest/" 2>/dev/null
    cp -r "$agent_dir/IDENTITY.md" "$dest/" 2>/dev/null
    cp -r "$agent_dir/config.yaml" "$dest/" 2>/dev/null

    # Copy skill manifest (not full skill content)
    if [ -d "$agent_dir/skills" ]; then
        find "$agent_dir/skills" -name "SKILL.md" -exec \
            sh -c 'dest_path="$1/${2#$3}"; mkdir -p "$(dirname "$dest_path")"; cp "$2" "$dest_path"' \
            _ "$dest" {} "$agent_dir" \;
    fi
done

# Commit snapshot
cd "$(dirname "$SNAPSHOT_DIR")"
git add .
git commit -m "Config snapshot: $(date +%Y-%m-%d %H:%M)"

echo "Snapshot saved to $SNAPSHOT_DIR"
```

#### Diff Script

```bash
#!/bin/bash
# config-versioning/scripts/diff.sh
# Compare two config snapshots

if [ $# -ne 2 ]; then
    echo "Usage: diff.sh <snapshot-1> <snapshot-2>"
    exit 1
fi

echo "=== Config Diff: $1 vs $2 ==="
echo ""

diff -rq "snapshots/$1" "snapshots/$2" | while read -r line; do
    echo "$line"
done

echo ""
echo "=== Detailed Changes ==="
diff -ru "snapshots/$1" "snapshots/$2" --color=always
```

#### Tagging with Eval Scores

The real power of config versioning comes from tagging snapshots with eval scores:

```bash
# After weekly review, tag the current config state with scores
git tag -a "v2026-w12" -m "Week 12: Ada=4.2/3.8/4.0, Rita=3.9/4.1/3.5, Bruno=4.5/4.3/4.2"
```

Now when you see a performance regression, you can:

1. Look at the score trend to identify when it started
2. Diff the config snapshots from before and after the regression
3. Identify exactly what changed
4. Rollback if needed

```bash
# "Ada regressed in week 14. What changed since week 12?"
./scripts/diff.sh 2026-03-15-1800 2026-03-29-1800

# Output shows: SOUL.md modified, new skill added, config.yaml model changed
# Now you know where to look.
```

---

### patterns/ : Production-Tested Multi-Agent Patterns

The `patterns/` directory links to the companion repository [multi-agent-patterns](https://github.com/wanderclan/multi-agent-patterns), which documents 9 architectural patterns tested in production:

| Pattern | Description | When to Use |
|---|---|---|
| **Orchestrator-Worker** | Central agent delegates to specialized workers | Complex tasks requiring multiple skills |
| **Pipeline** | Sequential chain of specialized agents | Document processing, data transformation |
| **Debate** | Multiple agents argue, one synthesizes | Decision-making, risk assessment |
| **Fallback Chain** | Cascade through agents/models on failure | High-availability requirements |
| **Human-in-the-Loop** | Agent works, human approves at gates | Safety-critical operations |
| **Parallel Fan-Out** | Multiple agents tackle same task, best result wins | When quality matters more than cost |
| **Specialist Router** | Classify task, route to best agent | Mixed workloads with diverse task types |
| **Memory-Sharing** | Agents read/write shared memory stores | Collaborative long-running projects |
| **Self-Eval Loop** | Agent evaluates own output, iterates | Tasks where quality is verifiable |

Each pattern includes:
- When to use it (and when not to)
- Architecture diagram
- Implementation guidance
- Failure modes and mitigations
- Real performance data from production usage

---

## Quick Start

You can adopt AgentRE incrementally. Here is how to get meaningful value in 30 minutes.

### Minute 0-5: Set Up Eval Tracking

Create a simple spreadsheet or markdown file. One row per evaluated task.

```markdown
# Agent Evals - Week of 2026-03-24

| Date | Agent | Task | Success | Autonomy | Efficiency | Notes |
|------|-------|------|---------|----------|------------|-------|
| 03-24 | Ada | Fix pagination bug | 5 | 5 | 4 | Clean fix, fast | 
| 03-24 | Ada | Add auth middleware | 4 | 3 | 3 | Needed help with token refresh |
| 03-25 | Rita | Research competitor pricing | 4 | 5 | 4 | Thorough, independent |
```

You do not need to evaluate every task. Aim for 5-10 per agent per week. Enough to see patterns, few enough to sustain.

### Minute 5-15: Define Your Agents' SLIs

For each agent, pick 2-3 metrics that define "working well."

```yaml
# my-agents.yaml
agents:
  - name: "Ada"
    type: engineer
    slis:
      - metric: success_rate
        target: "> 85% of tasks score 4+"
      - metric: autonomy
        target: "> 70% of tasks score 4+"

  - name: "Rita"
    type: research
    slis:
      - metric: success_rate
        target: "> 80% of tasks score 4+"
      - metric: efficiency
        target: "Average API cost < $1 per task"

  - name: "Signora"
    type: orchestrator
    slis:
      - metric: routing_accuracy
        target: "> 90% tasks routed to correct agent"
      - metric: autonomy
        target: "> 80% of tasks score 4+"
```

### Minute 15-20: Create Your First Golden Set

Pick 5 representative tasks for your most important agent. These are your regression tests.

```yaml
# golden-sets/my-engineer.yaml
tasks:
  - id: 1
    name: "Fix simple bug"
    description: "Fix the TypeError in src/utils.py line 23"
    difficulty: easy
    success_criteria: ["Bug fixed", "Tests pass"]

  - id: 2
    name: "Add feature"
    description: "Add rate limiting to the /api/search endpoint"
    difficulty: medium
    success_criteria: ["Rate limiting works", "Tests added", "Docs updated"]

  - id: 3
    name: "Code review"
    description: "Review PR #42, check for security issues"
    difficulty: medium
    success_criteria: ["Security issues identified", "Clear feedback"]

  - id: 4
    name: "Refactor"
    description: "Extract the email logic from UserService into EmailService"
    difficulty: hard
    success_criteria: ["Clean separation", "All tests pass", "No behavior changes"]

  - id: 5
    name: "Debug production issue"
    description: "Investigate why /api/users returns 500 for accounts created before 2024"
    difficulty: hard
    success_criteria: ["Root cause identified", "Fix proposed", "Reproduction steps documented"]
```

### Minute 20-25: Set Up Config Versioning

```bash
# Create a config tracking directory
mkdir -p ~/agent-configs
cd ~/agent-configs
git init

# Copy your current agent configs
mkdir -p agent-ada agent-signora  # etc.
cp ~/.agents/ada/SOUL.md agent-ada/
cp ~/.agents/ada/IDENTITY.md agent-ada/
# ... repeat for each agent

# Initial commit
git add .
git commit -m "Initial config snapshot"
```

From now on, every time you change an agent's configuration, commit the change with a descriptive message.

### Minute 25-30: Schedule Your First Weekly Review

Put 15 minutes on your calendar for Friday afternoon. Use the weekly review template from `evals/templates/weekly-review.md`. Fill it in based on the week's eval data.

That is it. You are now doing Agent Reliability Engineering.

### What Comes Next

Once you have 2-4 weeks of eval data:

1. **Calculate imp@week** for each agent. Are they improving, stable, or regressing?
2. **Look for Rule of Three candidates.** Any task type that failed 3+ times? Codify the fix as a skill.
3. **Try a transfer experiment.** If you improved one agent, does the same change help another?
4. **Run the self-improvement pipeline.** Let your agents analyze their own data and propose improvements.

The full framework unfolds naturally from consistent measurement. Start small, stay consistent.

---

## Philosophy

AgentRE is opinionated. These are the principles behind the design decisions.

### 1. Lightweight Over Comprehensive

A 15-minute weekly review that you actually do beats a comprehensive monitoring system that you abandon after two weeks. Every tool in this repo is designed to be sustainable for a single practitioner. If it takes too long, you will stop doing it, and a framework nobody uses is worse than no framework at all.

> The best monitoring system is the one you actually look at.

### 2. Manual Judgment Is Valuable

Automated evals are useful for regression detection but poor at assessing quality nuance. A coding agent might produce technically correct code that is architecturally terrible. An automated test will not catch that. A human reviewer will.

This framework deliberately includes manual scoring because human judgment captures dimensions that automated metrics miss:

- Was the code *elegant* or just *correct*?
- Did the research agent *understand* the question or just pattern-match keywords?
- Was the agent's communication *clear* or technically accurate but confusing?

### 3. Trends Over Absolutes

A single eval score tells you very little. An agent scoring 3.8 might be excellent for its task difficulty or terrible for its capabilities. You cannot interpret scores in isolation.

Trends tell you everything. An agent that was scoring 4.2 and is now scoring 3.5 has a problem, regardless of whether 3.5 is objectively "good." An agent that was scoring 2.8 and is now scoring 3.5 is improving, even though 3.5 is the same number that signaled regression for the other agent.

**Always look at the delta, not the absolute.**

### 4. Human-in-the-Loop for Modifications

Agents can analyze their own performance. Agents can propose improvements. Agents MUST NOT implement identity or behavioral changes autonomously.

This is not a limitation of current technology that will be overcome with better models. This is a design principle. Self-modifying systems without human oversight develop in unpredictable directions. The human approval step is a feature, not a bottleneck.

```
Agent proposes: "I should be more assertive in code reviews"
Human evaluates: "Yes, but only for security issues. Stay collaborative on style."
```

That nuance is why humans stay in the loop.

### 5. The Rule of Three

Borrowed from software engineering wisdom and adapted for agent operations:

- **First occurrence:** Solve it. The agent figures out the solution manually.
- **Second occurrence:** Recognize it. "I have handled this type of problem before."
- **Third occurrence:** Codify it. Create a skill, write a script, update the config.

This prevents both premature optimization (codifying something you will never see again) and chronic toil (solving the same problem for the fourteenth time because nobody wrote it down).

The Rule of Three also applies to failure patterns:

| Occurrence | Action |
|---|---|
| 1st failure of a type | Note it in the daily log |
| 2nd failure of same type | Flag it in the weekly review |
| 3rd failure of same type | Create a skill or fix the root cause |

---

## Academic and Industry Connections

AgentRE does not exist in a vacuum. It builds on established work and emerging research.

### Google's Site Reliability Engineering

The foundational text. [Site Reliability Engineering: How Google Runs Production Systems](https://sre.google/sre-book/table-of-contents/) (2016) introduced SLOs, error budgets, toil reduction, and blameless postmortems to the industry.

AgentRE adapts these concepts for a new class of system. The core insight from Google SRE, that reliability is a feature that requires engineering investment, applies directly to AI agents.

Key adaptations:
- **SLOs** become agent performance targets (success rate, autonomy, efficiency)
- **Error budgets** become acceptable failure rates tuned per agent type
- **Runbooks** become Skills (SKILL.md, modular procedural knowledge)
- **Postmortems** become memory consolidation (daily logs to curated long-term memory)
- **Toil reduction** becomes the Rule of Three

### Meta's HyperAgents Paper

[HyperAgents: LLM-Based Agentic Systems for Automated Self-Improvement](https://arxiv.org/abs/2603.19461) (2026) demonstrated that LLM agents can systematically improve their own performance through metacognitive processes.

Key findings relevant to AgentRE:

1. **The imp@k metric:** A formal measure of improvement rate at evaluation step k. We adapted this into imp@week and imp@skill for practical use.

2. **Meta-level improvements transfer across domains:** A problem-solving strategy learned in one domain can improve performance in unrelated domains. This inspired our `transfer/` module.

3. **Self-improvement with safety rails works:** Agents that propose improvements (with human approval) outperform agents with static configurations. This validates the `self-improve/` pipeline approach.

4. **Structured evaluation enables compounding improvement:** Without measurement, improvement is random. With measurement, improvement compounds. This is the entire thesis of AgentRE.

### The Gap This Fills

As of early 2026, "Agent Reliability Engineering" does not exist as a named discipline. There are:

- **Agent frameworks** (LangChain, CrewAI, AutoGen) that help you build agents
- **Evaluation benchmarks** (GAIA, SWE-bench, AgentBench) that test agent capabilities
- **Monitoring tools** (LangSmith, Arize, Braintrust) that track individual calls

But there is no established practice for the operational lifecycle: measuring agents over time, tracking improvement, diagnosing regressions, codifying operational knowledge, and systematically improving agent reliability.

AgentRE fills that gap.

---

## FAQ

### Do I need 9 agents to use this?

No. Start with one. The eval framework, weekly reviews, and config versioning work for a single agent. The transfer experiments and some advanced patterns require multiple agents.

### Does this work with [framework X]?

Yes. AgentRE is framework-agnostic. It sits on top of whatever agent system you use. Whether your agents are built with LangChain, CrewAI, OpenClaw, raw API calls, or custom code, the operational practices apply.

### Is the scoring really manual?

Mostly, yes. You score a sample of tasks each week (5-10 per agent). It takes about 2 minutes per agent. Automated collection scripts can pre-fill some data (API costs, completion times), but the quality judgments are human.

### What if my agents are not persistent?

AgentRE is designed for agents that persist across sessions (with memory, skills, and identity). If your agents are stateless (new instance per request), the eval and metrics modules still apply, but config versioning and memory consolidation are less relevant.

### How is this different from LLM evals?

LLM evals measure model capabilities on benchmarks. AgentRE measures agent performance on your specific tasks, in your specific environment, over time. LLM evals ask "Can GPT-4 solve coding problems?" AgentRE asks "Is my coding agent getting better at fixing bugs in my codebase this month?"

### Can agents really improve themselves?

With guardrails, yes. The self-improvement pipeline analyzes performance data and proposes changes (new skills, config adjustments). Humans review and approve changes. Over time, this creates a compounding improvement loop. See Meta's HyperAgents paper for the academic foundation.

---

## Contributing

AgentRE is a young discipline. Contributions are welcome, especially from practitioners running agents in production.

### What We Are Looking For

- **Real-world case studies.** How did you apply AgentRE? What worked? What did you adapt?
- **New agent types.** Golden sets for agent types beyond engineer/ops/research/orchestrator.
- **Tooling integrations.** Scripts that pull eval data from LangSmith, Arize, or other monitoring tools.
- **Transfer experiment results.** Did an improvement transfer between your agent types? Share the data.
- **Pattern contributions.** New multi-agent patterns with production data.
- **Metric refinements.** Better formulas, normalization approaches, or trend detection methods.

### How to Contribute

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/my-contribution`)
3. Make your changes
4. Write clear commit messages
5. Open a PR with:
   - What you changed and why
   - Any production data supporting the change
   - Whether this is based on real operational experience

### Guidelines

- **Practitioner voice.** Write like you are explaining to a colleague, not writing a paper.
- **Show real data.** Anonymize if needed, but ground claims in actual usage.
- **Keep it lightweight.** If a contribution makes the framework heavier, justify why the complexity is worth it.
- **No vendor lock-in.** Tools and scripts should be framework-agnostic or clearly labeled.

### Code of Conduct

Be constructive, be respectful, focus on the work. Standard open-source expectations apply.

---

## Acknowledgments

- **Google SRE Team** for establishing the principles that this framework adapts
- **Meta AI Research** for the HyperAgents paper and the imp@k metric framework
- **The OpenClaw community** for building the agent infrastructure where these practices were developed and tested
- Every practitioner running agents in production and figuring this out the hard way

---

## License

MIT License. See [LICENSE](LICENSE) for details.

Use it, adapt it, improve it, share what you learn.

---

<p align="center">
  <em>Built from production experience, not theory.</em><br>
  <em>9 agents. 14 months. Real workloads. Real failures. Real improvements.</em><br><br>
  <strong>Agent Reliability Engineering: because your agents deserve the same operational rigor as your services.</strong>
</p>
