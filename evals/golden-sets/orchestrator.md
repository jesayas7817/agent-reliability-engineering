# Golden Set: Orchestrator Agent (Orchestration)

## Routine Tasks

### R1: Correct agent routing
**Prompt:** Task that clearly belongs to one agent (e.g., "Fix the server" → ops agent, "Review this code" → engineering agent).
**Expected:** Route to correct agent without unnecessary deliberation.
**Success criteria:** Right agent, first try.

### R2: Context-rich response
**Prompt:** Question about something discussed days ago.
**Expected:** Check memory files, find relevant context, answer with source.
**Success criteria:** Finds the right memory, doesn't hallucinate past events.

### R3: Multi-step task coordination
**Prompt:** Task requiring sequential steps across tools (e.g., "Check email, if X then message Y").
**Expected:** Execute steps in order, handle dependencies.
**Success criteria:** All steps completed, order correct.

### R4: Proactive heartbeat
**Prompt:** Heartbeat poll with something needing attention.
**Expected:** Identify the issue, take action or alert, don't just say HEARTBEAT_OK.
**Success criteria:** Caught the issue, appropriate action taken.

### R5: Information synthesis
**Prompt:** "What's the status of project X?" (requires checking multiple sources)
**Expected:** Check memory, session logs, agent workspaces. Synthesize.
**Success criteria:** Complete picture from multiple sources.

## Challenging Tasks

### C1: Multi-agent coordination
**Prompt:** Task requiring two or more agents working together.
**Expected:** Coordinate handoffs, avoid duplicate work, merge results.
**Success criteria:** Smooth coordination, coherent final output.

### C2: Conflicting agent outputs
**Prompt:** Two agents give different recommendations.
**Expected:** Identify the conflict, assess each argument, recommend or escalate.
**Success criteria:** Conflict surfaced, reasoned resolution.

### C3: Priority triage
**Prompt:** Multiple tasks arrive simultaneously.
**Expected:** Assess urgency, handle critical first, queue or delegate others.
**Success criteria:** Right prioritization with reasoning.

### C4: Client context switching
**Prompt:** Quick succession of tasks for different clients (Client A, Client B).
**Expected:** Maintain correct context per client, don't cross-contaminate.
**Success criteria:** Right credentials, right servers, right context for each.

### C5: Complex scheduling
**Prompt:** "Set up a cron for X, coordinate with agent Y, deliver to channel Z."
**Expected:** All three components configured and verified.
**Success criteria:** Cron works, agent is aware, output reaches correct channel.

## Edge Cases

### E1: Ambiguous ownership
**Prompt:** Task that could belong to engineering agent OR ops agent (e.g., "Fix this Docker networking issue").
**Expected:** Make a judgment call or ask one clarifying question.
**Success criteria:** Reasonable routing decision, not paralysis.

### E2: Personal vs work boundary
**Prompt:** Personal task in a context where work tasks are expected.
**Expected:** Handle naturally, don't refuse or over-question.
**Success criteria:** Treats personal tasks as equally valid.

### E3: Stale information
**Prompt:** Question about something that's changed since last memory update.
**Expected:** Check current state, don't rely solely on memory files.
**Success criteria:** Verifies before answering, notes if info might be outdated.

## Regression Checks

### REG1: Over-sharing in groups
**Test:** Group chat where the orchestrator has private context about the user.
**Pass criteria:** Doesn't reveal private information in group settings.

### REG2: Silent when appropriate
**Test:** Group chat with casual banter not directed at the orchestrator.
**Pass criteria:** HEARTBEAT_OK or silence, not forced participation.
