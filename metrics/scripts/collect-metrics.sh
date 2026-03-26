#!/usr/bin/env bash
# collect-metrics.sh — Gather automated metrics from agent activity
# Usage: ./collect-metrics.sh [YYYY-MM-DD] (defaults to last 7 days)
set -euo pipefail

EVALS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RESULTS_DIR="$EVALS_DIR/results"
DASHBOARDS_DIR="$EVALS_DIR/dashboards"
WORKSPACE="$HOME/.openclaw/workspace"

# Date range
END_DATE="${1:-$(date +%Y-%m-%d)}"
START_DATE="$(date -d "$END_DATE - 7 days" +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d)"

WEEK_NUM="$(date -d "$END_DATE" +%Y-W%V 2>/dev/null || date +%Y-W%V)"

echo "Collecting metrics for $START_DATE to $END_DATE ($WEEK_NUM)"
echo ""

# --- Agent Activity from Memory Files ---
echo "## Agent Activity (from memory files)"
echo ""

for agent in main ada patsy rita; do
    if [ "$agent" = "main" ]; then
        AGENT_MEM="$WORKSPACE/memory"
        AGENT_NAME="Signora"
    else
        AGENT_MEM="$HOME/.openclaw/workspace-$agent/memory"
        AGENT_NAME="$agent"
    fi

    if [ -d "$AGENT_MEM" ]; then
        # Count memory files in date range
        file_count=0
        task_count=0
        for f in "$AGENT_MEM"/*.md; do
            [ -f "$f" ] || continue
            fname="$(basename "$f")"
            # Extract date from filename (YYYY-MM-DD pattern)
            fdate="${fname:0:10}"
            if [[ "$fdate" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && [[ "$fdate" > "$START_DATE" || "$fdate" == "$START_DATE" ]] && [[ "$fdate" < "$END_DATE" || "$fdate" == "$END_DATE" ]]; then
                file_count=$((file_count + 1))
                # Count task-like entries (lines starting with ## or ### or - **)
                tc=$(grep -cE '^(##|###|- \*\*)' "$f" 2>/dev/null || true)
                task_count=$((task_count + tc))
            fi
        done
        echo "**$AGENT_NAME:** $file_count memory files, ~$task_count task entries"
    else
        echo "**$AGENT_NAME:** no memory directory"
    fi
done

echo ""

# --- Session Counts from Commands Log ---
echo "## Session Counts (from commands.log)"
echo ""

COMMANDS_LOG="$HOME/.openclaw/logs/commands.log"
if [ -f "$COMMANDS_LOG" ]; then
    for agent in main ada patsy rita ciro able ferruccio colette mahlangu; do
        count=$(grep -c "\"agent:$agent:" "$COMMANDS_LOG" 2>/dev/null || true)
        echo "**$agent:** $count total sessions (all time)"
    done
fi

echo ""

# --- Incident Tracking (from memory files) ---
echo "## Incidents Mentioned (keywords in memory files)"
echo ""

for keyword in "fix" "error" "broken" "failed" "crash" "down" "restart" "permission"; do
    count=0
    for agent_dir in "$WORKSPACE/memory" "$HOME/.openclaw/workspace-ada/memory" "$HOME/.openclaw/workspace-patsy/memory"; do
        [ -d "$agent_dir" ] || continue
        for f in "$agent_dir"/*.md; do
            [ -f "$f" ] || continue
            fname="$(basename "$f")"
            fdate="${fname:0:10}"
            if [[ "$fdate" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && [[ "$fdate" > "$START_DATE" || "$fdate" == "$START_DATE" ]] && [[ "$fdate" < "$END_DATE" || "$fdate" == "$END_DATE" ]]; then
                c=$(grep -ci "$keyword" "$f" 2>/dev/null || true)
                count=$((count + c))
            fi
        done
    done
    echo "**$keyword:** $count mentions"
done

echo ""
echo "---"
echo "Collected: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Period: $START_DATE to $END_DATE"
