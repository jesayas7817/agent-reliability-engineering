#!/usr/bin/env bash
# self-improve.sh -- Self-improving skills pipeline
#
# Analyzes agent eval results, proposes targeted improvements,
# and applies them after human approval.
#
# Usage:
#   ./self-improve.sh              # interactive (prompts for approval)
#   ./self-improve.sh --dry-run    # generate proposals only, do not apply
#   ./self-improve.sh --auto-approve  # skip prompt (cron use)

set -euo pipefail

WORKSPACE="$HOME/.openclaw/workspace"
EVALS_DIR="$WORKSPACE/evals"
RESULTS_DIR="$EVALS_DIR/results"
TIMESTAMP=$(date +%Y-%m-%d)

DRY_RUN=false
AUTO_APPROVE=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --auto-approve) AUTO_APPROVE=true ;;
  esac
done

CLAWD_URL="http://localhost:18789"
CLAWD_TOKEN=$(python3 -c "
import json, os
with open(os.path.expanduser('~/.openclaw/openclaw.json')) as f:
    d = json.load(f)
print(d['gateway']['auth']['token'])
" 2>/dev/null || echo "")

if [ -z "$CLAWD_TOKEN" ]; then
  echo "ERROR: Could not read OpenClaw gateway token"
  exit 1
fi

log() { echo "[$(date +%H:%M:%S)] $*"; }
section() { echo ""; echo "=== $* ==="; echo ""; }

# Call the LLM via gateway REST API.
# All prompt construction happens in Python to avoid shell quoting issues.
llm_invoke() {
  local prompt_file="$1"
  local tmpargs
  tmpargs=$(mktemp)
  python3 -c "
import json, sys
prompt = open(sys.argv[1]).read()
print(json.dumps({'prompt': prompt, 'model': 'claude-opus-4-6'}))
" "$prompt_file" > "$tmpargs"

  local result
  result=$(curl -s -X POST "$CLAWD_URL/tools/invoke" \
    -H "Authorization: Bearer $CLAWD_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"llm-task\",\"action\":\"run\",\"args\":$(cat "$tmpargs")}" \
    2>/dev/null)
  rm -f "$tmpargs"

  local ok
  ok=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('ok',''))" 2>/dev/null || echo "")
  if [ "$ok" != "True" ]; then
    echo "LLM_ERROR: $(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error',{}).get('message','unknown'))" 2>/dev/null)" >&2
    exit 1
  fi

  # Extract text from response
  echo "$result" | python3 -c "
import json, sys
d = json.load(sys.stdin)
content = d.get('result', {}).get('content', [])
for item in content:
    if item.get('type') == 'text':
        t = item['text']
        if t.startswith('\"') and t.endswith('\"'):
            try: t = json.loads(t)
            except: pass
        print(t)
        break
"
}

# ----------------------------------------------------------------
section "STEP 1: Collecting automated metrics"
log "Running collect-metrics.sh..."
METRICS_FILE=$(mktemp)
bash "$EVALS_DIR/scripts/collect-metrics.sh" > "$METRICS_FILE" 2>&1 || true
cat "$METRICS_FILE" | head -30
log "Metrics collected ($(wc -c < "$METRICS_FILE") bytes)"

# ----------------------------------------------------------------
section "STEP 2: Reading latest manual scores"
LATEST_RESULTS=$(ls -t "$RESULTS_DIR"/*.md 2>/dev/null | head -1 || echo "")
SCORES_FILE=$(mktemp)
if [ -z "$LATEST_RESULTS" ]; then
  log "WARNING: No results files found in $RESULTS_DIR"
  echo "No manual scores available yet. This is the first eval cycle." > "$SCORES_FILE"
else
  log "Reading: $LATEST_RESULTS"
  cat "$LATEST_RESULTS" > "$SCORES_FILE"
  head -40 "$SCORES_FILE"
fi

# ----------------------------------------------------------------
section "STEP 3: LLM analysis -- identifying weak areas"
log "Asking LLM to analyze metrics and scores..."

ANALYSIS_PROMPT=$(mktemp)
python3 -c "
import sys
metrics = open(sys.argv[1]).read()
scores = open(sys.argv[2]).read()
scores_label = sys.argv[3]

prompt = f'''You are analyzing agent performance data to identify areas for improvement.

## Automated Metrics
{metrics}

## Manual Scores ({scores_label})
{scores}

## Scoring Rubric
- Success/Autonomy/Efficiency each scored 1-5 (5=perfect, 1=failed)

## Agents
- Ada: software engineering (SSH, Docker, git, debugging, infrastructure)
- Patsy: healthcare admin (appointments, insurance, records)
- Rita: research and personal assistant
- Signora: main orchestrator (coordinates agents, memory, heartbeats)

## Task
Identify the weakest areas per agent based on available data.
If manual scores are empty, use incident keywords and memory file density as proxy signals.
Focus on Ada and Signora (most activity). Max 4 items total.

Return a JSON array only (no markdown, no text outside JSON):
[
  {{
    \"agent\": \"Ada\",
    \"weak_area\": \"brief description\",
    \"evidence\": \"specific evidence from data\",
    \"improvement_type\": \"soul_refinement\",
    \"priority\": \"high\"
  }}
]
Allowed improvement_type: soul_refinement, skill_update, procedure, golden_set
Allowed priority: high, medium, low'''

print(prompt)
" "$METRICS_FILE" "$SCORES_FILE" "$LATEST_RESULTS" > "$ANALYSIS_PROMPT"

ANALYSIS_FILE=$(mktemp)
llm_invoke "$ANALYSIS_PROMPT" > "$ANALYSIS_FILE"
rm -f "$ANALYSIS_PROMPT"
log "Analysis result:"
cat "$ANALYSIS_FILE"

# Extract and validate JSON
ANALYSIS_JSON=$(mktemp)
python3 -c "
import json, sys, re
text = open(sys.argv[1]).read().strip()
# Try direct parse
try:
    parsed = json.loads(text)
    print(json.dumps(parsed, indent=2))
    sys.exit(0)
except: pass
# Try to find JSON array in text
match = re.search(r'\[.*\]', text, re.DOTALL)
if match:
    try:
        parsed = json.loads(match.group())
        print(json.dumps(parsed, indent=2))
        sys.exit(0)
    except: pass
print('[]')
" "$ANALYSIS_FILE" > "$ANALYSIS_JSON"

ANALYSIS_COUNT=$(python3 -c "import json; print(len(json.load(open('$ANALYSIS_JSON'))))" 2>/dev/null || echo "0")
log "$ANALYSIS_COUNT weak areas identified"

# ----------------------------------------------------------------
section "STEP 4: LLM generation -- producing improvement proposals"
log "Asking LLM to generate concrete improvement proposals..."

GENERATE_PROMPT=$(mktemp)
python3 -c "
import json, sys
analysis = open(sys.argv[1]).read()

prompt = f'''You are generating specific, actionable improvement proposals for AI agents.

## Weakness Analysis
{analysis}

## Agent File Locations
- Signora: /home/choutos/.openclaw/workspace/SOUL.md
- Ada: /home/choutos/.openclaw/workspace-ada/SOUL.md
- Patsy: /home/choutos/.openclaw/workspace-patsy/SOUL.md
- Rita: /home/choutos/.openclaw/workspace-rita/SOUL.md
- Shared skills: /home/choutos/.openclaw/skills/
- Golden sets: /home/choutos/.openclaw/workspace/evals/golden-sets/<agent>.md

## Task
For each weakness, generate one concrete change:
- soul_refinement: new section to append to agent SOUL.md
- skill_update: full content for a new skill SKILL.md
- procedure: step-by-step procedure block to add to SOUL.md
- golden_set: new test case in golden set format

Rules:
- Keep changes minimal and targeted (one change per weakness)
- No em dashes in any generated content
- new_content must be complete and ready to use (no placeholders)
- append: added at end of file with two blank lines before it
- replace: search_text must be exact text currently in the file
- create: creates a new file

Return a JSON array only (no markdown, no text outside JSON):
[
  {{
    \"agent\": \"Ada\",
    \"weak_area\": \"...\",
    \"file_path\": \"/home/choutos/.openclaw/workspace-ada/SOUL.md\",
    \"change_type\": \"append\",
    \"search_text\": \"\",
    \"new_content\": \"exact text to write\",
    \"rationale\": \"one sentence why this helps\"
  }}
]'''

print(prompt)
" "$ANALYSIS_JSON" > "$GENERATE_PROMPT"

PROPOSALS_RAW=$(mktemp)
llm_invoke "$GENERATE_PROMPT" > "$PROPOSALS_RAW"
rm -f "$GENERATE_PROMPT"
log "Proposals result:"
cat "$PROPOSALS_RAW"

# Extract and validate JSON
PROPOSALS_JSON=$(mktemp)
python3 -c "
import json, sys, re
text = open(sys.argv[1]).read().strip()
try:
    parsed = json.loads(text)
    print(json.dumps(parsed, indent=2))
    sys.exit(0)
except: pass
match = re.search(r'\[.*\]', text, re.DOTALL)
if match:
    try:
        parsed = json.loads(match.group())
        print(json.dumps(parsed, indent=2))
        sys.exit(0)
    except: pass
print('[]')
" "$PROPOSALS_RAW" > "$PROPOSALS_JSON"

PROPOSAL_COUNT=$(python3 -c "import json; print(len(json.load(open('$PROPOSALS_JSON'))))" 2>/dev/null || echo "0")
log "$PROPOSAL_COUNT proposals generated"

# Cleanup temp files
rm -f "$METRICS_FILE" "$SCORES_FILE" "$ANALYSIS_FILE" "$ANALYSIS_JSON" "$PROPOSALS_RAW"

if [ "$PROPOSAL_COUNT" = "0" ]; then
  log "No proposals generated. Nothing to apply."
  exit 0
fi

# Save proposals for reference
mkdir -p "$RESULTS_DIR"
PROPOSALS_FILE="$RESULTS_DIR/proposals-$TIMESTAMP.json"
cp "$PROPOSALS_JSON" "$PROPOSALS_FILE"
rm -f "$PROPOSALS_JSON"
log "Proposals saved to: $PROPOSALS_FILE"

# ----------------------------------------------------------------
section "STEP 5: Human approval"

if $DRY_RUN; then
  log "DRY RUN -- proposals saved, no changes applied."
  echo ""
  python3 -c "
import json
proposals = json.load(open('$PROPOSALS_FILE'))
for i, p in enumerate(proposals, 1):
    print(f'  {i}. [{p.get(\"agent\",\"?\")}] {p.get(\"weak_area\",\"?\")}')
    print(f'     File: {p.get(\"file_path\",\"?\")}')
    print(f'     Type: {p.get(\"change_type\",\"?\")} -- {p.get(\"rationale\",\"?\")}')
    print()
"
  echo "To apply:"
  echo "  bash $WORKSPACE/workflows/self-improve.sh --auto-approve"
  echo "  (optionally edit $PROPOSALS_FILE first)"
  exit 0
fi

if $AUTO_APPROVE; then
  log "AUTO-APPROVE: skipping confirmation."
  APPROVED=true
else
  echo ""
  echo "$PROPOSAL_COUNT proposed changes:"
  python3 -c "
import json
proposals = json.load(open('$PROPOSALS_FILE'))
for i, p in enumerate(proposals, 1):
    print(f'  {i}. [{p.get(\"agent\",\"?\")}] {p.get(\"weak_area\",\"?\")}')
    print(f'     File: {p.get(\"file_path\",\"?\")}')
    print(f'     Type: {p.get(\"change_type\",\"?\")} -- {p.get(\"rationale\",\"?\")}')
    print()
"
  echo "Full proposals: $PROPOSALS_FILE"
  echo "(Edit that file to remove items before approving)"
  echo ""
  read -p "Apply these changes? [y/N] " -r REPLY
  [[ "$REPLY" =~ ^[Yy]$ ]] && APPROVED=true || APPROVED=false
fi

if [ "$APPROVED" = false ]; then
  log "Not approved. Proposals saved at: $PROPOSALS_FILE"
  exit 0
fi

# ----------------------------------------------------------------
section "STEP 6: Applying approved changes"

APPLIED_LOG="$RESULTS_DIR/applied-$TIMESTAMP.log"

python3 << PYEOF
import json, os, datetime

proposals_file = "$PROPOSALS_FILE"
applied_log = "$APPLIED_LOG"
home = os.path.expanduser("~")

with open(proposals_file) as f:
    proposals = json.load(f)

# Safety: only write to known agent workspace directories
allowed = [
    os.path.join(home, ".openclaw", "workspace"),
    os.path.join(home, ".openclaw", "workspace-ada"),
    os.path.join(home, ".openclaw", "workspace-patsy"),
    os.path.join(home, ".openclaw", "workspace-rita"),
    os.path.join(home, ".openclaw", "workspace-ciro"),
    os.path.join(home, ".openclaw", "workspace-colette"),
    os.path.join(home, ".openclaw", "workspace-ferruccio"),
    os.path.join(home, ".openclaw", "skills"),
]

applied = 0
skipped = 0
lines = [
    "Applied changes log",
    f"Timestamp: {datetime.datetime.utcnow().isoformat()}Z",
    f"Source: {proposals_file}",
    "",
]

for p in proposals:
    agent = p.get("agent", "?")
    area = p.get("weak_area", "?")
    fpath = os.path.expanduser(p.get("file_path", ""))
    ctype = p.get("change_type", "append")
    content = p.get("new_content", "")
    search = p.get("search_text", "")
    reason = p.get("rationale", "")

    def skip(msg):
        global skipped
        m = f"SKIP [{agent}] {area}: {msg}"
        print(m); lines.append(m); skipped += 1

    def ok(msg):
        global applied
        m = f"{msg} [{agent}] {fpath}"
        print(m); lines.append(m); lines.append(f"  Reason: {reason}"); applied += 1

    if not fpath or not content:
        skip("missing file_path or new_content"); continue
    if not any(fpath.startswith(a) for a in allowed):
        skip(f"path not in allowed locations: {fpath}"); continue

    try:
        os.makedirs(os.path.dirname(fpath) or ".", exist_ok=True)
        if ctype == "create":
            with open(fpath, "w") as f: f.write(content)
            ok("CREATED")
        elif ctype == "append":
            with open(fpath, "a") as f: f.write("\n\n" + content)
            ok("APPENDED")
        elif ctype == "replace":
            if not search: skip("replace requires search_text"); continue
            if not os.path.exists(fpath): skip("file not found"); continue
            orig = open(fpath).read()
            if search not in orig: skip("search_text not found in file"); continue
            with open(fpath, "w") as f: f.write(orig.replace(search, content, 1))
            ok("REPLACED")
        else:
            skip(f"unknown change_type '{ctype}'")
    except Exception as e:
        skip(f"error: {e}")

lines += ["", f"Summary: {applied} applied, {skipped} skipped"]
print(f"\nDone. {applied} applied, {skipped} skipped. Log: {applied_log}")
with open(applied_log, "w") as f: f.write("\n".join(lines) + "\n")
PYEOF

log "Self-improvement pipeline complete."
