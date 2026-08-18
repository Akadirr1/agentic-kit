#!/usr/bin/env bash
# Launch the USV coordinator.
#
# Save this as an Orca command so the coordinator can be started on demand,
# or run it by hand:
#
#     ./agents/orchestrator.sh
#
# Model and effort come from agents/roles.toml [roles.orchestrator].

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

read -r MODEL EFFORT <<<"$(python3 - <<'PY'
import tomllib
r = tomllib.load(open("agents/roles.toml", "rb"))["roles"]["orchestrator"]
print(r.get("model") or "opus", r.get("effort") or "")
PY
)"

if [ -n "$EFFORT" ]; then
  export CLAUDE_EFFORT="$EFFORT"
fi

exec claude --model "$MODEL" \
  "You are the USV coordinator. Read AGENTS.md and agents/orchestrator.md, then run the session-start procedure in agents/orchestrator.md and report the reconciled state plus the task you propose. Do not change code."
