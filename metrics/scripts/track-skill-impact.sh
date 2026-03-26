#!/usr/bin/env bash
# track-skill-impact.sh -- Record before/after eval scores to measure imp@skill.
#
# imp@skill measures the performance change after a skill is added or modified.
# Run once before deploying a skill (--before), then again after (--after).
# The delta is stored in evals/results/skill-impacts.json.
#
# Usage:
#   ./track-skill-impact.sh --before <skill-name> <agent-name>
#   ./track-skill-impact.sh --after  <skill-name> <agent-name>
#   ./track-skill-impact.sh --show   <skill-name> <agent-name>
#   ./track-skill-impact.sh --list
#
# Examples:
#   ./track-skill-impact.sh --before lidl-prices Ada
#   # deploy the skill
#   ./track-skill-impact.sh --after  lidl-prices Ada

set -euo pipefail

EVALS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RESULTS_DIR="$EVALS_DIR/results"
IMPACTS_FILE="$RESULTS_DIR/skill-impacts.json"
SCRIPTS_DIR="$EVALS_DIR/scripts"

# --- Helpers ---

require_jq() {
    if ! command -v jq &>/dev/null; then
        echo "Error: jq is required. Install with: sudo apt-get install jq" >&2
        exit 1
    fi
}

usage() {
    echo "Usage:"
    echo "  $0 --before <skill-name> <agent-name>   Record scores before skill deployment"
    echo "  $0 --after  <skill-name> <agent-name>   Record scores after skill deployment"
    echo "  $0 --show   <skill-name> <agent-name>   Show current record for this skill+agent"
    echo "  $0 --list                                List all recorded skill impacts"
    exit 1
}

# Get current average score from the most recent results file for an agent.
# Falls back to prompting user for manual entry if no scores are found.
get_current_avg() {
    local agent="$1"
    local avg=""

    # Find the latest results file
    local latest_file
    latest_file="$(find "$RESULTS_DIR" -maxdepth 1 -name '[0-9][0-9][0-9][0-9]-W[0-9]*.md' | sort -V | tail -1)"

    if [ -n "$latest_file" ] && [ -f "$latest_file" ]; then
        local in_section=0
        local scores=()
        while IFS= read -r line; do
            if echo "$line" | grep -qiE "^#{2,3} ${agent}"; then
                in_section=1; continue
            fi
            if [ "$in_section" -eq 1 ] && echo "$line" | grep -qE "^#{2,3} "; then
                in_section=0
            fi
            if [ "$in_section" -eq 1 ] && echo "$line" | grep -qE '^\|[^|]+\|[^|]+\|[[:space:]]*[1-5][[:space:]]*\|'; then
                col3=$(echo "$line" | awk -F'|' '{print $4}' | tr -d ' ')
                col4=$(echo "$line" | awk -F'|' '{print $5}' | tr -d ' ')
                col5=$(echo "$line" | awk -F'|' '{print $6}' | tr -d ' ')
                for val in "$col3" "$col4" "$col5"; do
                    if echo "$val" | grep -qE '^[1-5]$'; then
                        scores+=("$val")
                    fi
                done
            fi
        done < "$latest_file"

        if [ "${#scores[@]}" -gt 0 ]; then
            local sum=0
            for s in "${scores[@]}"; do sum=$((sum + s)); done
            avg="$(echo "$sum ${#scores[@]}" | awk '{printf "%.2f", $1/$2}')"
        fi
    fi

    if [ -z "$avg" ]; then
        echo "No automated scores found for $agent in the latest results file." >&2
        echo -n "Enter current average score for $agent (1.00-5.00), or press Enter to skip: " >&2
        read -r manual_avg
        if echo "$manual_avg" | grep -qE '^[0-9]+(\.[0-9]+)?$'; then
            avg="$manual_avg"
        else
            avg="null"
        fi
    fi

    echo "$avg"
}

# Initialize the JSON file if it does not exist
init_file() {
    if [ ! -f "$IMPACTS_FILE" ]; then
        echo "[]" > "$IMPACTS_FILE"
    fi
}

# Read the file as JSON array
read_impacts() {
    cat "$IMPACTS_FILE"
}

# Write a JSON array back
write_impacts() {
    local data="$1"
    echo "$data" | jq '.' > "$IMPACTS_FILE"
}

# Find an existing entry index (returns -1 if not found)
find_entry() {
    local skill="$1"
    local agent="$2"
    jq --arg skill "$skill" --arg agent "$agent" \
        'to_entries | .[] | select(.value.skill == $skill and .value.agent == $agent) | .key' \
        "$IMPACTS_FILE" 2>/dev/null || echo "-1"
}

compute_imp() {
    local before="$1"
    local after="$2"
    if [ "$before" = "null" ] || [ "$after" = "null" ]; then
        echo "null"
        return
    fi
    echo "$before $after" | awk '{printf "%.2f", $2-$1}'
}

# --- Mode dispatch ---

[ $# -lt 1 ] && usage

MODE="$1"
shift

case "$MODE" in
    --list)
        require_jq
        if [ ! -f "$IMPACTS_FILE" ]; then
            echo "No skill-impacts.json found. Nothing recorded yet."
            exit 0
        fi
        echo "Skill impact records:"
        echo ""
        printf "%-12s  %-20s  %-8s  %-8s  %-10s  %-8s\n" "Agent" "Skill" "Before" "After" "imp@skill" "Status"
        printf "%-12s  %-20s  %-8s  %-8s  %-10s  %-8s\n" "------------" "--------------------" "--------" "--------" "----------" "--------"
        jq -r '.[] | [
            .agent,
            .skill,
            (if .before_avg then (.before_avg|tostring) else "(none)" end),
            (if .after_avg then (.after_avg|tostring) else "(none)" end),
            (if .imp_skill then
                (if (.imp_skill >= 0) then "+"+(.imp_skill|tostring) else (.imp_skill|tostring) end)
            else "pending" end),
            (if .after_avg then "complete" else "awaiting after" end)
        ] | @tsv' "$IMPACTS_FILE" \
        | while IFS=$'\t' read -r agent skill before after imp status; do
            printf "%-12s  %-20s  %-8s  %-8s  %-10s  %-8s\n" "$agent" "$skill" "$before" "$after" "$imp" "$status"
        done
        ;;

    --before)
        [ $# -lt 2 ] && { echo "Usage: $0 --before <skill-name> <agent-name>"; exit 1; }
        require_jq
        SKILL="$1"
        AGENT="$2"
        init_file

        echo "Recording BEFORE snapshot for skill=$SKILL agent=$AGENT"
        avg="$(get_current_avg "$AGENT")"
        echo "Score snapshot: $avg"

        timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        data="$(read_impacts)"

        idx="$(find_entry "$SKILL" "$AGENT")"
        if [ -n "$idx" ] && [ "$idx" != "-1" ]; then
            # Update existing entry
            data="$(echo "$data" | jq --arg skill "$SKILL" --arg agent "$AGENT" \
                --argjson avg "$([ "$avg" = "null" ] && echo "null" || echo "$avg")" \
                --arg ts "$timestamp" \
                'map(if .skill == $skill and .agent == $agent then
                    .before_avg = $avg | .before_ts = $ts | .after_avg = null | .after_ts = null | .imp_skill = null
                else . end)')"
        else
            # Append new entry
            data="$(echo "$data" | jq --arg skill "$SKILL" --arg agent "$AGENT" \
                --argjson avg "$([ "$avg" = "null" ] && echo "null" || echo "$avg")" \
                --arg ts "$timestamp" \
                '. + [{skill: $skill, agent: $agent, before_avg: $avg, before_ts: $ts, after_avg: null, after_ts: null, imp_skill: null}]')"
        fi

        write_impacts "$data"
        echo "Saved to $IMPACTS_FILE"
        echo ""
        echo "Next step: deploy the skill, then run:"
        echo "  $0 --after $SKILL $AGENT"
        ;;

    --after)
        [ $# -lt 2 ] && { echo "Usage: $0 --after <skill-name> <agent-name>"; exit 1; }
        require_jq
        SKILL="$1"
        AGENT="$2"
        init_file

        idx="$(find_entry "$SKILL" "$AGENT")"
        if [ -z "$idx" ] || [ "$idx" = "-1" ]; then
            echo "No 'before' snapshot found for skill=$SKILL agent=$AGENT"
            echo "Run --before first."
            exit 1
        fi

        echo "Recording AFTER snapshot for skill=$SKILL agent=$AGENT"
        avg="$(get_current_avg "$AGENT")"
        echo "Score snapshot: $avg"

        timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

        # Get the before_avg to compute delta
        before_avg="$(jq --arg skill "$SKILL" --arg agent "$AGENT" \
            '.[] | select(.skill == $skill and .agent == $agent) | .before_avg' \
            "$IMPACTS_FILE")"

        imp="null"
        if [ "$before_avg" != "null" ] && [ "$avg" != "null" ]; then
            imp="$(echo "$before_avg $avg" | awk '{printf "%.2f", $2-$1}')"
        fi

        data="$(read_impacts)"
        data="$(echo "$data" | jq --arg skill "$SKILL" --arg agent "$AGENT" \
            --argjson avg "$([ "$avg" = "null" ] && echo "null" || echo "$avg")" \
            --argjson imp "$([ "$imp" = "null" ] && echo "null" || echo "$imp")" \
            --arg ts "$timestamp" \
            'map(if .skill == $skill and .agent == $agent then
                .after_avg = $avg | .after_ts = $ts | .imp_skill = $imp
            else . end)')"

        write_impacts "$data"
        echo "Saved to $IMPACTS_FILE"

        if [ "$imp" != "null" ]; then
            signed="$(echo "$imp" | awk '{if ($1>=0) printf "+%.2f", $1; else printf "%.2f", $1}')"
            echo ""
            echo "imp@skill for $SKILL on $AGENT: $signed"
            trend="$(echo "$imp" | awk '{if ($1>0.1) print "improving"; else if ($1<-0.1) print "regressing"; else print "stable"}')"
            echo "Verdict: $trend"
        fi
        ;;

    --show)
        [ $# -lt 2 ] && { echo "Usage: $0 --show <skill-name> <agent-name>"; exit 1; }
        require_jq
        SKILL="$1"
        AGENT="$2"

        if [ ! -f "$IMPACTS_FILE" ]; then
            echo "No skill-impacts.json found."
            exit 0
        fi

        jq --arg skill "$SKILL" --arg agent "$AGENT" \
            '.[] | select(.skill == $skill and .agent == $agent)' \
            "$IMPACTS_FILE"
        ;;

    *)
        usage
        ;;
esac
