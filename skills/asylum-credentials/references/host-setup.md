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

The function also creates the project's Claude config dir up front. Otherwise Asylum seeds it by copying all of `~/.claude` (see below). The name formula comes from Asylum's `ContainerName`.

```sh
asylum() {
  local base="${${PWD:t:l}//[^a-z0-9-]/-}"
  base="${${base[1,56]##-#}%%-#}"
  local cname="asylum-$(printf %s "$PWD" | shasum -a 256 | cut -c1-12)-${base:-project}"
  mkdir -p "$HOME/.asylum/projects/$cname/claude-config"

  if [[ -n "$ASYLUM_GH_TOKEN" ]]; then
    command asylum -e GH_TOKEN="$ASYLUM_GH_TOKEN" "$@"
  else
    command asylum "$@"
  fi
}
```

## Once: `~/.asylum/config.yaml`

- `agents.claude.config: project`. `shared` mounts the host's `~/.claude`, so the agent sees the transcripts and memories of all projects. `project` and `isolated` seed a missing config dir by copying all of `~/.claude`, which is why the shell function creates the dir first. The cost: you log in to Claude once per project.
- The `github` kit without `credentials: auto`. That option writes the host's full `gh` token to `~/.asylum/projects/<container>/credentials/gh/hosts.yml` for every project.

Don't put tokens in `env:` in `.asylum`/`.asylum.local` or in `.env`. All three are files, and `${VAR}` is not expanded.

## Limits

- Docker keeps the container env in its metadata (`docker inspect`) until the container is removed. Asylum removes it after the last session.
- The token is fixed at creation. After rotating it, end all sessions or use `asylum --rebuild`.
- `asylum --debug` prints the run arguments, including the token.
