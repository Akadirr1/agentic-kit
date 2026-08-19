---
name: agentkit
description: Set up or operate the agentkit coordination layer in a project — scaffolding agents/, choosing which layer a piece of work belongs to, keeping one coordinator with disposable workers, and checkpointing state without a model. Use when a project needs multi-agent coordination, when deciding whether to delegate a task and to what, or when agentkit's own files need installing, updating, or diagnosing.
---

# agentkit

A coordination layer for projects where more than one agent works on the same
repository. One coordinator, role profiles, per-role model pinning, and state
that survives a session dying mid-sentence.

## Commands

```bash
agentkit init          # scaffold agents/, AGENTS.md, CLAUDE.md, project hooks
agentkit doctor        # verify layout, roles, CLIs, model ids, hooks, stores
agentkit preflight     # prove every role actually launches — see agentkit-launch
agentkit update        # refresh kit-managed files only
```

`init` writes the scaffold and then hands off: the coordinator reads the
repository — README, manifests, CI config, test layout, git history — fills
`AGENTS.md` and `agents/orchestrator.md` from what it finds, prunes roles the
project has no use for, and presents the result for approval. That is why there
are no per-domain presets to maintain.

**The bootstrap has one hard rule: never invent an invariant.** A constraint that
cannot be traced to a document, a config that enforces it, or the human saying so
does not get written. An empty section is honest; a fabricated one reads as
authoritative and nobody re-checks it.

## Layers — escalate only as far as the question requires

| Layer | What | Cost |
|---|---|---|
| 0 | Scripted and deterministic: graph rebuilds, link scans, `git fetch` | shell, no model |
| 1 | The coordinator: reconciliation, scoping, structural queries, evidence packs | — |
| 2a | One-shot call, no supervised worker, no lifecycle | one invocation |
| 2b | Supervised worker in its own pane | full session |
| 3 | Council: two vendors cross-reading one evidence pack | human request only |

Layer 0 work never goes to an agent. The council never starts on the
coordinator's own initiative. `agents/roles.toml` maps each role to its CLI,
model, effort, and layer — read it instead of hard-coding launch flags.

## What the coordinator does not do

It does not write production code, and it does not approve its own plan.
Implementation goes to an implementer; `reviewer`, `safety`, and `test-verifier`
inspect the resulting diff independently. If agents disagree, preserve both
claims, identify the evidence each used, and request a discriminating
measurement — never settle a technical disagreement by majority.

## Two rules that keep this from rotting

**Doctrine splits by section, not by file.** Coordination machinery is the same
everywhere and lives in `agents/core.md`, which the kit owns and overwrites on
update. Only project facts go in `agents/orchestrator.md`. Without that split
every project drifts its own copy.

**Launch config has exactly one home.** `roles.toml` maps role to CLI, model,
effort, layer, and profile. Nothing else names a model. Any role may declare a
`fallback` block that takes over when an availability toggle flips, which is how
an exhausted quota is survived without losing the real intent — and reverted
with one boolean.

## Long output goes to a file

A report streamed through orchestration messages lands in the coordinator's
context verbatim and is re-read on every subsequent turn. One 15K-token report
delivered in six messages cost roughly a million tokens of re-reads before it
reached durable storage. Every dispatch names a report path; the worker writes
there and sends the path plus a summary of at most ten lines. The coordinator
verifies the report where it lies and never copies its body into the
conversation.

## Sessions are disposable

The context window is working memory, not storage. Durable state lives in git,
in the orchestration database, in the knowledge stores, and in `agents/` —
never in a conversation.

Sessions do not end politely: the app gets closed, the limit runs out, the
process dies. Any rule of the form "write the handoff before you finish" breaks
precisely when it matters. So checkpoint at boundaries that already happen —
after each accepted completion, each gate decision, each measurement. The
marginal cost is a few lines and the maximum loss is one unit of work.

`checkpoint.sh` runs on Stop, SessionEnd, and SessionStart without a model and
records mechanical facts only: branch, commit, dirty count, open tasks.
Reasoning is yours to record.

For launching, permissions, trust, and the 2a/2b decision, load
`agentkit-launch`.
