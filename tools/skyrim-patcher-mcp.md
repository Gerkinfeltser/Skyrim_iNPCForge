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

## Useful Read-Only Tools

- `list_profiles` — confirm the MO2 root/profile selection
- `list_load_order` — inspect active plugins
- `search_records` — resolve supported FormKeys by EditorID/name
- `read_record` — inspect the winning record or a specific plugin's override
- `get_conflicts` / `diff_record` — inspect override chains
- `audit_load_order` — check load-order health

## Confirmed Useful Record Types

- `race`
- `outfit`
- `faction`
- `npc` (useful for clone/source appearance lookup)

## Not A Replacement For xEdit Dumps

Current SkyrimPatcherMCP generic lookup does not cover every iNPCForge table.
Keep using xEdit dump scripts for:

- `VTYP` voices
- `PACK` AI packages
- `HDPT` headparts
- `CLFM` colors
- `CELL` locations
- `CLAS` classes

## Provenance

When a generated NPC uses a FormKey resolved through this MCP, write:

```yaml
source: skyrim-patcher-mcp
evidence: "search_records faction BanditFaction in <profile> profile"
```
