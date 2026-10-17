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

## Security

This is a hole in the sandbox. The server runs with the user's full rights on the host.

- The agent can edit `.xcodebuildmcp/config.yaml` (mounted read-write; it overrides env vars) and call `manage_workflows`, so the workflow list is not a boundary.
- With `debugging` enabled, `debug_lldb_command` allows `platform shell`, i.e. arbitrary host commands.
- The port has no auth. Every container and local process can reach it.

Run the proxy only for trusted projects and stop it afterwards. A real boundary would need an Asylum kit on the host broker with fixed actions.
