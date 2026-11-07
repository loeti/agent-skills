# Host setup

Flow: Proton Pass → `lw env` via direnv on the Mac (`LW_ENV_<NAME>`) → `env-from-host` → container env. Command reference: https://github.com/loeti/loeti-way#readme

No pass-cli and no Proton token in the container. Each customer has a Proton agent `agent-<customer>` that reads everything, only on the Mac: provider tokens as note `GitHub Token` in vault `agent-<customer>` (project with `vault: own`: `agent-<customer>-<folder>`) and the `env:` values. Vault `lw-tokens` holds only the Proton agents' own tokens; host agent `lw-host` (Viewer, token in `~/.config/loeti-way/host-token`) reads them so a customer agent can log in.

## Once per Mac / per customer

```sh
lw host --setup        # once: create host agent, store its token, log in
pass-cli vault create --name agent-<customer>
lw init --github-owner <org>   # in the customer directory: .loeti-way.yaml, .envrc
lw apply <customer>    # confirm customer and projects, create agent and grants
lw token github        # in the directory: open PAT form, check and store the token
direnv allow           # in the customer or project directory
lw status              # what's missing; --konto also checks grants
```

Own PAT for a project: `lw init --project` in its directory, add `agent-<customer>-<folder>` to `proton.vaults` of the customer, `pass-cli vault create --name agent-<customer>-<folder>`, `lw apply`, `lw token github`, `direnv allow`.

`.envrc` in customer and project directories, as written by `lw init`:

```sh
if has lw; then eval "$(lw env)"; else log_error "lw fehlt"; fi
```

- Replace any old `.envrc` that calls pass-cli itself.
- `LW_ENV_GH_TOKEN`: the project's PAT in a project directory with its own token, else the customer's. A broken or unregistered project gets nothing, no fallback to the customer.
- `LW_ENV_<NAME>` per entry under `env:` of customer and project. On the Mac a variable never carries its real name (`GH_TOKEN` would override the host's own `gh` login).
- Unreadable values are unset and reported on stderr; exit status is always 0. Check with `lw status`.
- Tokens only for customers and projects confirmed by `lw apply` in `~/.config/loeti-way/customers.yaml`. Any change to `.loeti-way.yaml` or `.loeti-way-project.yaml` (agent, vaults, tokens, env) blocks them until `lw apply` again, because the container can write those files.
- Old config key `github:` is refused: move it under `tokens:`. Old PAT notes in `lw-tokens` are no longer read; store them again with `lw token github`.
- PAT: let `lw token github` open the form, don't create it beforehand. Fine-grained, only the needed repos, minimal permissions ("Contents" and "Pull requests": read and write), with an expiry date.

GitHub remotes are HTTPS (`https://github.com/<owner>/<repo>.git`), in the container and on the Mac, because `.git/config` is shared. On the Mac run `gh auth setup-git` once, so git uses the host's own `gh` login.

The direnv hook must be at the end of `~/.zshrc`, otherwise `.envrc` never loads on `cd`: `eval "$(direnv hook zsh)"`. Check with `[ -n "$LW_ENV_GH_TOKEN" ] && echo set || echo EMPTY`; `direnv exec .` doesn't prove the hook works.

## After `lw renew` or `lw token`

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
  GH_TOKEN: LW_ENV_GH_TOKEN
  MAVEN_PASSWORD: LW_ENV_MAVEN_PASSWORD   # one line per name under env:
```

- Remove `PROTON_PASS_PERSONAL_ACCESS_TOKEN: ASYLUM_PROTON_PASS_PAT` or similar if present. Change an old `GH_TOKEN: ASYLUM_GH_TOKEN` to `LW_ENV_GH_TOKEN`.
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

The key is shared by all projects (`isolation: isolated`), so it can't serve as a push deploy key: GitHub allows a deploy key in one repo only. Pushes go over HTTPS remotes with the PAT (see SKILL.md).

## Limits

- Docker keeps the container env in its metadata (`docker inspect`) until the container is removed. Asylum removes it after the last session.
- All repos using the customer PAT get the same token in their containers. Repos that must not reach each other need a project PAT.
