# skiller command reference

Based on skiller 0.2.1. Check `skiller --version`. If it differs, `skiller help <command>`
is authoritative.

Every workspace command accepts `-w, --workspace <path>`. Resolution order:
`--workspace` → `$AGENTIC_WORKSPACE` → nearest parent directory containing `.skiller/`.

| Command | Purpose | Key options |
|---|---|---|
| `init [<path>]` | Create the workspace skeleton | |
| `search <query…>` | Search all registries, deduplicate, number results | `--source all\|skills-sh\|github\|registry`, `-l/--limit` (20), `--json` |
| `index` | Show local registry index status | `--refresh` (~18 MB download, ~5 s), `--clear` |
| `add <ref\|number>` | Clone → `installs/` link → optional group → lock file | `--as <name>`, `-g/--group`, `--ref <branch\|tag\|sha>`, `--update` |
| `link <group> <name…>` | Add skills or groups to a group | `--as-group` (if a name is both a skill and a group) |
| `unlink <group> <name…>` | Remove from a group; the install stays | |
| `apply <group…>` | Flatten groups into `./.claude/skills/` (absolute links) | `-n/--dry-run`, `-c/--clean`, `--project <dir>`, `--no-gitignore` |
| `list` / `ls` | Installed skills | `--groups`, `--licenses`, `--json` |
| `info` / `show <name\|ref>` | Description, source, commit, groups, contents | `--json` |
| `remove` / `rm <name…>` | Remove the install and all of its group links | `--prune` (also delete the clone; required for `local`) |
| `sync` | Lock file → actual state; repairs links | `--update` (latest commit, rewrites the lock file) |
| `adopt [<path…>]` | Move real directories under `skills/` into `installs/`, leaving a symlink | `--as`, `--dry-run`, `--suggest` |
| `doctor` | Report inconsistencies; never changes anything | `--json` |

## Reference formats for `add` / `info`

- `owner/repo`: **all** skills in the repo
- `owner/repo/skill-id`
- `owner/repo/skill@ref`
- `https://github.com/owner/repo/tree/main/skills/x`
- `git@github.com:owner/repo.git`
- `3`: row number from the last `search`

Only github.com is supported.

## Search sources

- **registry**: local index of the community registry (~160k skills, with description and
  licence). Needs `skiller index --refresh` once, then works offline.
- **skills-sh**: skills.sh API with install counts, no description.
- **github**: code search for `filename:SKILL.md`. Needs a token (`GITHUB_TOKEN` → `GH_TOKEN`
  → `gh auth token`). Without one, this source is skipped with a warning.

Results are merged with Reciprocal Rank Fusion and capped at 3 results per repository.

## Typical error messages

- **Name collision**: `'x' is already installed from …`. Retry with `--as x@<owner>`.
- **Name is both skill and group**: `link` aborts. Use `--as-group` or choose the skill name.
- **Self-nesting** (`link ios ios`): rejected. Cycles between sibling groups are allowed;
  `apply` reports them and continues.
- **Dirty clone**: `sync` skips repos with local changes instead of resetting them.
