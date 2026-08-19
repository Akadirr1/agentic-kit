---
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
description: Scaffold the agentkit coordination layer here, then fill it from this repository
argument-hint: "[--project NAME] [--force]"
---

## Context

- Repository: !`git remote -v 2>/dev/null | head -2; git log --oneline -5 2>/dev/null`
- Layout: !`ls -a | head -40`

## Your task

Scaffold the layer, then finish it from the repository itself.

**Step 1 — scaffold.** Run the CLI shipped with this plugin:
`"$CLAUDE_PLUGIN_ROOT/scripts/agentkit" init $ARGUMENTS` — or plain
`agentkit init $ARGUMENTS` if you cloned the repository and put it on PATH. Existing files are skipped
unless `--force`, so this is safe to run in a project that already has some of it.

**Step 2 — read the repository, do not interview the human.** Open the README,
the package manifests, the CI configuration, the test layout, and recent git
history. Everything you can read, you must not ask about.

**Step 3 — fill `AGENTS.md` and `agents/orchestrator.md`** from what you found:
where truth lives, which branches mean what, how tests run, what the recurring
failure mode is if the history shows one.

**The one hard rule: never invent an invariant.** A constraint that cannot be
traced to a document, a config that enforces it, or the human saying so does not
get written. An empty section is honest; a fabricated one reads as authoritative
and nobody re-checks it. If you inferred something, label it as inference.

**Step 4 — prune the roles this project has no use for.** A `safety` role on a
static site is noise; a `safety` role on anything that moves, spends money, or
deletes data is not. Match each role's model to how hard its job actually is
here — the cheap tier exists to be used.

**Step 5 — ask once, for what is left.** Collect the genuine gaps into one short
list. Do not ask in a drip.

**Step 6 — propose, do not commit.** Present the filled files as a diff for
approval. These govern every future session; the human signs them off.

Then run `agentkit doctor` and report what remains.
