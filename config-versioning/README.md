# Config Versioning

Git-based version control for AI agent configurations. Track changes to agent identity, personality, and knowledge over time. Roll back when things break.

## Why

When you change an agent's SOUL.md or add a new skill, you need to know:
- What changed?
- Did performance improve or degrade?
- Can I undo this?

Config versioning answers all three.

## Scripts

### `agent-config-snapshot`

Takes a point-in-time snapshot of all agent configurations into a central git repo.

```bash
# Snapshot all agents
./scripts/agent-config-snapshot all

# Snapshot one agent
./scripts/agent-config-snapshot ada

# Snapshot with eval score tag
./scripts/agent-config-snapshot ada --tag "w14-success-4.5-autonomy-4.0"
```

### `agent-config-diff`

Shows what changed since the last snapshot.

```bash
# What changed for ada?
./scripts/agent-config-diff ada

# Diff between two tags
./scripts/agent-config-diff ada --from w13-baseline --to w14-improved
```

### `agent-config-rollback`

Restores an agent's configuration to a previous version.

```bash
# Roll back to a tagged version
./scripts/agent-config-rollback ada w13-baseline

# Shows a preview diff and asks for confirmation before applying
```

## Workflow

1. Run `agent-config-snapshot all` before making changes (or weekly after eval review)
2. Make your changes (update SOUL.md, add skills, modify prompts)
3. Run evals to measure impact
4. If improved: `agent-config-snapshot all --tag "w14-improvement-description"`
5. If regressed: `agent-config-rollback <agent> <previous-tag>`

## What Gets Tracked

Per agent:
- `SOUL.md` (personality, behavior instructions)
- `IDENTITY.md` (name, role, emoji)
- `MEMORY.md` (curated long-term knowledge)

Shared:
- All custom skills (SKILL.md files and their scripts/references)

## Adapting for Your Setup

The scripts assume a workspace layout like:

```
workspace-{agent-name}/
  SOUL.md
  IDENTITY.md
  MEMORY.md
```

Edit the `WORKSPACES` array in `agent-config-snapshot` to match your directory structure.
