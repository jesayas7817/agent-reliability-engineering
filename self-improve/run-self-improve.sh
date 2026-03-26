#!/usr/bin/env bash
# run-self-improve.sh -- Cron-ready wrapper for the self-improvement pipeline
#
# Called by OpenClaw cron after Friday eval reviews complete.
# Runs in non-interactive mode (no TTY prompts).
#
# Cron example (every Friday at 22:00):
#   0 22 * * 5 /home/choutos/.openclaw/workspace/workflows/run-self-improve.sh
#
# The pipeline runs with --dry-run by default.
# To apply changes automatically, set SELF_IMPROVE_AUTO_APPROVE=1.
# Recommended workflow: run dry-run, review proposals, then re-run with auto-approve.
#
# Output goes to a log file in evals/results/ and is sent as a Telegram message.

set -euo pipefail

WORKSPACE="$HOME/.openclaw/workspace"
RESULTS_DIR="$WORKSPACE/evals/results"
TIMESTAMP=$(date +%Y-%m-%d)
LOG_FILE="$RESULTS_DIR/cron-self-improve-$TIMESTAMP.log"

mkdir -p "$RESULTS_DIR"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

log "Self-improvement cron job started"

# Determine mode
if [ "${SELF_IMPROVE_AUTO_APPROVE:-0}" = "1" ]; then
  MODE_FLAG="--auto-approve"
  log "Mode: auto-approve (will apply changes directly)"
else
  MODE_FLAG="--dry-run"
  log "Mode: dry-run (proposals only, no changes applied)"
fi

# Run the pipeline
EXIT_CODE=0
bash "$WORKSPACE/workflows/self-improve.sh" "$MODE_FLAG" 2>&1 | tee -a "$LOG_FILE" || EXIT_CODE=$?

# Find the latest proposals file
PROPOSALS_FILE=$(ls -t "$RESULTS_DIR"/proposals-*.json 2>/dev/null | head -1 || echo "")
PROPOSAL_COUNT=0
if [ -n "$PROPOSALS_FILE" ] && [ -f "$PROPOSALS_FILE" ]; then
  PROPOSAL_COUNT=$(python3 -c "import json; print(len(json.load(open('$PROPOSALS_FILE'))))" 2>/dev/null || echo "0")
fi

# Build notification message
if [ "$EXIT_CODE" = "0" ]; then
  STATUS_ICON="OK"
else
  STATUS_ICON="FAIL"
fi

if [ "$MODE_FLAG" = "--dry-run" ]; then
  NOTIFY_MSG="[$STATUS_ICON] Self-improve run: $TIMESTAMP

Mode: dry-run
Proposals: $PROPOSAL_COUNT improvements identified
File: $PROPOSALS_FILE

To apply:
  bash $WORKSPACE/workflows/self-improve.sh --auto-approve

Or review first:
  cat $PROPOSALS_FILE"
else
  APPLIED_LOG=$(ls -t "$RESULTS_DIR"/applied-*.log 2>/dev/null | head -1 || echo "no log")
  NOTIFY_MSG="[$STATUS_ICON] Self-improve run: $TIMESTAMP

Mode: auto-approve
Changes: $PROPOSAL_COUNT processed
Applied log: $APPLIED_LOG"
fi

# Send Telegram notification via OpenClaw gateway
CLAWD_URL="http://localhost:18789"
CLAWD_TOKEN=$(python3 -c "
import json, os
with open(os.path.expanduser('~/.openclaw/openclaw.json')) as f:
    d = json.load(f)
print(d['gateway']['auth']['token'])
" 2>/dev/null || echo "")

if [ -n "$CLAWD_TOKEN" ]; then
  TMPFILE=$(mktemp /tmp/notify-args-XXXXXX.json)
  python3 -c "
import json, sys
print(json.dumps({
    'target': '991233',
    'channel': 'telegram',
    'message': sys.argv[1]
}))
" "$NOTIFY_MSG" > "$TMPFILE"

  curl -s -X POST "$CLAWD_URL/tools/invoke" \
    -H "Authorization: Bearer $CLAWD_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"message\",\"action\":\"send\",\"args\":$(cat "$TMPFILE")}" \
    >> "$LOG_FILE" 2>&1 && log "Telegram notification sent" || log "WARNING: Telegram notification failed"

  rm -f "$TMPFILE"
else
  log "WARNING: Could not read CLAWD_TOKEN -- Telegram notification skipped"
fi

log "Self-improvement cron job finished (exit $EXIT_CODE)"
exit "$EXIT_CODE"
