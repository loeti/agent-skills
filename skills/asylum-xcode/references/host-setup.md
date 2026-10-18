# Host setup

Flow: agent in container → `http://host.docker.internal:8765/mcp` → `mcp-proxy` on host (`127.0.0.1`) → `xcodebuildmcp mcp` (stdio) → Xcode/Simulator.

## Once: install

```sh
brew install xcodebuildmcp   # check that `which -a xcodebuildmcp` has no older npm copy first
```

`uvx` fetches `mcp-proxy` on first use.

## Per project: config

```sh
mkdir -p .xcodebuildmcp
cat > .xcodebuildmcp/config.yaml <<'EOF'
enabledWorkflows: ["simulator", "ui-automation"]
sentryDisabled: true
EOF
echo ".xcodebuildmcp/" >> .git/info/exclude   # keep it out of the repo without touching .gitignore
```

Default without config is `["simulator"]` only. Names are `XCODEBUILDMCP_*` and `.xcodebuildmcp/` as of 2.7.0; the project was renamed MobileBuildMCP, so later versions may use `MOBILEBUILDMCP_*`.

## Per session: proxy

From the project directory, in its own terminal, only while needed:

```sh
XCODEBUILDMCP_SENTRY_DISABLED=true \
  uvx mcp-proxy --host 127.0.0.1 --port 8765 --pass-environment -- xcodebuildmcp mcp
```

Alternative where installed: `xcodebuildmcp-proxy [project-dir]` (`/Volumes/Tools/bin`) wraps the same command, checks that the port is free and warns if the config is missing. Other port: `PORT=8767 xcodebuildmcp-proxy`.

Cupertino (Apple docs, read-only): `cupertino-proxy` (same script, port 8766, any directory). Low risk, so it can keep running.

## Per project: register the MCP server

With the proxy running, from the project directory on the host, before starting Claude (a server added during a session only loads in the next one):

```sh
asylum run claude mcp add --transport http --scope local xcodebuild http://host.docker.internal:8765/mcp
asylum run claude mcp add --transport http --scope local cupertino http://host.docker.internal:8766/mcp
asylum run claude mcp list   # expect "xcodebuild/cupertino … ✓ Connected"
```

Use `--scope local`, not `.mcp.json`: it stays in the project's Claude config, out of the repo. Unverified whether it survives container removal; if `mcp list` no longer shows it after a restart, add it again.

## Security

This is a hole in the sandbox (XcodeBuildMCP; Cupertino only reads its docs index). The server runs with the user's full rights on the host.

- `manage_workflows` and debugging tools are not exposed with the config above (checked with `tools/list`, 2.7.0). But the agent can edit `.xcodebuildmcp/config.yaml` (mounted read-write; it overrides env vars), so the workflow list is not a boundary.
- If `debugging` gets enabled, `debug_lldb_command` allows `platform shell`, i.e. arbitrary host commands.
- The port has no auth. Every container and local process can reach it.

Run the proxy only for trusted projects and stop it afterwards. A real boundary would need an Asylum kit on the host broker with fixed actions.
