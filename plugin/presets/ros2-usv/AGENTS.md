# USV Workspace — shared agent instructions

ROS 2 Humble. Jetson Xavier + Raspberry Pi. 2026 İDA competition.

Every agent working in this repository loads this file. It holds only what is
true for all of them; role-specific doctrine lives in `agents/<role>.md`, and
launch configuration lives in `agents/roles.toml`.

## Where truth lives

| Source | Path | Holds |
|---|---|---|
| Obsidian vault | `usv-obsidian/USV/` | decisions, rationale, field findings |
| Code graph | `graphify-out/graph.json` | both repos, merged. First stop for structure questions |
| Pi code | `raspi_nav2` @ `marine-hardening` | all field work |
| Xavier code | `xavier_usv` @ `new` | perception |

Start here: `usv-obsidian/USV/00 🧭 YENİ OTURUM BRİFİNGİ.md`.

## Invariant boundaries

Decided. Do not reopen.

1. **`marine-hardening` will not be merged into `new`.** Separate branches.
   `new` has been frozen since 24 July.
2. **Xavier is fragile — solve it on the Pi first.** Touching Xavier code or its
   build is the last resort.
3. **`usv_tuner` is abandoned.** Do not build plans on it.
4. **`usv_logrouter` lives on its own `logrouter` branch.** It broke the field
   branch's build.
5. **Foxglove is a test tool only.** `enable_foxglove:=false` in competition.
6. **`zed_msgs` will not be installed on the Pi.**
7. **graphify runs without a model.** `graphify update .` is AST-only; Do not run document
   extraction; the vault is better organised already.

## The recurring failure

One session hit the same thing five times:

> Node shows `active [3]` · most of its inputs are flowing · **output is zero** ·
> **log is completely empty.**

Seen in `detection_world_node`, `usv_logrouter`, `station_keeping_node`, and
`foxglove_bridge`.

**Rule: every fix must add a check that shouts about silence.** Any path that
returns early must emit at least a throttled warning.

## Measurement discipline

- Do not write a conclusion you have not measured. If it is inference, label it
  "inference".
- For structure questions run `graphify query` before grep. The coordinator
  normally supplies the scoped subgraph; do not rebuild it yourself.
- Read `std dev` and `max` from `ros2 topic delay`, not the mean. One fix here
  raised the mean and cut deviation twentyfold; watching the mean would have
  reverted a correct fix.
- Log line frequency is not event frequency. Check `throttle_duration_sec` in
  code before interpreting a warning's rate. This inference has been wrong twice.
- The absence of a warning is not evidence of health. Early `return` paths and
  `x is None` guards log nothing.
- A git ref you did not just fetch is not evidence. `git fetch` before any
  branch claim.

## Practical traps

```bash
ssh-add --apple-load-keychain     # SSH agent empties each session
export ROS_DOMAIN_ID=42           # launch-scoped only; separate terminals need it
python3 graphify-out/relabel.py   # labels are lost after a graphify rebuild
```

Validate vault wikilinks with the scanner in the onboarding note, never with
grep — two grep patterns have already given wrong results here.

## Authority

Stop and ask when the next step needs hardware, credentials, a branch-policy
change, merge, deployment, arming, or field authority. Staging, committing, and
pushing are separate decisions, each scoped to the exact repository, paths,
remote, and branch a human named.
