# SkyrimPatcherMCP Notes

SkyrimPatcherMCP is an optional offline MCP resolver for Mod Organizer 2 load
orders. Use it when Skyrim is closed or unavailable and the target record type is
supported by the MCP server.

## Setup

Clone/build externally, not inside this repo:

```powershell
git clone https://github.com/ViceReversa/SkyrimPatcherMCP.git D:\git\SkyrimPatcherMCP
Set-Location -LiteralPath D:\git\SkyrimPatcherMCP
dotnet build -c Release
```

Set `MO2_ROOT` to the Mod Organizer root that contains `ModOrganizer.ini`:

```powershell
$env:MO2_ROOT = "D:\Modlists\ADT"
```

The local ADT path above is an example only. Do not hardcode it in generated
NPC output or repo templates.

## Fork With Extended Record Types

The upstream has limited `search_records` support. The fork branch
[`Gerkinfeltser/SkyrimPatcherMCP@feat-record-search-types`](https://github.com/Gerkinfeltser/SkyrimPatcherMCP/tree/feat-record-search-types)
adds `voiceType`, `package`, `headPart`, `colorRecord`, and `class` support
while [upstream PR #1](https://github.com/ViceReversa/SkyrimPatcherMCP/pull/1)
is open.

```powershell
git clone -b feat-record-search-types https://github.com/Gerkinfeltser/SkyrimPatcherMCP.git D:\git\SkyrimPatcherMCP
```

Build and configure the same way as upstream. The read-only tools below exist
in both versions; the extended record types require the fork branch until the PR
is merged upstream.

## Useful Read-Only Tools

- `list_profiles` — confirm the MO2 root/profile selection
- `list_load_order` — inspect active plugins
- `search_records` — resolve supported FormKeys by EditorID/name
- `read_record` — inspect the winning record or a specific plugin's override
- `get_conflicts` / `diff_record` — inspect override chains
- `audit_load_order` — check load-order health

## Confirmed Useful Record Types

These are useful for iNPCForge lookups and are supported by upstream
SkyrimPatcherMCP:

- `race`
- `outfit`
- `faction`
- `armor`
- `weapon`
- `miscItem`
- `ammunition`
- `npc` (useful for clone/source appearance lookup)

The fork branch also supports:

- `voiceType`
- `package`
- `headPart`
- `colorRecord`
- `class`

## Not A Replacement For xEdit Dumps

xEdit dumps are still required for:

- `CELL` locations (not a generically searchable record type)

## Provenance

When a generated NPC uses a FormKey resolved through this MCP, write:

```yaml
source: skyrim-patcher-mcp
evidence: "search_records faction BanditFaction in <profile> profile"
```
