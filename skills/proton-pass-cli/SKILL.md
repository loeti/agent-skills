---
name: proton-pass-cli
description: Retrieves credentials and secrets from Proton Pass with `pass-cli` as an agent (PAT login, pass:// references, run/inject, item view). Use when a task needs a password, token, API key or other secret, when the user mentions Proton Pass, pass-cli or pass:// URIs, or when a command fails for missing credentials.
---

# Proton Pass CLI for agents

Goal: use secrets without them entering the conversation. Docs: https://protonpass.github.io/pass-cli/

## Session

```sh
export PROTON_PASS_SESSION_DIR="/tmp/pass-agent-<project>"   # isolated from the user's session
pass-cli info || pass-cli login                               # PAT comes from the environment
```

- `login` reads `PROTON_PASS_PERSONAL_ACCESS_TOKEN` from the environment. If it is unset, ask the user to set it (e.g. via direnv). Never ask for the PAT in chat.
- Never write the PAT into commands, files, commits or memory. Don't use `--pat`.
- On auth errors: `pass-cli logout --force`, log in again, retry once. If that fails, report the error.

## Using secrets (in this order)

1. **`run`**: references in env vars, resolved only for the child process, masked in output:
   ```sh
   DB_PASSWORD='pass://Vault/Item/password' pass-cli run -- ./cmd
   pass-cli run --env-file .env -- ./cmd       # .env holds pass:// references, not values
   ```
2. **`inject`**: config files from a template with `{{ pass://Vault/Item/field }}`:
   ```sh
   pass-cli inject -i config.tpl.yaml -o config.yaml   # file mode 0600
   ```
   Make sure the output file is gitignored.
3. **`item view`**: only if the value itself is needed. Read single fields, never whole items:
   ```sh
   PROTON_PASS_AGENT_REASON="<why>" pass-cli item view "pass://Vault/Item/field"
   ```
   Don't repeat the value in replies. Pipe it straight into the consuming command.

Reference format: `pass://<vault name|share ID>/<item title|ID>/<field>`. Fields: `username`, `password`, `email`, `url`, `note`, `totp`, custom names, `Section.field`. Use IDs when names are ambiguous.

## Discovery

```sh
pass-cli vault list --output json
pass-cli item list --vault-name "<vault>" --output json
```

Lists can be long. Filter with `jq` for the titles you need instead of reading full output.

## Rules

- `PROTON_PASS_AGENT_REASON` is required for `item view|create|update|trash|untrash` and `vault update`. Give a concrete reason, it is audited.
- Ask the user before any write (`create`, `update`, `trash`, `delete`, `move`, `share`).
- Don't try to work around a denied vault or item. Tell the user which access is missing.
