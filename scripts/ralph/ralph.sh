#!/usr/bin/env bash
set -euo pipefail

MAX_ITERATIONS=${1:-10}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROMPT_FILE="$SCRIPT_DIR/prompt.md"

if ! command -v codex >/dev/null 2>&1; then
  echo "codex CLI is not installed or not on PATH" >&2
  exit 1
fi

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "Missing prompt file at $PROMPT_FILE" >&2
  exit 1
fi

if [[ ! -f "$SCRIPT_DIR/prd.json" ]]; then
  echo "Missing prd.json. Create it before running Ralph." >&2
  exit 1
fi

if [[ ! -f "$SCRIPT_DIR/progress.txt" ]]; then
  echo "Missing progress.txt. Create it before running Ralph." >&2
  exit 1
fi

CODEX_CMD=(
  codex exec
  --dangerously-bypass-approvals-and-sandbox
  --sandbox danger-full-access
  --cd "$PROJECT_ROOT"
)

printf '\n🚀 Starting Ralph (Codex)\n'
for i in $(seq 1 "$MAX_ITERATIONS"); do
  printf '\n═══ Iteration %s/%s ═══\n' "$i" "$MAX_ITERATIONS"

  OUTPUT=$(cat "$PROMPT_FILE" \
    | "${CODEX_CMD[@]}" 2>&1 \
    | tee /dev/stderr) || true

  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    printf '✅ Done!\n'
    exit 0
  fi

  sleep 2
done

printf '\n⚠️  Max iterations (%s) reached without completion.\n' "$MAX_ITERATIONS" >&2
exit 1
