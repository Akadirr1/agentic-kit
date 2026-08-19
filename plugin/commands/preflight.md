---
allowed-tools: Bash, Read, Edit
description: Prove every role in roles.toml actually launches unblocked
argument-hint: "[--role NAME] [--launch] [--handshake]"
---

## Context

- Static check: !`AK="${CLAUDE_PLUGIN_ROOT:-}/scripts/agentkit"; [ -x "$AK" ] || AK="$(command -v agentkit || echo agentkit)"; "$AK" preflight $ARGUMENTS 2>&1 | tail -60`

## Your task

Report whether every role can actually start, and fix what is fixable.

Read the output above, then:

1. **Name the failures, not the totals.** For each role that failed, say which
   check failed and what it means: a missing CLI, a missing profile, an
   untrusted directory, a model the launch cannot carry.
2. **Untrusted directories are already handled** — preflight records trust when
   it runs. If a role still reports untrusted, the trust store was unwritable;
   say which file and why that matters (an unattended pane will stop on the
   prompt and look hung).
3. **A model warning is not cosmetic.** If Orca refuses launch-time model
   selection for an agent, that role's `roles.toml` pin has no effect. Say so
   and point at the CLI's own configuration as the place to set it.
4. **If `--launch` or `--handshake` ran**, distinguish the two failure classes
   the output separates: a pane parked on a prompt is a configuration problem,
   a pane that reached idle but failed readiness is the CLI. Do not blur them.

If everything passes, say so in one line and stop. Do not restate the table.

Load the `agentkit-launch` skill before interpreting an unfamiliar failure.
