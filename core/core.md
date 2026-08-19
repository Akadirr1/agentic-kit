---
name: core
description: Generic multi-agent coordination doctrine shared across projects. Copied from agentkit; do not edit here — run `agentkit update` instead.
---

# Coordination core

This file is machinery, not project knowledge. It is copied verbatim by
`agentkit` and overwritten on update, so edits here are lost. Anything true only
of one project belongs in that project's `agents/orchestrator.md`.


## Layers

Escalate only as far as the question requires.

- **Layer 0 — no model.** `graphify update`, `relabel.py`, the vault wikilink
  scanner, `git fetch`. Shell commands. Never delegate these to an agent.
- **Layer 1 — you.** Reconciliation, scoping, graph queries, evidence packs,
  merging worker reports.
- **Layer 2a — one-shot calls.** A single non-interactive invocation returning
  text or JSON. No supervised worker, no lifecycle. Use for summarising,
  classifying, drafting.
- **Layer 2b — supervised workers.** Orca orchestration workers for multi-step
  work that reads widely or changes files.
- **Layer 3 — council.** Two large models cross-reading each other. Runs only
  when the human asks for it. Never start it on your own initiative.

`agents/roles.toml` maps each role to its CLI, model, effort, and layer. Read it
rather than hard-coding launch flags.

When `[settings] codex_available = false`, every role that declares a
`[roles.<name>.fallback]` block runs that block instead. Resolve the effective
launch config from the toggle before building any command; do not read the
top-level fields alone. `council-b` deliberately falls back to a third vendor
rather than to claude, because a claude-versus-claude council defeats its
purpose.

State is checkpointed by `agents/checkpoint.sh`, wired to Stop, SessionEnd, and
SessionStart hooks in `.claude/settings.json`. It runs without a model and writes
`.orchestrator/journal.md`. It captures mechanical facts only — branch, commit,
dirty count, open tasks. Reasoning is yours to record; see Sessions are
disposable.

## Workers run in the current worktree

Use `--worktree current`. A fresh worker means a fresh agent session, not a new
git checkout. Create a worktree only when the human asks for one or a concrete
filesystem conflict makes sharing unsafe — and state that conflict first.

Account for every settled worker: reuse it, retain it at the human's request, or
release it. Released workers stay readable.

**Every worker opens as an Orca pane — Claude workers included.** The human
supervises through the agent window; a worker spawned as an in-session subagent
is invisible there, so that path is a fallback for when Orca is unreachable, and
using it must be stated in the handoff. Idle notifications are part of that
visibility: do not suppress them.

Some CLIs never answer the supervised-worker handshake (`worker-start` fails at
`agent_readiness` no matter how the terminal was created — seen with agy 1.1.14).
`agentkit doctor` flags them. Run those agents in a pane without supervision:
`terminal split --command`, drive them with `terminal send`, read results from
the pane, and close the loop with `task-update` yourself.

## Pane layout

Workers stack down the right-hand side, so the coordinator stays on the left and
every worker is visible at once. Build the pane first, then bind it:

```bash
# first worker of a wave — vertical split puts it to the RIGHT of you
orca terminal split --terminal <coordinator_handle> --direction vertical \
  --command "<cli and flags from roles.toml>" --json

# every worker after that — horizontal split STACKS it under the previous one
orca terminal split --terminal <previous_worker_handle> --direction horizontal \
  --command "<cli and flags from roles.toml>" --json

orca terminal wait --terminal <handle> --for tui-idle --timeout-ms 120000 --json
orca orchestration worker-start --task <task_id> --terminal <handle> --json
```

In Orca's naming `vertical` means side by side and `horizontal` means stacked;
the handle comes back at `result.split.handle`.

Binding with `--terminal` means `worker-start` will not accept `--model` or
`--effort`, so put the model in the split command itself — for example
`codex -c model="gpt-5.6-sol" -c model_reasoning_effort="xhigh"` or
`agy --model gemini-3.1-pro-high`. Read those values from `agents/roles.toml`.

Close a worker's pane when its dispatch is settled and you are not reusing it;
`orca terminal close --terminal <handle>` keeps the screen readable.

## Messages

Orca injects a "you have N orchestration messages" turn when a worker sends. It
is a hook, not the human speaking.

**Read the inbox, not `check`.** `orca orchestration check` returns one delivery
batch and has already returned fewer messages than were waiting; a scribe report
was missed that way. Use `orca orchestration inbox --json` to see everything, and
use `check --wait` only as a blocking wait signal.

Every `orca ... --json` response is NDJSON: decode object by object, never with a
single `json.load`.

`check` hands out a `deliveryId`. Close it with
`orca orchestration check --ack <delivery_id>`, otherwise the same batch is
redelivered on the next call. `--peek` shows true unread count without consuming.

A `worker-start` that reports `ok: false` may still have delivered the task —
that is the `outcome_unknown` case, and it has happened here. Before retrying,
check `task-list` and `worker-list`; a second start against a dispatched task
fails with `task_not_startable`.

## Dispatch discipline

Delegation messages must be self-contained. Include the task ID, problem,
desired outcome, safety class, exact repository and base ref, worktree path,
allowed and forbidden paths, constraints, acceptance criteria, required
evidence, and rollback. Never assume a worker has seen this conversation.

**Long output goes to a file, not through messages.** A report streamed through
orchestration messages lands in the coordinator's context verbatim and gets
re-read on every subsequent turn — one 15K-token report delivered in six
messages cost roughly a million tokens of re-reads before it reached durable
storage. The dispatch spec must name a report path (the vault's draft area if
the project has one, `agents/reports/<task_id>.md` otherwise); the worker writes
there and sends only the path plus a summary of at most ten lines. The
coordinator verifies the report where it lies — spot-checking claims against the
graph and the diff — and never copies its body into the conversation.

For a review dispatch, build the evidence pack: the diff and exact base ref,
`graphify explain` for every changed node, `graphify path` from each changed node
to the project's critical nodes, the invariant boundaries that apply, and any
measurements already taken.

## Knowledge stores: the vault and the graph

Projects under this kit keep two stores beside git, and the coordinator is
their gatekeeper.

- **The vault (Obsidian)** records decisions, rationale, and field findings —
  what code cannot say. Canonical notes change only behind a human gate.
  Workers never edit canonical notes; they write into the vault's draft area
  (or `agents/reports/`) and the coordinator promotes content through the gate.
  Validate wikilinks with `agents/vault_scan.py`, never with grep or a pasted
  snippet — regex pasted through a shell heredoc has been corrupted in transit
  and produced 34 false positives.
- **The code graph (graphify)** answers structure questions. The coordinator
  holds the query monopoly: workers receive a prepared, scoped subgraph and do
  not grep the repository for structure. Blast radius comes from `graphify
  path`, not from asking a model what a change might affect. After code changes
  run `graphify update . --code-only` — AST-only, no model cost, Layer 0.

Cross-checking a worker's report against the graph is cheap and catches the
expensive class of error: a claimed dependency the graph does not show, or a
missed one it does.

## Context hygiene

The dominant token cost of a long coordinator session is not the work — it is
the fixed per-turn overhead re-read on every turn: MCP tool listings, skill
listings, global instruction files. Budget it once at project setup:

- Disable MCP servers the project does not use in `.claude/settings.json`;
  every enabled server's tool listing is a tax on all turns of every session.
- Keep the machine-wide instruction file (`~/.claude/CLAUDE.md`) near-empty;
  anything project-specific belongs in the project files.
- Prefer few large tool calls over many small ones — each call re-reads the
  whole context. Batch independent shell commands.
- Answering a settled worker's idle notification costs a full-context turn;
  keep the notifications (they are the human's visibility), but do not reply
  unless the message needs an action.

## Separation of duties

- Architects and investigators establish facts and propose boundaries.
- One implementer edits the target component.
- The implementer never runs the final review gate.
- `reviewer`, `safety`, and `test-verifier` inspect the resulting diff and
  evidence independently.
- `scribe` updates accepted project state last, behind a human gate.

If agents disagree, preserve both claims, identify the evidence each used, and
request a discriminating measurement. Never settle technical disagreement by
majority vote.

## Council protocol

Runs only on explicit human request.

**Round 1, independent.** Both models receive the identical evidence pack and
cannot see each other. The pack is the reviewer output, the scoped subgraph, the
applicable invariant boundaries, and any measurements — never the raw repository.

**Round 2, crossed.** Each receives the other's report verbatim and responds per
claim with agree / disagree / insufficient evidence. On disagreement they do not
vote; they write the discriminating measurement: the command to run, what result
proves which side.

**Merge.** You produce one table: claim · basis (measured / inferred / needs
measurement) · agreement · affected parts (from `graphify path`) · rollback.

There is no round three. If two rounds do not converge, the output is an
unresolved disagreement plus its discriminating measurement. That is the correct
result, not a failure.

## Sessions are disposable

Your context window is working memory, not storage. Orca is built this way on
purpose: a fresh worker is a fresh agent session, `--reuse-session` is opt-in and
only "when it is still available", and even a reused worker is re-engaged with a
fresh preamble rather than being trusted to remember. Durable state lives in the
Run/Task/Dispatch database, in git, in the vault, in the graph, and in these
files — never in a conversation.

Two consequences, and the second is the one that actually bites.

**Long sessions go stale silently.** A branch belief, a measurement, a git state
held in context ages without announcing it. This project has already been burned
by exactly that: a `origin/new` ref eleven days stale put wrong information into
the vault. A fresh start forces `git fetch` and reconciliation; a long-lived
coordinator quietly skips both.

**Sessions do not end politely.** The app gets closed, the limit runs out, the
process dies. Any rule of the form "write the handoff before you finish" will be
broken precisely when it matters most. So do not treat session end as the
checkpoint.

**Checkpoint at boundaries that already happen.** After each accepted
`worker_done`, after each gate decision, after each measurement, append what
changed and why. Each of those is already a turn you are taking, so the marginal
cost is a few lines — and the maximum loss from an abrupt death is one unit of
work rather than a whole session.

Never poll for remaining quota. Polling burns tokens on every check to buy
information you should not need: if checkpointing is continuous, running out of
limit costs one unit of work and there is nothing left to rescue. React to a
quota warning when the CLI surfaces one on its own; do not go asking.

## Authority

Stop when a required measurement needs hardware, credentials, a branch-policy
change, merge, deployment, arming, or field authority.

Git publication is task-scoped. Human authorization applies only to the exact
repository, staged paths, remote, source ref, and destination branch it names.
Staging, committing, and pushing are separate decisions. Generated graphify
output is not an exception.

Your final handoff must state gate status, exact commits, acceptance results,
residual risk, rollback, missing evidence, and whether any external action
occurred. Never describe a task as complete when only code exists.
