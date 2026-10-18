---
name: asylum-xcode
description: Build, test and drive iOS apps in the Simulator from an Asylum container through XcodeBuildMCP running on the macOS host. Use when running in Asylum (ASYLUM_AGENT is set) and a task needs xcodebuild, the iOS Simulator, screenshots or UI taps, when it needs Apple API documentation, HIG or sample code (Cupertino MCP), or when the xcodebuild or cupertino MCP server is missing or unreachable.
---

# Xcode from Asylum

Xcode and the Simulator exist only on the macOS host. The container reaches them through the `xcodebuild` MCP server (XcodeBuildMCP behind a proxy on `host.docker.internal:8765`). The project has the same path on host and container, so pass absolute paths unchanged.

For Apple docs, HIG, sample code and Swift Evolution use the `cupertino` MCP server (proxy on `host.docker.internal:8766`, read-only) instead of guessing APIs from memory.

## Check

```sh
curl -s -o /dev/null -w '%{http_code}\n' http://host.docker.internal:8765/mcp   # 000 = proxy not running
claude mcp list | grep xcodebuild || \
  claude mcp add --transport http --scope local xcodebuild http://host.docker.internal:8765/mcp
claude mcp list | grep cupertino || \
  claude mcp add --transport http --scope local cupertino http://host.docker.internal:8766/mcp
```

A server added here only loads in the next session: tell the user to restart Claude.

If the proxy is not running, stop and tell the user:

> Start the XcodeBuildMCP proxy on the host in the project directory (`xcodebuildmcp-proxy`, or `cupertino-proxy` for docs; see the asylum-xcode host setup).

## Rules

- Don't install Xcode, simctl, idb or XcodeBuildMCP in the container, and don't call `xcodebuild`/`xcrun` there.
- Set session defaults (workspace, scheme, simulator) once, then reuse them. Prefer `build_run_sim` for "build and run".
- Don't edit `.xcodebuildmcp/config.yaml`. If a needed tool is missing, ask the user to enable its workflow.
- Signing for devices is not available. Use the Simulator.

Host setup (config, proxy, security): [references/host-setup.md](references/host-setup.md)
