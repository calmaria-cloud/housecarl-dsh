# houseCARL for DeepSeek Harness (DSH)

This fork adapts [houseCARL](https://github.com/Avick3110/houseCARL) for the
[DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) agent runtime.

houseCARL is a comprehensive, data-layer MCP server for Skyrim Special Edition load
orders (Mod Organizer 2), built on [Mutagen](https://github.com/Mutagen-Modding/Mutagen).
Upstream ships for Claude Code / Codex; this fork:

- retargets the four projects from net9.0 to net10.0 (DSH ships .NET 10 / LTS);
- keeps the server unchanged - it is already a **stdio MCP server** by default;
- adds the DSH mount recipe + this build script.

Everything else (the housecarl_* tool surface, reflection-driven full coverage,
non-destructive writes) is upstream and unchanged.

## Requirements

- Windows
- .NET 10 SDK
- Mod Organizer 2 (Skyrim SE / AE / GOG). The server reads MO2 statically - MO2 need
  not be running.

## Build

~~~powershell
.\dsh\install.ps1
~~~

This regenerates generated/corpus.json, publishes the server to dsh/server/
(framework-dependent, trimming OFF - required for the reflection-driven schema), copies
corpus.json beside the exe, and prints the DSH mount snippet.

## Mount in DSH

DSH has a built-in MCP client bridge (@deepseek-ai/dsh-mcp-client, stdio transport).
Add one entry to ~/.dsh/profiles/<profile>/cordis.patch.yml:

~~~yaml
- insert:
    - id: housecarl
      name: '@deepseek-ai/dsh-mcp-client'
      config:
        serverName: housecarl
        transport: stdio
        command: <repo>\dsh\server\housecarl-mcp.exe
        env:
          HouseCarl__Mo2InstanceDir: 'E:\Game\mo2'
~~~

Reload the DSH session; the tools appear as mcp__housecarl__<tool> (for example
mcp__housecarl__read_record, mcp__housecarl__set_mo2_instance).

HouseCarl__Mo2InstanceDir pre-seeds the MO2 instance (the housecarl_set_mo2_instance
tool writes the same value at runtime and wins if changed). corpus.json is loaded from
beside the exe by default.

## Notes

- Upstream's houseCARL-Setup.exe (Claude/Codex desktop wiring) is not needed for DSH -
  the server runs standalone over stdio.
- Writes are non-destructive by default: every patch is a new MO2 mod folder.
- See the root README.md for the full capability list.
