---
name: skiller
description: Manages agent skills with the `skiller` CLI. It searches registries (skills.sh, GitHub, community registry), installs skills into the agentic workspace, organises them into nested groups, and applies groups to a project's .claude/skills/. Use when the user wants to find, install, update, group, remove or inspect agent skills, set up skills for a project, or mentions skiller, the agentic workspace, or $AGENTIC_WORKSPACE.
---

# skiller

`skiller` finds agent skills, clones them into a central workspace and makes them
groupable through symlinks. Projects receive skills via `skiller apply <group>`.
Never copy skill directories by hand.

The workspace is `$AGENTIC_WORKSPACE` (normally `/Volumes/Tools/agentic-workspace`).
Override it with `--workspace <path>` if needed.

## Workspace model

```
$AGENTIC_WORKSPACE/
├── .skiller/{config,lock,last-search}.json
├── downloads/github.com/<owner>/<repo>/   git clones (tool-owned cache)
├── installs/<name>                        flat list of all skills
└── skills/<group>/[<subgroup>/]<name>     the user's groups, symlinks only
```

- **downloads/** belongs to the tool. Never edit it: `sync --update` runs `git reset --hard`.
- **installs/** is flat. A name can exist only once (use `--as <name>@<owner>` on collisions).
  An entry links into a clone (origin `git`) or is a real directory (origin `local`, created by `adopt`).
- **skills/** belongs to the user. Groups can be nested, and one skill can be in many groups.

## Common tasks

**Find and install a skill**

```sh
skiller search <query>                 # numbered results with licence
skiller info <owner/repo/skill-id>     # preview before installing
skiller add <number|ref> --group <group>
```

Show the search results to the user and let them choose. Do not pick one yourself.
Mention any `⚠ licence?` marker, since it matters for customer projects.

**Organise groups**

```sh
skiller link <group> <skill…>          # add a skill to another group
skiller link ios swift swiftui         # add groups as subgroups
skiller unlink <group> <skill…>        # removes the group link only
skiller list --groups
```

**Set up skills for a project** (run inside the project directory)

```sh
skiller apply <group…> --dry-run       # always first, show the result
skiller apply <group…>                 # links flat into .claude/skills/
```

`--clean` removes existing symlinks in `.claude/skills/` first. It never removes real
directories. `apply` adds `.claude/` to `.gitignore` unless `--no-gitignore` is passed.

**Keep the workspace healthy**

```sh
skiller doctor                         # read-only check
skiller sync                           # restore the locked state
skiller sync --update                  # move all skills to the latest commit
```

## Rules

- Run `--dry-run` before `apply` and `adopt`, and get the user's confirmation before the real run.
- Get the user's confirmation before `remove`, `remove --prune` and `sync --update`.
  `remove --prune` deletes `local` skills for good, because `installs/` holds their only copy.
- Use `doctor` to diagnose problems. Repairs happen through `sync`, never through manual
  symlink surgery in the workspace.
- `add` only accepts github.com references. Other hosts (e.g. Codeberg) fail with
  `unsupportedHost`. Bring such skills into the workspace by cloning or copying them into
  `skills/<group>/` and then running `skiller adopt`.
- `owner/repo` without a skill ID installs **all** skills in the repo. Ask the user first
  if they only want one.
- To work on skiller itself, use a throwaway workspace (`skiller init /tmp/ws`, `--workspace /tmp/ws`).

See [references/commands.md](references/commands.md) for all commands, options and
reference formats.
