# agentkit

A reusable coordination layer for multi-agent work: one coordinator, a set of
role profiles, per-role model pinning, deterministic state checkpoints, and a
health check.

It assumes agents run as CLIs (`claude`, `codex`, `agy`, …) and, optionally, that
Orca supervises them.

## Use

```bash
cd my-project
agentkit init          # scaffold — works the same for web, mobile, backend, robotics
agentkit doctor        # verify before trusting it
```

Then open the coordinator and let it bootstrap the project. `agents/bootstrap.md`
has it read the repository — README, manifests, CI config, test layout, git
history — fill `AGENTS.md` and `agents/orchestrator.md` from what it finds, prune
the roles the project has no use for, ask only about what it could not read, and
hand you the result for approval.

That is why there are no per-domain presets to maintain. The project-specific
half is derived from the project, not from a template somebody wrote in advance.
`presets/` exists only to seed a repeat of an existing setup; the normal path
does not use it.

**The bootstrap has one hard rule: never invent an invariant.** A constraint that
cannot be traced to a document, a config that enforces it, or the human saying so
does not get written. An empty section is honest; a fabricated one reads as
authoritative and nobody re-checks it.

## What lands in a project

```
AGENTS.md                 read by codex and agy
CLAUDE.md                 read by claude — coordinator identity
.claude/settings.json     project-level hooks; global settings untouched
agents/
  core.md                 KIT-MANAGED — coordination machinery, do not edit
  bootstrap.md            KIT-MANAGED — first-run procedure
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
  ids checked against the live provider list, remaining bootstrap placeholders,
  hooks wired, core drift, Orca reachability, and which CLIs are not valid
  `--agent` ids
- `preflight [--role NAME] [--launch] [--handshake] [--json]` — prove every role
  actually starts. Static by default: CLI present, profile present, the exact
  launch command including its permission-bypass flag, and whether this
  directory is trusted for that CLI. `--launch` opens each role's real command
  in an Orca pane, waits for `tui-idle`, reads the pane back and fails if it is
  sitting on a trust, login, or approval prompt. `--handshake` additionally
  probes `worker-start` for 2b roles and cleans up the task, worker, and pane.

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
