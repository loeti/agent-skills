# Host setup

Flow: Proton Pass → direnv (`ASYLUM_GH_TOKEN`) → `asylum -e GH_TOKEN=…` → container env.

## Per project: `.envrc`

```sh
# Inside the container pass-cli is missing; GH_TOKEN comes from asylum -e there.
if has pass-cli; then
  export ASYLUM_GH_TOKEN="$(pass-cli item view "pass://<Vault>/<Item>/note")"
fi
```

- Then run `direnv allow`. The field for a secure note is `note`.
- Keep `.envrc` gitignored or free of values. It only contains the reference.
- Use the name `ASYLUM_GH_TOKEN`, not `GH_TOKEN`/`GITHUB_TOKEN`. Those would override the host's own `gh` login in this directory.
- PAT: fine-grained, only this project's repos, minimal permissions, with an expiry date.

### One PAT for several repos

direnv uses the nearest `.envrc` up the tree. Put it in the common parent directory:

```
customer/
├── .envrc        ← ASYLUM_GH_TOKEN for all repos below
├── repo-a/       ← inherits it (as long as it has no .envrc of its own)
└── repo-b/
```

A repo that needs its own variables loads the parent's first:

```sh
# repo-a/.envrc
source_up                  # or source_up_if_exists
export FOO=bar
```

- Each `.envrc` needs `direnv allow` once.
- Each repo directory gets its own container, but all of them get the same token. Repos that must not reach each other need separate PATs.

## Once: `~/.zshrc`

The direnv hook must be present, otherwise `.envrc` never loads on `cd` and `asylum` starts without the token. Put it at the end:

```sh
eval "$(direnv hook zsh)"
```

Check with `[ -n "$ASYLUM_GH_TOKEN" ] && echo set || echo EMPTY` in the project directory. `direnv exec .` loads the file without the hook, so it doesn't prove the hook works.

The function also creates the project's Claude config dir up front. Otherwise Asylum seeds it by copying all of `~/.claude` (see below). The name formula comes from Asylum's `ContainerName`. `ASYLUM_PASS_ENV` lists further direnv variables to pass through under the same name.

```sh
asylum() {
  local base="${${PWD:t:l}//[^a-z0-9-]/-}"
  base="${${base[1,56]##-#}%%-#}"
  local cname="asylum-$(printf %s "$PWD" | shasum -a 256 | cut -c1-12)-${base:-project}"
  mkdir -p "$HOME/.asylum/projects/$cname/claude-config"

  local -a envargs
  [[ -n "$ASYLUM_GH_TOKEN" ]] && envargs+=(-e GH_TOKEN="$ASYLUM_GH_TOKEN")
  local v; for v in ${=ASYLUM_PASS_ENV}; do envargs+=(-e "$v=${(P)v}"); done
  command ${ASYLUM_BIN:-asylum} "${envargs[@]}" "$@"
}
asylum-dev() { ASYLUM_BIN=/path/to/asylum/build/asylum-darwin-arm64 asylum "$@"; }
```

Every other way to start Asylum (an alias to a dev build, an IDE terminal without direnv) skips the function: no token, and a missing config dir gets the full `~/.claude`. Shells opened before switching from an alias to a function still have the alias; `unalias` it or open a new shell.

## Once: `~/.asylum/config.yaml`

- `agents.claude.config: project`. `shared` mounts the host's `~/.claude`, so the agent sees the transcripts and memories of all projects. `project` and `isolated` seed a missing config dir by copying all of `~/.claude`, which is why the shell function creates the dir first. The cost: you log in to Claude once per project.
- The `github` kit without `credentials: auto`. That option writes the host's full `gh` token to `~/.asylum/projects/<container>/credentials/gh/hosts.yml` for every project.

Don't put tokens in `env:` in `.asylum`/`.asylum.local` or in `.env`. All three are files, and `${VAR}` is not expanded.

## Signing the agent's commits

The copied `~/.gitconfig` signs with the host's GPG key, which isn't in the container (`No secret key`). Sign with the container's own SSH key (`~/.asylum/ssh/id_ed25519`, mounted at `~/.ssh/`) instead. `GIT_CONFIG_*` overrides every config file and only exists in the container:

```yaml
# ~/.asylum/config.yaml
env:
  GIT_CONFIG_COUNT: "2"
  GIT_CONFIG_KEY_0: gpg.format
  GIT_CONFIG_VALUE_0: ssh
  GIT_CONFIG_KEY_1: user.signingkey
  GIT_CONFIG_VALUE_1: /Users/<you>/.ssh/id_ed25519.pub   # container HOME = host HOME
```

- Add `~/.asylum/ssh/id_ed25519.pub` on GitHub as a **Signing Key** (grants no repo access). Without it, commits are signed but not "Verified".
- Not `kits.shell.entrypoint`: Asylum's generated config documents it, but it is silently ignored.
- Forwarding the host's gpg-agent doesn't work: Docker Desktop on macOS can't mount host Unix sockets.
- Applies to new containers only; end all sessions first.

The key is shared by all projects (`isolation: isolated`), so it can't serve as a push deploy key: GitHub allows a deploy key in one repo only. Pushes go over HTTPS with the PAT (see SKILL.md).

## Limits

- Docker keeps the container env in its metadata (`docker inspect`) until the container is removed. Asylum removes it after the last session.
- The token is fixed at creation. After rotating it, end all sessions or use `asylum --rebuild`.
- In v0.8.1, `asylum --debug` and the process list (`ps`) show `-e` values, including the token, while a session runs.

## After the merged PRs

On Asylum `main`, not yet in a stable release (v0.8.1). Then the shell function goes away:

```yaml
# ~/.asylum/config.yaml
agents:
  claude:
    config: project
    seed: settings              # #44: settings, skills, login; no transcripts
env-from-host:                  # #42: container name: host name; unset is skipped
  GH_TOKEN: ASYLUM_GH_TOKEN
```

- Per-project secrets: `env-from-host` in `.asylum.local`. Both keys are ignored in `.asylum`.
- #45: values go to `docker run` via an env file, so they leave `ps` and `--debug`. `docker inspect` still shows them.
- `seed: settings` copies only `~/.claude`'s files: settings not in its `settings.json` (e.g. a statusline), user MCP servers (`~/.claude.json`) and plugins must be set up again per project.
