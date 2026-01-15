#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/ralph/ralph.sh [options] [iterations]

Options:
  -c, --client <codex|claude>   Which CLI to run (default: codex)
  -h, --help                    Show this help and exit

Examples:
  ./scripts/ralph/ralph.sh 25
  ./scripts/ralph/ralph.sh --client claude 10
EOF
}

CLIENT="codex"
MAX_ITERATIONS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--client)
      CLIENT="${2:-}"
      if [[ -z "$CLIENT" ]]; then
        echo "Missing value for $1" >&2
        usage
        exit 1
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      if [[ -n "$MAX_ITERATIONS" ]]; then
        echo "Iterations already set to $MAX_ITERATIONS; extra value '$1' is unexpected." >&2
        usage
        exit 1
      fi
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS="$1"
        shift
      else
        echo "Iterations must be a positive integer (received '$1')." >&2
        usage
        exit 1
      fi
      ;;
  esac
done

MAX_ITERATIONS=${MAX_ITERATIONS:-10}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROMPT_FILE="$SCRIPT_DIR/prompt.md"

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

case "$CLIENT" in
  codex)
    REQUIRED_BIN="codex"
    CLIENT_LABEL="Codex"
    RUN_MODE="pipe"
    AGENT_CMD=(
      codex exec
      --dangerously-bypass-approvals-and-sandbox
      --sandbox danger-full-access
      --cd "$PROJECT_ROOT"
    )
    ;;
  claude)
    REQUIRED_BIN="claude"
    CLIENT_LABEL="Claude"
    RUN_MODE="arg"
    AGENT_CMD=(
      claude
      --print
      --permission-mode acceptEdits
    )
    ;;
  *)
    echo "Unsupported client '$CLIENT'. Use 'codex' or 'claude'." >&2
    exit 1
    ;;
esac

if ! command -v "$REQUIRED_BIN" >/dev/null 2>&1; then
  echo "$REQUIRED_BIN CLI is not installed or not on PATH" >&2
  exit 1
fi

run_iteration() {
  local output prompt_text
  case "$RUN_MODE" in
    pipe)
      output=$(cat "$PROMPT_FILE" \
        | "${AGENT_CMD[@]}" 2>&1 \
        | tee /dev/stderr) || true
      ;;
    arg)
      prompt_text=$(<"$PROMPT_FILE")
      output=$(
        cd "$PROJECT_ROOT" && \
        "${AGENT_CMD[@]}" "$prompt_text" 2>&1 \
        | tee /dev/stderr
      ) || true
      ;;
    *)
      echo "Unknown run mode '$RUN_MODE'." >&2
      exit 1
      ;;
  esac

  printf '%s' "$output"
}

printf '\n🚀 Starting Ralph (%s)\n' "$CLIENT_LABEL"
for i in $(seq 1 "$MAX_ITERATIONS"); do
  printf '\n═══ Iteration %s/%s ═══\n' "$i" "$MAX_ITERATIONS"

  OUTPUT=$(run_iteration)

  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    printf '✅ Done!\n'
    exit 0
  fi

  sleep 2
done

printf '\n⚠️  Max iterations (%s) reached without completion.\n' "$MAX_ITERATIONS" >&2
exit 1
