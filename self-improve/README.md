# Self-Improve

Metacognitive self-modification with human oversight. Agents analyze their own performance data, identify weaknesses, and propose improvements to their skills and configuration. Humans review and approve before anything changes.

## Inspired By

Meta's HyperAgents paper (arXiv:2603.19461) demonstrated that agents can improve their own improvement process. Their agents automatically developed:
- Persistent memory systems
- Performance tracking infrastructure  
- Multi-stage evaluation pipelines

We implement the same concept with a critical difference: **human-in-the-loop approval** for all modifications. Agents propose, humans decide.

## How It Works

```
1. Collect metrics (automated)
   ↓
2. Read evaluation scores (from weekly review)
   ↓
3. Identify weak areas (LLM analysis)
   ↓
4. Generate proposed improvements (LLM)
   ↓
5. Present for human review (approval gate)
   ↓
6. Apply approved changes (automated)
```

## Scripts

### `self-improve.sh`

The main pipeline. Analyzes eval data and generates improvement proposals.

```bash
./self-improve.sh
```

What it does:
1. Runs metrics collection
2. Reads the latest weekly results
3. Identifies task categories scoring below threshold
4. For each weak area, proposes a specific improvement (skill update, SOUL.md change, or new procedure)
5. Outputs proposals in a structured format for review
6. On approval, applies changes to the relevant files

### `run-self-improve.sh`

Cron-ready wrapper. Can be scheduled to run after Friday eval reviews.

```bash
# Run directly
./run-self-improve.sh

# Or via cron (e.g., Friday 16:00 after eval review at 15:00)
openclaw cron add --name "self-improve" --cron "0 16 * * 5" \
  --agent main --session isolated \
  --message "Run the self-improvement pipeline at ~/workspace/workflows/run-self-improve.sh"
```

## Safety

This pipeline never modifies agent configurations autonomously. Every proposed change requires explicit human approval. The approval gate is the most important part of the system.

What it can propose:
- Skill file updates (adding steps, fixing procedures)
- SOUL.md refinements (adjusting behavior instructions)
- New skill creation (when a gap is identified)
- Memory updates (adding lessons learned)

What it cannot do without approval:
- Everything above. Nothing happens without a human saying "yes."

## When to Run

After your Friday eval review:
1. Complete the 15-minute eval review (score tasks, update results)
2. Run `self-improve.sh`
3. Review proposals
4. Approve good ones, reject bad ones
5. Take a config snapshot (`agent-config-snapshot all --tag "w14-post-improvement"`)
6. Next week's eval will measure the impact via imp@skill
