# MCP Landscape

Three MCP servers serve this project. They overlap in places; this doc maps
what each is for and when to reach for which.

|                              | Plugin data | Runtime state | Prompt mgmt |
| ---------------------------- | ----------- | ------------- | ----------- |
| **SkyLinkAI**                | ✓           | ✓             | ✗           |
| **SkyrimPatcherMCP**         | ✓           | ✗             | ✗           |
| **SkyrimNet MCP**            | ✗           | ✓             | ✓           |

## SkyLinkAI (localhost SKSE plugin)

Requires Skyrim running with the SkyLinkAI SKSE plugin loaded.

**Plugin data:** `search_forms` — broad `help`-style FormKey lookups across all
loaded mods. Fast but imprecise (returns strings, not structured records).

**Runtime state:** Full suite — player info, NPC detection, combat state,
inventory, quests, cell info, faction lookups on live references, appearance,
screenshots.

**Use when:** You need live FormKey or actor state data and Skyrim is already
running. The go-to for interactive sessions and runtime verification.

**Don't use:** For batch offline FormKey resolution — too slow, requires the
game, and the game must be in a safe state (not paused, not in menus).

## SkyrimPatcherMCP (offline, Mutagen-based)

Reads plugin data directly from disk through MO2's virtual filesystem.

**Plugin data:** `search_records` and `read_record` for structured record data
(NPC, race, outfit, faction, voiceType, package, headPart, colorRecord, class,
armor, weapon, etc.). Also `list_load_order`, `get_conflicts`, `diff_record`.

**Use when:** Skyrim is closed and you need reliable FormKey resolution from the
installed modlist. The best tool for offline batch lookups.

**Don't use:** For runtime state (position, health, dead/alive, combat) — it
reads records only, not live object data.

See `tools/skyrim-patcher-mcp.md` for setup and record type reference.

## SkyrimNet MCP (localhost:8889)

Requires SkyrimNet runtime. Focused on dialogue and prompt management.

**Runtime state:** Has access to SkyrimNet's internal game state — NPC
positions, loaded cells, active conversations, biotext live edits.

**Prompt mgmt:** The main draw — read/write biotext prompts, inject world
knowledge entries, manage conversation state. Used for verifying prompt files
are loaded correctly.

**Use when:** You're working with SkyrimNet's dialogue system — checking what
prompts are loaded, live-editing NPC personality, or managing world knowledge
injection.

**Don't use:** For FormKey resolution or plugin data lookups — not its job.

## Rule of Thumb

- Need a FormKey and Skyrim is **closed**? → SkyrimPatcherMCP
- Need a FormKey and Skyrim is **open**? → SkyLinkAI (search_forms)
- Need runtime state (dead/alive, position, combat)? → SkyLinkAI
- Need prompt/dialogue state? → SkyrimNet MCP
