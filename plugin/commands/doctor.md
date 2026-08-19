---
allowed-tools: Bash, Read, Edit
description: Verify the agentkit layout, roles, CLIs, hooks, and knowledge stores
---

## Context

- Health check: !`AK="${CLAUDE_PLUGIN_ROOT:-}/scripts/agentkit"; [ -x "$AK" ] || AK="$(command -v agentkit || echo agentkit)"; "$AK" doctor 2>&1 | tail -70`

## Your task

Turn the check into a short list of what to do, in the order it should be done.

- **Failures block work; warnings usually do not.** Separate them, and lead with
  anything that would make a dispatch fail rather than anything cosmetic.
- **Core drift means a local edit will be lost.** If a kit-managed file differs,
  say which one and that `agentkit update` overwrites it — the edit belongs in
  the kit repository, not in the project.
- **Placeholders left in `AGENTS.md` or `agents/orchestrator.md`** mean the
  bootstrap never finished. That is the highest-value fix: every later session
  reads those files.
- **A missing knowledge store is not automatically a problem.** Say what is
  unavailable as a result — no graph means structure questions fall back to
  grep, no vault means decisions have nowhere canonical to live.

If the project is healthy, say so in one line.
