#!/usr/bin/env bash
# run-transfer-experiment.sh
# Run one phase of a transfer experiment: extract baseline, prompt for scoring, compute delta.
#
# Usage:
#   ./scripts/run-transfer-experiment.sh <experiment-file> [--phase before|after]
#
# Examples:
#   ./scripts/run-transfer-experiment.sh experiments/structured-checklist-transfer.md --phase before
#   ./scripts/run-transfer-experiment.sh experiments/structured-checklist-transfer.md --phase after
#
# If --phase is omitted, the script asks interactively.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVALS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TRANSFER_DIR="$EVALS_DIR/transfer"
RESULTS_DIR="$TRANSFER_DIR/results"
LOG_FILE="$RESULTS_DIR/transfer-log.md"

# ------------------------------------------------------------------ parse args

EXPERIMENT_FILE=""
PHASE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --phase)
            PHASE="$2"
            shift 2
            ;;
        --help|-h)
            grep '^#' "$0" | sed 's/^# *//' | head -20
            exit 0
            ;;
        *)
            EXPERIMENT_FILE="$1"
            shift
            ;;
    esac
done

if [[ -z "$EXPERIMENT_FILE" ]]; then
    echo "Error: experiment file is required."
    echo "Usage: $0 <experiment-file> [--phase before|after]"
    exit 1
fi

# Resolve experiment file path relative to evals dir if not absolute
if [[ ! "$EXPERIMENT_FILE" = /* ]]; then
    if [[ -f "$EVALS_DIR/$EXPERIMENT_FILE" ]]; then
        EXPERIMENT_FILE="$EVALS_DIR/$EXPERIMENT_FILE"
    elif [[ -f "$TRANSFER_DIR/$EXPERIMENT_FILE" ]]; then
        EXPERIMENT_FILE="$TRANSFER_DIR/$EXPERIMENT_FILE"
    fi
fi

if [[ ! -f "$EXPERIMENT_FILE" ]]; then
    echo "Error: experiment file not found: $EXPERIMENT_FILE"
    exit 1
fi

EXPERIMENT_NAME="$(basename "$EXPERIMENT_FILE" .md)"

# ------------------------------------------------------------------ interactive phase selection

if [[ -z "$PHASE" ]]; then
    echo ""
    echo "Experiment: $EXPERIMENT_NAME"
    echo ""
    echo "Which phase are you running?"
    echo "  1) before  - establish baseline scores"
    echo "  2) after   - score after pattern was applied"
    read -rp "Enter 1 or 2: " phase_choice
    case "$phase_choice" in
        1) PHASE="before" ;;
        2) PHASE="after" ;;
        *) echo "Invalid choice. Use 1 or 2."; exit 1 ;;
    esac
fi

if [[ "$PHASE" != "before" && "$PHASE" != "after" ]]; then
    echo "Error: --phase must be 'before' or 'after'"
    exit 1
fi

# ------------------------------------------------------------------ display experiment context

echo ""
echo "================================================================"
echo "Transfer Experiment: $EXPERIMENT_NAME"
echo "Phase: $PHASE"
echo "================================================================"
echo ""

# Extract key metadata from the experiment file
SOURCE_AGENT=$(grep "^\*\*Source agent" "$EXPERIMENT_FILE" | head -1 | sed 's/.*: //' | sed 's/\*\*//')
TARGET_AGENT=$(grep "^\*\*Target agent" "$EXPERIMENT_FILE" | head -1 | sed 's/.*: //' | sed 's/\*\*//')
PATTERN=$(grep "^\*\*Pattern" "$EXPERIMENT_FILE" | head -1 | sed 's/.*: //' | sed 's/\*\*//')

echo "Source agent: $SOURCE_AGENT"
echo "Target agent: $TARGET_AGENT"
echo "Pattern:      $PATTERN"
echo ""

# ------------------------------------------------------------------ before phase

if [[ "$PHASE" == "before" ]]; then
    echo "BEFORE PHASE: Establish baseline scores"
    echo ""
    echo "Instructions:"
    echo "  1. Open the experiment file to see which tasks to score:"
    echo "     $EXPERIMENT_FILE"
    echo ""
    echo "  2. Run the target agent's golden set tasks (or a targeted subset"
    echo "     from the experiment file's baseline table)."
    echo ""
    echo "  3. Score each task using the rubric in evals/METHODOLOGY.md:"
    echo "     - Success (1-5)"
    echo "     - Autonomy (1-5)"
    echo "     - Efficiency (1-5)"
    echo ""
    echo "  4. Enter scores below when ready."
    echo ""
    echo "Press Enter when you have run the golden set and are ready to enter scores."
    read -r

    # Collect before scores interactively
    echo ""
    echo "Enter scores for the tasks listed in the experiment file."
    echo "Press Ctrl+C to abort without logging."
    echo ""

    SCORES=()
    TASK_IDS=()

    while true; do
        read -rp "Task ID (or 'done' to finish): " task_id
        if [[ "$task_id" == "done" || -z "$task_id" ]]; then
            break
        fi

        read -rp "  Success (1-5): " score_success
        read -rp "  Autonomy (1-5): " score_autonomy
        read -rp "  Efficiency (1-5): " score_efficiency
        echo ""

        TASK_IDS+=("$task_id")
        SCORES+=("$task_id|$score_success|$score_autonomy|$score_efficiency")
    done

    # Write to a temp before-scores file so after phase can read it
    BEFORE_SCORES_FILE="$RESULTS_DIR/${EXPERIMENT_NAME}-before.scores"
    printf '%s\n' "${SCORES[@]}" > "$BEFORE_SCORES_FILE"
    echo "Before scores saved to: $BEFORE_SCORES_FILE"
    echo ""

    # Log to transfer-log.md
    TIMESTAMP="$(date '+%Y-%m-%d %H:%M')"
    LOG_ENTRY="## [$TIMESTAMP] $EXPERIMENT_NAME - Before baseline\n\n"
    LOG_ENTRY+="**Experiment file:** $EXPERIMENT_FILE\n"
    LOG_ENTRY+="**Source agent:** $SOURCE_AGENT\n"
    LOG_ENTRY+="**Target agent:** $TARGET_AGENT\n"
    LOG_ENTRY+="**Phase:** Before baseline\n\n"
    LOG_ENTRY+="### Scores\n\n"
    LOG_ENTRY+="| Task | Success | Autonomy | Efficiency |\n"
    LOG_ENTRY+="|------|---------|----------|------------|\n"

    for score_line in "${SCORES[@]}"; do
        IFS='|' read -r tid s a e <<< "$score_line"
        LOG_ENTRY+="| $tid | $s | $a | $e |\n"
    done

    LOG_ENTRY+="\n### Summary\n\n"
    LOG_ENTRY+="Baseline recorded. Pattern not yet applied. Run after phase once pattern is applied.\n\n"
    LOG_ENTRY+="### Next Step\n\n"
    LOG_ENTRY+="Apply the pattern as described in the experiment file, then run:\n\n"
    LOG_ENTRY+="\`\`\`\n./scripts/run-transfer-experiment.sh $EXPERIMENT_NAME --phase after\n\`\`\`\n\n"
    LOG_ENTRY+="---\n\n"

    # Prepend to log (after the Active Experiments table)
    # We insert before the "Completed Experiments" section
    TEMP_LOG="$(mktemp)"
    awk -v entry="$LOG_ENTRY" '
        /^## Completed Experiments/ && !done {
            print entry
            done=1
        }
        { print }
    ' "$LOG_FILE" > "$TEMP_LOG"
    mv "$TEMP_LOG" "$LOG_FILE"

    echo "Logged to: $LOG_FILE"
    echo ""
    echo "Next: Apply the pattern from the experiment file to $TARGET_AGENT,"
    echo "wait 24 hours, then run this script with --phase after."
fi

# ------------------------------------------------------------------ after phase

if [[ "$PHASE" == "after" ]]; then
    echo "AFTER PHASE: Score post-transfer and compute delta"
    echo ""

    BEFORE_SCORES_FILE="$RESULTS_DIR/${EXPERIMENT_NAME}-before.scores"

    if [[ ! -f "$BEFORE_SCORES_FILE" ]]; then
        echo "Warning: No before-scores file found at:"
        echo "  $BEFORE_SCORES_FILE"
        echo ""
        echo "Either the before phase was not run via this script, or the file was moved."
        echo "You can still enter after scores; delta computation will be skipped."
        echo ""
        HAS_BEFORE=false
    else
        HAS_BEFORE=true
        echo "Found before scores. Delta will be computed after entering after scores."
        echo ""
    fi

    echo "Instructions:"
    echo "  1. Run the same golden set tasks as the before phase."
    echo "     Use identical task inputs."
    echo "  2. Score each task without looking at the before scores."
    echo "  3. Enter scores below."
    echo ""
    echo "Press Enter when ready to enter after scores."
    read -r

    AFTER_SCORES=()

    while true; do
        read -rp "Task ID (or 'done' to finish): " task_id
        if [[ "$task_id" == "done" || -z "$task_id" ]]; then
            break
        fi

        read -rp "  Success (1-5): " score_success
        read -rp "  Autonomy (1-5): " score_autonomy
        read -rp "  Efficiency (1-5): " score_efficiency
        echo ""

        AFTER_SCORES+=("$task_id|$score_success|$score_autonomy|$score_efficiency")
    done

    # Save after scores
    AFTER_SCORES_FILE="$RESULTS_DIR/${EXPERIMENT_NAME}-after.scores"
    printf '%s\n' "${AFTER_SCORES[@]}" > "$AFTER_SCORES_FILE"

    # Compute deltas if before scores exist
    echo ""
    echo "================================================================"
    echo "RESULTS: $EXPERIMENT_NAME"
    echo "================================================================"
    echo ""

    if [[ "$HAS_BEFORE" == true ]]; then
        # Read before scores into associative array
        declare -A before_success before_autonomy before_efficiency

        while IFS='|' read -r tid s a e; do
            before_success[$tid]="$s"
            before_autonomy[$tid]="$a"
            before_efficiency[$tid]="$e"
        done < "$BEFORE_SCORES_FILE"

        echo "Task         | Before S/A/E | After S/A/E  | Delta S/A/E"
        echo "-------------|--------------|--------------|-------------"

        TOTAL_DELTA_S=0
        TOTAL_DELTA_A=0
        TOTAL_DELTA_E=0
        TASK_COUNT=0

        DELTA_TABLE="| Task | Before S/A/E | After S/A/E | Delta S/A/E | Result |\n"
        DELTA_TABLE+="|------|-------------|------------|------------|--------|\n"

        for score_line in "${AFTER_SCORES[@]}"; do
            IFS='|' read -r tid after_s after_a after_e <<< "$score_line"

            if [[ -n "${before_success[$tid]+x}" ]]; then
                before_s="${before_success[$tid]}"
                before_a="${before_autonomy[$tid]}"
                before_e="${before_efficiency[$tid]}"

                delta_s=$(echo "$after_s - $before_s" | bc)
                delta_a=$(echo "$after_a - $before_a" | bc)
                delta_e=$(echo "$after_e - $before_e" | bc)

                # Format with sign
                [[ "$delta_s" -ge 0 ]] && ds="+$delta_s" || ds="$delta_s"
                [[ "$delta_a" -ge 0 ]] && da="+$delta_a" || da="$delta_a"
                [[ "$delta_e" -ge 0 ]] && de="+$delta_e" || de="$delta_e"

                # Determine result label
                avg_primary=$(echo "scale=2; ($delta_s + $delta_a) / 2" | bc)
                if (( $(echo "$avg_primary >= 0.5" | bc -l) )); then
                    result="Transfer"
                elif (( $(echo "$avg_primary >= 0" | bc -l) )); then
                    result="Weak"
                elif (( $(echo "$delta_s <= -0.3 || $delta_a <= -0.3" | bc -l) )); then
                    result="Regression"
                else
                    result="Neutral"
                fi

                printf "%-12s | %s/%s/%s         | %s/%s/%s        | %s/%s/%s\n" \
                    "$tid" "$before_s" "$before_a" "$before_e" \
                    "$after_s" "$after_a" "$after_e" \
                    "$ds" "$da" "$de"

                DELTA_TABLE+="| $tid | $before_s/$before_a/$before_e | $after_s/$after_a/$after_e | $ds/$da/$de | $result |\n"

                TOTAL_DELTA_S=$(echo "$TOTAL_DELTA_S + $delta_s" | bc)
                TOTAL_DELTA_A=$(echo "$TOTAL_DELTA_A + $delta_a" | bc)
                TOTAL_DELTA_E=$(echo "$TOTAL_DELTA_E + $delta_e" | bc)
                ((TASK_COUNT++))
            else
                echo "$tid: no matching before score (skipping delta)"
                DELTA_TABLE+="| $tid | N/A | $after_s/$after_a/$after_e | N/A | N/A |\n"
            fi
        done

        if [[ "$TASK_COUNT" -gt 0 ]]; then
            avg_s=$(echo "scale=2; $TOTAL_DELTA_S / $TASK_COUNT" | bc)
            avg_a=$(echo "scale=2; $TOTAL_DELTA_A / $TASK_COUNT" | bc)
            avg_e=$(echo "scale=2; $TOTAL_DELTA_E / $TASK_COUNT" | bc)

            echo ""
            echo "Average delta: Success=$avg_s  Autonomy=$avg_a  Efficiency=$avg_e"
            echo ""

            # Overall verdict
            primary_avg=$(echo "scale=2; ($avg_s + $avg_a) / 2" | bc)
            if (( $(echo "$primary_avg >= 0.5" | bc -l) )); then
                echo "VERDICT: Transfer successful (primary avg delta >= 0.5)"
            elif (( $(echo "$primary_avg >= 0" | bc -l) )); then
                echo "VERDICT: Weak transfer (improvement below threshold)"
            else
                echo "VERDICT: No transfer / regression (primary avg negative)"
            fi
        fi
    else
        echo "No before scores available. Showing after scores only:"
        echo ""
        echo "Task | Success | Autonomy | Efficiency"
        echo "-----|---------|----------|----------"
        for score_line in "${AFTER_SCORES[@]}"; do
            IFS='|' read -r tid s a e <<< "$score_line"
            printf "%-6s| %-8s| %-9s| %s\n" "$tid" "$s" "$a" "$e"
        done
        DELTA_TABLE="(No before scores available for delta computation)\n"
    fi

    # Get qualitative notes
    echo ""
    echo "Enter a brief qualitative observation (press Enter twice when done):"
    QUALITATIVE=""
    while IFS= read -r line; do
        [[ -z "$line" && -n "$QUALITATIVE" ]] && break
        QUALITATIVE+="$line "
    done
    QUALITATIVE="${QUALITATIVE:-No notes recorded.}"

    # Write log entry
    TIMESTAMP="$(date '+%Y-%m-%d %H:%M')"
    LOG_ENTRY="## [$TIMESTAMP] $EXPERIMENT_NAME - After run\n\n"
    LOG_ENTRY+="**Experiment file:** $EXPERIMENT_FILE\n"
    LOG_ENTRY+="**Source agent:** $SOURCE_AGENT\n"
    LOG_ENTRY+="**Target agent:** $TARGET_AGENT\n"
    LOG_ENTRY+="**Phase:** After run (transfer applied)\n\n"
    LOG_ENTRY+="### Scores and Deltas\n\n"
    LOG_ENTRY+="$DELTA_TABLE"
    LOG_ENTRY+="\n### Qualitative Notes\n\n$QUALITATIVE\n\n"
    LOG_ENTRY+="### Status\n\nComplete. Review deltas and decide whether to keep or revert the pattern change.\n\n"
    LOG_ENTRY+="---\n\n"

    TEMP_LOG="$(mktemp)"
    awk -v entry="$LOG_ENTRY" '
        /^## Completed Experiments/ && !done {
            print entry
            done=1
        }
        { print }
    ' "$LOG_FILE" > "$TEMP_LOG"
    mv "$TEMP_LOG" "$LOG_FILE"

    echo ""
    echo "Results logged to: $LOG_FILE"
    echo ""
    echo "Done."
fi
