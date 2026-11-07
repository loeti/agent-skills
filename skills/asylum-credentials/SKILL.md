---
name: asylum-credentials
description: Git and GitHub access inside an Asylum container through a customer- or project-scoped PAT passed in as GH_TOKEN by `lw` (loeti-way). Use when running in Asylum (ASYLUM_AGENT is set) and a task needs git push/pull, gh, or the GitHub API, when git or gh fails with an auth or GPG signing error there, or when setting up `lw`, `.envrc` or `env-from-host` for Asylum.
---

# Credentials in Asylum

The container gets exactly one GitHub token: `GH_TOKEN`, a fine-grained PAT scoped to this customer's or project's repos. Other secrets arrive under their real names from `env:` in `.loeti-way.yaml`. All are set when the container is created and never stored in a file. There is no pass-cli and no Proton token here, by design.

## Setup (once per container)

```sh
[ -n "$GH_TOKEN" ] || echo "GH_TOKEN missing"
gh auth status                 # must show "(GH_TOKEN)"
gh auth setup-git              # git uses gh as credential helper (writes no token)
git config --global url."https://github.com/".insteadOf "git@github.com:"
```

The rewrite sends SSH remotes over HTTPS, because the container's SSH key has no push access on GitHub (it's only a signing key). Don't change the remotes themselves.

## Commit signing

Commits are signed with the container's own SSH key, set via `GIT_CONFIG_*` in the environment (`git config --get gpg.format` → `ssh`). Don't disable signing or change signing config. If a commit fails with `No secret key` (GPG) or `gpg.format` is not `ssh`, the setup is missing: stop and tell the user (see host setup). Never touch `.git/config`, it is shared with the host.

## If GH_TOKEN is missing or rejected

Don't work around it. Tell the user:

> Run `lw status` in the project directory on the Mac and fix what it reports (`lw apply <customer>` after a `.loeti-way.yaml` change, `lw github <customer>` or `lw init --project <path>` for a missing PAT). Then `direnv reload`, end all Asylum sessions of the customer and start again: the token is fixed when the container is created.

A project directory never falls back to the customer PAT. A missing `env:` value has the same causes.

A 403/404 on another repo means the PAT doesn't cover it. That is intended, so report it and don't look for other credentials.

## Rules

- Never print, echo, log or write `GH_TOKEN` to a file. Don't use `gh auth login`, `gh auth token`, or tokens in remote URLs.
- Don't search the container for other credentials (`~/.config/gh`, `~/.ssh`, env dumps).
- Don't install or look for pass-cli or a Proton token in the container.
- Don't edit `.loeti-way.yaml`: any change blocks all tokens until the user runs `lw apply` again.
- Bitbucket: not configured yet. Report that instead of improvising.

Host setup (`lw`, `.envrc`, Asylum config): [references/host-setup.md](references/host-setup.md)
