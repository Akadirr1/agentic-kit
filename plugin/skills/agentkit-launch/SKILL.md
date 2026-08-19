---
name: agentkit-launch
description: How to start a CLI agent as a worker so it reaches an input-accepting state instead of stopping on a prompt nobody answers. Use when a supervised worker fails at agent_readiness, when an agent pane looks hung, when choosing between a supervised worker and a one-shot call, or when deciding which permission and trust settings a launched agent needs.
---

# Launching an agent that actually starts

Everything here was measured against live CLIs and a live Orca runtime on
2026-08-19. Where a claim came from reading documentation instead, it says so.

## The failure this exists to prevent

A worker fails at `agent_readiness`, or its pane sits there doing nothing
visible. Four different causes produce that identical symptom:

1. **Wrong agent id.** The launch never happened.
2. **The agent is parked on a prompt.** Trust dialog, hook trust, version
   update, onboarding wizard. It is running and will never report ready.
3. **The agent is still starting.** A banner and a spinner that resolve on their
   own, given minutes.
4. **The CLI genuinely cannot be supervised.**

Only reading the pane separates them, and **only reading the whole pane**. A
modal can sit above the tail while a spinner redraws at the bottom, so a short
read shows motion and hides the question. One CLI was called hung three separate
times on that basis; the actual state was an unanswered folder-trust prompt, and
the same binary opened in seconds once a human answered it.

**A process doing something is not evidence that it is not waiting on a human.**

## The agent id is not the binary name

Orca's `--agent` takes Orca's registered id. Rejecting an unknown id looks
exactly like refusing to run that agent, which is how "Orca cannot supervise
this CLI" gets written down.

| binary | Orca agent id | launch-time `--model` |
|---|---|---|
| `claude` | `claude` | yes |
| `codex` | `codex` | yes |
| `agy` | **`antigravity`** | **no** |

`--agent agy` fails on the name alone. `--agent antigravity` is accepted and
launches the same binary. When Orca refuses `--model` for an agent, that role's
model comes from the CLI's own configuration and `roles.toml` cannot pin it —
say so rather than letting the pin look effective.

`--model` and `--effort` never combine with `--terminal`, so binding a
pre-built pane gives up launch-time model selection. Prefer the composed
`worker-start --agent <id> --model <id>` and let Orca build the terminal.

## Permission tier: answerable, not absent

Use the permissive tier that still asks when it matters, not the one that
deletes the question:

| CLI | tier |
|---|---|
| claude | `--permission-mode auto` |
| codex | `-a on-request` (add `-s read-only` for review work) |
| agy | `--mode accept-edits` |

Bypassing checks outright removes the signal you need when an agent can change
how a system behaves. When the permissive tier does stop, a pane read reports it
as a blocker rather than letting the pane hang unexplained.

## Answer trust once, on the record

Each CLI keeps its own trust store, and trust does **not** inherit from a parent
directory — a project was still prompted while its home directory was already
marked trusted.

| CLI | store |
|---|---|
| claude | `~/.claude.json` → `projects[path].hasTrustDialogAccepted` |
| codex | `~/.codex/config.toml` → `[projects."path"] trust_level` |
| agy | `~/.gemini/trustedFolders.json` → `{path: "TRUST_FOLDER"}` |

`agentkit preflight` records the current project in each store it needs.
Reporting "not trusted" and moving on leaves the actual failure in place.

Known gates beyond folder trust: codex asks separately about hook trust
whenever a hook changes, and stops on its own version-update prompt; a config
directory with no first-run state runs the onboarding wizard.

## Memory follows the coordinator, not the worker

A cross-session memory store hooks every session of its CLI, workers included.
Left alone it inverts its own purpose: a throwaway smoke-test prompt was
persisted under the project's name while the real coordinator session was filed
under the home directory's name.

Claude Code and codex both resolve plugins through `CLAUDE_CONFIG_DIR`, so a
worker launched against a plugin-free config directory runs without memory
hooks. That directory needs more than credentials: identity and first-run state
are stored per config directory, so without them the worker runs the onboarding
wizard and then asks to log in. `agentkit preflight` maintains
`~/.agentkit/worker-config` with the theme, the identity keys, the project
trusted, and the real credentials symlinked.

Some CLIs attach the same memory store by other means — one registers it as an
MCP server in the CLI's own config — so check the CLI's MCP configuration too.

## 2a or 2b: ask what the human will do

- **2a, one-shot.** A single non-interactive call: `agy --print`,
  `claude --print`, `codex exec`. No session, no handshake, no pane, no cleanup.
  Multi-step work is still available through `--input-format stream-json`.
- **2b, supervised worker.** A full agent session in its own pane, with a task,
  a dispatch, `worker_done`, and release.

The deciding question is not which CLI it is. It is **whether a human will watch
this work as it happens and steer it.** If yes, 2b — the pane is the point. If
the output is a document nobody interrupts, 2a, which skips every gate class
above because it never opens a TUI.

## Cleanup

Release a settled worker by dispatch: `worker-release --dispatch <id>`. It
preserves output first, then closes only the terminal that dispatch owns.
`terminal close` has none of those protections and takes a handle that may be
stale — handles are runtime-scoped and `--terminal` is optional on most
commands, so a stale one can resolve to the active terminal. That cost a
coordinator session once.

A `worker-start` that reports `ok: false` may still have dispatched the task and
created the pane. Before retrying, check `task-list`, `worker-list`, and
`terminal list`.

## Verify instead of arguing

```bash
agentkit preflight                 # static: ids, trust, permission flags, commands
agentkit preflight --launch        # open each role's real command and read the pane
agentkit preflight --handshake     # also probe worker-start, then clean up
```
