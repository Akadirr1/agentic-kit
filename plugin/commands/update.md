---
allowed-tools: Bash, Read, Edit
description: Refresh the kit-managed files in this project and report what changed
---

## Context

- Update: !`AK="${CLAUDE_PLUGIN_ROOT:-}/scripts/agentkit"; [ -x "$AK" ] || AK="$(command -v agentkit || echo agentkit)"; "$AK" update 2>&1`
- Working tree: !`git status --short 2>/dev/null | head -20`

## Your task

Say what changed and what it means for this project.

- **Only `core/` is kit-managed.** Project files — `roles.toml`,
  `orchestrator.md`, `AGENTS.md`, role profiles — are never touched. If a role
  profile needs the new doctrine, that is a manual edit, and it is worth saying
  so explicitly rather than letting the operator assume `update` covered it.
- **A file that changed carries new doctrine.** Read the diff for
  `agents/core.md` and summarise what rule is new, in one or two lines. Do not
  paste the diff.
- **A local edit to a kit-managed file has just been overwritten.** If the
  working tree shows one, say what was lost and that the edit belongs in the kit
  repository instead.

Finish with whether anything else needs doing before the next dispatch.
