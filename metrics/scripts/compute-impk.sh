#!/usr/bin/env bash
# compute-impk.sh -- Calculate imp@week per agent by comparing consecutive weekly result files.
#
# imp@week: performance delta (average score change vs previous week)
# imp@skill: performance delta after a skill was added (see track-skill-impact.sh)
# Trend: improving (>+0.1), stable (-0.1 to +0.1), regressing (<-0.1)
#
# Usage:
#   ./compute-impk.sh                    # compare latest two weeks
#   ./compute-impk.sh 2026-W14           # compare W14 vs W13
#   ./compute-impk.sh 2026-W14 2026-W13  # compare specific pair

set -euo pipefail

EVALS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RESULTS_DIR="$EVALS_DIR/results"

AGENTS=(Ada Patsy Rita Signora)

# --- Helpers ---

# Extract average score for an agent from a results file.
# Looks for rows in the Manual Scoring tables that have numeric values.
# Returns empty string if not found or no scores yet.
get_agent_avg() {
    local file="$1"
    local agent="$2"

    # Find the agent section header, then collect all score values (cols 3,4,5 in pipe tables)
    # Format: | Task | Description | N | N | N | Notes |
    local in_section=0
    local scores=()

    while IFS= read -r line; do
        # Detect agent section (### AgentName or ## AgentName)
        if echo "$line" | grep -qiE "^#{2,3} ${agent}"; then
            in_section=1
            continue
        fi
        # Stop at next section of same or higher level
        if [ "$in_section" -eq 1 ] && echo "$line" | grep -qE "^#{2,3} "; then
            in_section=0
        fi
        # Parse table rows with numeric scores (skip header/separator rows)
        if [ "$in_section" -eq 1 ] && echo "$line" | grep -qE '^\|[^|]+\|[^|]+\|[[:space:]]*[1-5][[:space:]]*\|'; then
            # Extract columns 3, 4, 5 (success, autonomy, efficiency)
            col3=$(echo "$line" | awk -F'|' '{print $4}' | tr -d ' ')
            col4=$(echo "$line" | awk -F'|' '{print $5}' | tr -d ' ')
            col5=$(echo "$line" | awk -F'|' '{print $6}' | tr -d ' ')
            for val in "$col3" "$col4" "$col5"; do
                if echo "$val" | grep -qE '^[1-5]$'; then
                    scores+=("$val")
                fi
            done
        fi
    done < "$file"

    if [ "${#scores[@]}" -eq 0 ]; then
        echo ""
        return
    fi

    # Compute average with awk
    local sum=0
    local count="${#scores[@]}"
    for s in "${scores[@]}"; do
        sum=$((sum + s))
    done
    echo "$sum $count" | awk '{printf "%.2f", $1/$2}'
}

# Trend label based on delta
trend_label() {
    local delta="$1"
    # Use awk for float comparison
    echo "$delta" | awk '{
        if ($1 > 0.1) print "improving"
        else if ($1 < -0.1) print "regressing"
        else print "stable"
    }'
}

trend_arrow() {
    local trend="$1"
    case "$trend" in
        improving) echo "up" ;;
        regressing) echo "down" ;;
        *) echo "stable" ;;
    esac
}

# Find the two most recent result files (YYYY-WXX.md)
find_latest_two() {
    find "$RESULTS_DIR" -maxdepth 1 -name '[0-9][0-9][0-9][0-9]-W[0-9]*.md' \
        | sort -V | tail -2
}

# Resolve a week label to a file path
resolve_week_file() {
    local label="$1"
    local f="$RESULTS_DIR/${label}.md"
    if [ -f "$f" ]; then
        echo "$f"
    else
        echo ""
    fi
}

# --- Argument Handling ---

CURRENT_FILE=""
PREVIOUS_FILE=""

if [ $# -eq 0 ]; then
    mapfile -t candidates < <(find_latest_two)
    if [ "${#candidates[@]}" -lt 1 ]; then
        echo "No result files found in $RESULTS_DIR" >&2
        exit 1
    fi
    CURRENT_FILE="${candidates[-1]}"
    if [ "${#candidates[@]}" -ge 2 ]; then
        PREVIOUS_FILE="${candidates[-2]}"
    fi
elif [ $# -eq 1 ]; then
    CURRENT_FILE="$(resolve_week_file "$1")"
    if [ -z "$CURRENT_FILE" ]; then
        echo "File not found: $RESULTS_DIR/$1.md" >&2
        exit 1
    fi
    # Find the one before it
    mapfile -t all_files < <(find "$RESULTS_DIR" -maxdepth 1 -name '[0-9][0-9][0-9][0-9]-W[0-9]*.md' | sort -V)
    for i in "${!all_files[@]}"; do
        if [ "${all_files[$i]}" = "$CURRENT_FILE" ] && [ "$i" -gt 0 ]; then
            PREVIOUS_FILE="${all_files[$((i-1))]}"
        fi
    done
elif [ $# -eq 2 ]; then
    CURRENT_FILE="$(resolve_week_file "$1")"
    PREVIOUS_FILE="$(resolve_week_file "$2")"
    if [ -z "$CURRENT_FILE" ]; then
        echo "File not found: $RESULTS_DIR/$1.md" >&2; exit 1
    fi
    if [ -z "$PREVIOUS_FILE" ]; then
        echo "File not found: $RESULTS_DIR/$2.md" >&2; exit 1
    fi
fi

CURRENT_WEEK="$(basename "$CURRENT_FILE" .md)"
PREVIOUS_WEEK=""
[ -n "$PREVIOUS_FILE" ] && PREVIOUS_WEEK="$(basename "$PREVIOUS_FILE" .md)"

# --- Compute and Print ---

echo "imp@week report"
echo "Current week : $CURRENT_WEEK"
if [ -n "$PREVIOUS_WEEK" ]; then
    echo "Previous week: $PREVIOUS_WEEK"
else
    echo "Previous week: none (baseline)"
fi
echo ""
printf "%-12s  %-8s  %-8s  %-10s  %-10s\n" "Agent" "Current" "Previous" "imp@week" "Trend"
printf "%-12s  %-8s  %-8s  %-10s  %-10s\n" "------------" "--------" "--------" "----------" "----------"

for agent in "${AGENTS[@]}"; do
    current_avg="$(get_agent_avg "$CURRENT_FILE" "$agent")"
    previous_avg=""
    [ -n "$PREVIOUS_FILE" ] && previous_avg="$(get_agent_avg "$PREVIOUS_FILE" "$agent")"

    if [ -z "$current_avg" ]; then
        printf "%-12s  %-8s  %-8s  %-10s  %-10s\n" "$agent" "(none)" "${previous_avg:-(none)}" "N/A" "no data"
        continue
    fi

    if [ -z "$previous_avg" ]; then
        printf "%-12s  %-8s  %-8s  %-10s  %-10s\n" "$agent" "$current_avg" "(none)" "baseline" "baseline"
        continue
    fi

    delta="$(echo "$current_avg $previous_avg" | awk '{printf "%.2f", $1-$2}')"
    signed_delta="$(echo "$delta" | awk '{if ($1>0) printf "+%.2f", $1; else printf "%.2f", $1}')"
    trend="$(trend_label "$delta")"

    printf "%-12s  %-8s  %-8s  %-10s  %-10s\n" "$agent" "$current_avg" "$previous_avg" "$signed_delta" "$trend"
done

echo ""

# --- imp@skill (from skill-impacts.json if present) ---
SKILL_IMPACTS="$RESULTS_DIR/skill-impacts.json"
if [ -f "$SKILL_IMPACTS" ] && command -v jq &>/dev/null; then
    echo "imp@skill (from skill-impacts.json)"
    echo ""
    printf "%-12s  %-20s  %-8s  %-8s  %-10s\n" "Agent" "Skill" "Before" "After" "imp@skill"
    printf "%-12s  %-20s  %-8s  %-8s  %-10s\n" "------------" "--------------------" "--------" "--------" "----------"

    jq -r '.[] | select(.after != null) | [.agent, .skill, (.before_avg|tostring), (.after_avg|tostring), (.imp_skill|tostring)] | @tsv' \
        "$SKILL_IMPACTS" 2>/dev/null \
    | while IFS=$'\t' read -r agent skill before after imp; do
        signed="$(echo "$imp" | awk '{if ($1>0) printf "+%.2f", $1; else printf "%.2f", $1}')"
        printf "%-12s  %-20s  %-8s  %-8s  %-10s\n" "$agent" "$skill" "$before" "$after" "$signed"
    done
    echo ""
fi

echo "---"
echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
