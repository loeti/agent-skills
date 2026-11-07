# Host setup

Flow: Proton Pass → `lw env` via direnv on the Mac (`ASYLUM_GH_TOKEN`, `LW_ENV_<NAME>`) → `env-from-host` → container env. Command reference: https://github.com/loeti/loeti-way#readme

No pass-cli and no Proton token in the container. PATs are notes in vault `lw-tokens`, readable only by host agent `lw-host` (Viewer, token in `~/.config/loeti-way/host-token`). Each customer has an agent `asylum-<customer>` that reads the `env:` values from the customer's `agent-…` vaults, only on the Mac.

## Once per Mac / per customer

```sh
lw host --setup        # create host agent, store its token, log in
lw apply <customer>    # confirm customer, create agent and grants
lw github <customer>   # store GitHub PAT (per project: lw init --project <path>)
direnv allow           # in the customer or project directory
lw status              # what's missing; --konto also checks grants
```

`.envrc` in customer and project directories, as written by `lw init`:

```sh
if has lw; then eval "$(lw env)"; else log_error "lw fehlt"; fi
```

- Replace any old `.envrc` that calls pass-cli itself.
- `ASYLUM_GH_TOKEN`: the project's PAT in a project directory, else the customer's. No fallback: a project without its own PAT gets none.
- `LW_ENV_<NAME>` per entry under `env:` in `.loeti-way.yaml`. On the Mac a variable never carries its real name (`GH_TOKEN` would override the host's own `gh` login).
- Unreadable values are unset and reported on stderr; exit status is always 0. Check with `lw status`.
- Tokens only for customers confirmed by `lw apply` in `~/.config/loeti-way/customers.yaml`. Any change to `.loeti-way.yaml` (agent, notes, vaults, env) blocks tokens until `lw apply` again, because the container can write that file.
- PAT: fine-grained, only the needed repos, minimal permissions ("Contents" and "Pull requests": read and write), with an expiry date.

The direnv hook must be at the end of `~/.zshrc`, otherwise `.envrc` never loads on `cd`: `eval "$(direnv hook zsh)"`. Check with `[ -n "$ASYLUM_GH_TOKEN" ] && echo set || echo EMPTY`; `direnv exec .` doesn't prove the hook works.

## After `lw renew` or `lw github`

`direnv reload` in open shells, then end all Asylum sessions of the customer and start again. The token is fixed when the container is created.

## Once: `~/.asylum/config.yaml`

Needs the Asylum development build (`main`) until the next release. Applies to all customers:

```yaml
agents:
  claude:
    config: project             # not shared: that mounts ~/.claude with all projects' transcripts
    seed: settings              # settings, skills, login; no transcripts
kits:
  github:
    credentials: false          # auto copies the host's full gh token into every project
env-from-host:                  # container name: host name; unset is skipped
  GH_TOKEN: ASYLUM_GH_TOKEN
  MAVEN_PASSWORD: LW_ENV_MAVEN_PASSWORD   # one line per name under env:
```

- Remove `PROTON_PASS_PERSONAL_ACCESS_TOKEN: ASYLUM_PROTON_PASS_PAT` or similar if present.
- `env-from-host` and `seed` are ignored in `.asylum`. Don't put tokens in `env:` in `.asylum`/`.asylum.local` or in `.env`: they are files, and `${VAR}` is not expanded.
- `seed: settings` copies only `~/.claude`'s files: settings not in its `settings.json` (e.g. a statusline), user MCP servers (`~/.claude.json`) and plugins must be set up again per project.

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
- All repos using the customer PAT get the same token in their containers. Repos that must not reach each other need a project PAT.
