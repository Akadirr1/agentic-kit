# {{PROJECT}} — shared agent instructions

<!-- Every agent working in this repository loads this file. Keep only what is
     true for all of them. Role doctrine lives in agents/<role>.md, coordination
     machinery in agents/core.md, launch config in agents/roles.toml. -->

One paragraph: what this project is, what it runs on, what it is for.

## Where truth lives

| Source | Path | Holds |
|---|---|---|
| | | decisions and rationale |
| | | code structure |
| | | the code itself |

Start here: <the one document a new session must read first>

## Invariant boundaries

<!-- Decisions already made. Listing them here stops every new session from
     reopening them. Delete this section only if the project genuinely has none. -->

1.
2.

## Known failure pattern

<!-- The failure this project keeps hitting, written concretely enough to be
     recognised. If you cannot name one yet, delete the section and add it the
     first time something bites twice. -->

**Rule that follows from it:**

## Measurement discipline

- Do not write a conclusion you have not measured. If it is inference, label it
  "inference".
- Absence of an error signal is not evidence of health.
- State you did not just re-read is not evidence.
- <project-specific: which metric lies, which tool misleads, which reading has
  already been wrong>

## Practical traps

```bash
# commands that must be run, environment that must be set, things that reset
```

## Authority

Stop and ask when the next step needs credentials, a policy change, deployment,
or anything irreversible. Staging, committing, and pushing are separate
decisions, each scoped to exactly what a human named.
