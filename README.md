# agentkit

A reusable coordination layer for multi-agent work: one coordinator, a set of
role profiles, per-role model pinning, deterministic state checkpoints, and a
health check.

It assumes agents run as CLIs (`claude`, `codex`, `agy`, …) and, optionally, that
Orca supervises them.

## Use

```bash
cd my-project
agentkit init                    # generic scaffold
agentkit init --preset ros2-usv  # or start from a domain preset
agentkit doctor                  # verify before trusting it
```

Then fill the placeholders in `AGENTS.md` and `agents/orchestrator.md`. Those two
files are the project's own knowledge; everything else arrives working.

## What lands in a project

```
AGENTS.md                 read by codex and agy
CLAUDE.md                 read by claude — coordinator identity
.claude/settings.json     project-level hooks; global settings untouched
agents/
  core.md                 KIT-MANAGED — coordination machinery, do not edit
  orchestrator.md         this project's coordinator facts
  roles.toml              which agent runs on which model — the only place
  <role>.md               role doctrine
  checkpoint.sh           KIT-MANAGED — zero-token state capture
  orchestrator.sh         KIT-MANAGED — launcher, reads roles.toml
```

Kit-managed files are overwritten by `agentkit update`. Edit them here, not
there.

## Two ideas worth keeping

**Doctrine splits by section, not by file.** Coordination machinery — layers,
worker placement, messaging, dispatch, the council protocol, session
disposability — is the same everywhere and lives in `core.md`. Only project facts
go in `orchestrator.md`. Without that split every project drifts its own copy.

**Launch config has exactly one home.** `roles.toml` maps role → cli, model,
effort, layer, profile. Nothing else names a model. Any role can declare a
`[roles.<name>.fallback]` block that takes over when an availability toggle flips
to false — that is how an exhausted quota is survived without losing the real
intent, and how it is reverted with one boolean.

## Commands

- `init [--preset NAME] [--project NAME] [--force]` — scaffold; existing files
  are skipped unless `--force`
- `update` — refresh kit-managed files only; project files are never touched
- `doctor` — layout, `roles.toml` parse, profile existence, CLIs on PATH, model
  ids checked against the live provider list, hooks wired, core drift, Orca
  reachability, and which CLIs are not valid `--agent` ids

`doctor` encodes failures found the hard way. `--agent agy` is rejected by Orca,
so agy workers need `terminal create --command` plus `worker-start --terminal`;
it says so instead of letting you find out from a failed dispatch.

## Layers

| Layer | What | Cost |
|---|---|---|
| 0 | scripted, deterministic | shell, no model |
| 1 | coordinator: scoping, structural queries, evidence packs | — |
| 2a | one-shot call, no supervised worker | one invocation |
| 2b | supervised worker | full session |
| 3 | council: two vendors cross-reading | human request only |

Escalate only as far as the question requires. Layer 0 work never goes to an
agent, and the council never starts on the coordinator's own initiative.
