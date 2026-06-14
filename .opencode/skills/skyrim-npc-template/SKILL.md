---
name: skyrim-npc-template
description: Generate a complete, self-contained ESL-flagged Skyrim NPC plugin with SkyrimNet AI dialogue from a single config file — record layer via Spriggit, personality layer via prompt file
version: 2.0.0
created: 2026-06-13
author: PhospheneOverdrive
---

# Skyrim NPC Template — Agent Recipe

Generate fully functional, self-contained Skyrim SE NPC plugins with SkyrimNet AI dialogue support. Config-driven: one YAML config → two outputs (Spriggit `.esp` + SkyrimNet `.prompt` file).

## When To Use

Use this skill when asked to:
- "Make me an NPC named X"
- "Create a custom NPC"
- "Add a new character to Skyrim"
- "Generate a bandit/guard/merchant/follower"
- Any request to create a new Skyrim NPC

## Prerequisites

- **Spriggit** 0.40.0 installed (`dotnet tool install --global Spriggit.Yaml.Skyrim`)
- `$env:SKYRIM_DATA` set to your Skyrim SE Data folder (see `AGENTS.md` → Commands)

## Pipeline Overview

```
npc.config.yaml (single source of truth)
         │
    ┌────┴────┐
    ▼         ▼
 Layer 1    Layer 2
 Spriggit   Prompt
 YAML→.esp  file
    │         │
    ▼         ▼
 Grok.esp   grok_801.prompt
(ESL)       (in characters/)
```

## Output Structure (MO2-Ready)

```
{PluginName}/
├── {PluginName}.esp                        # Compiled plugin (install in MO2)
├── {PluginName}_spriggit/                  # Spriggit YAML source (editable, re-serializable)
│   ├── .spriggit                           # Spriggit config
│   ├── RecordData.yaml                     # Mod header
│   ├── Npcs/
│   │   └── {editor_id}.yaml                # NPC record (edit + re-serialize, no CK needed)
│   ├── Outfits/                            # Present only if outfit_items used
│   │   └── {editor_id}_Outfit.yaml         # Custom OTFT record
│   └── Cells/
│       └── {group_path}/                   # e.g. 0/1/ for cell FormID 01DB4E
│           └── {cell_editor_id} - {formID}_Skyrim.esm/
│               └── RecordData.yaml         # Cell override with PlacedNpc in Temporary
├── formkey-provenance.yaml                 # Per-record FormKey source tracking
├── WorldKnowledge-ManuallyImport/
│   └── {PluginName}.sknpack                # SkyrimNet knowledge pack (import via Web UI)
└── SKSE/
    └── Plugins/
        └── SkyrimNet/
            └── prompts/
                └── characters/
                    └── {name}_{suffix}.prompt   # Personality (hot-reloadable)
```

**The entire `{PluginName}/` folder is MO2-installable.** Zip it and drop into MO2,
or copy its contents into your MO2 mods folder. The `_spriggit/` subfolder is
inert to the game (MO2 only cares about the .esp, SKSE/, and Data-rooted paths)
but keeps the mod self-contained — edit YAML + re-serialize without the repo.

## Interview Gate

Start every new NPC with this numbered form. The user may answer with numbers only. Ask follow-up questions only for missing required answers, contradictions, or unresolved FormKey needs.

```text
1. NPC name:
2. Plugin name:
3. Race/species:
4. Voice style or vanilla voice type:
5. Combat attitude: friendly / neutral / hostile
6. Placement location:
7. Outfit/clothing/armor:
8. Weapons/inventory:
9. Personality summary:
10. Backstory/origin:
11. Speech style:
12. Relationships/factions:
13. World knowledge: yes/no, and who should know about them?
14. Any mod-added gear, location, faction, or voice? If yes, is Skyrim + SkyLinkAI available for lookup?
15. Appearance basics: sex, height, weight/build, hair, eyes, scars/warpaint, or other visible head details?
```

Required answers: NPC name, race, combat attitude, and placement location. Everything else can be inferred or defaulted, but unresolved mod-added records (question 14) must be resolved before generation proceeds.

## FormKey Resolution Gate

SkyLinkAI is the preferred source of truth when available.

Resolution priority:

```text
skylink-live > xedit-dump > verified-table > user-provided
```

Before live lookup, check Skyrim:

```powershell
Get-Process SkyrimSE -ErrorAction SilentlyContinue
```

If Skyrim is not running and unresolved records require live lookup, stop and say: "Start Skyrim with SkyLinkAI loaded, then tell me when it's ready."

If Skyrim is running, use SkyLinkAI `check_connection` before other SkyLinkAI commands. Use `search_forms`, `get_cell_info`, `get_load_order`, and `get_mod_form_id_prefix` for live resolution. Never invent FormKeys.

When SkyLinkAI cannot resolve a record, fall back to xEdit dump scripts for bulk or authoritative checks. When xEdit is unavailable, fall back to verified `data/*.yaml` tables. When no source can verify the record, stop and ask the user to start Skyrim/SkyLinkAI, choose a known table option, provide a FormKey, or defer the detail.

`data/*.yaml` tables are verified fallback/cache, not a license to invent records. Entries marked `TODO` or `UNVERIFIED` in lookup tables do not count as verified.

## FormKey Provenance

Every generated output must include a provenance file tracking where each external FormKey came from:

```text
output/{PluginName}/formkey-provenance.yaml
```

Required fields per record: `label`, `form_key`, `source`, `evidence`.

Allowed sources: `skylink-live`, `xedit-dump`, `verified-table`, `user-provided`.

`user-provided` FormKeys are allowed but should warn by default and fail in strict verification mode.

Example schema:

```yaml
plugin: GrokTheSmith
records:
  race:
    label: OrcRace
    form_key: 013747:Skyrim.esm
    source: skylink-live
    evidence: "SkyLinkAI search_forms race OrcRace"
  voice:
    label: MaleOrc
    form_key: 013AEA:Skyrim.esm
    source: verified-table
    evidence: data/voices.yaml
  outfit_item:
    label: "Wayfarer's Skirt"
    form_key: 000ABC:WayfarerMod.esp
    source: skylink-live
    evidence: "SkyLinkAI search_forms armor Wayfarer's Skirt"
```

Generate this file from `templates/provenance/formkey-provenance.yaml` after FormKey resolution. Every external FormKey used by generated Spriggit YAML must have a provenance entry unless it is plugin-local.

## Step 2: Fill npc.config.yaml

Create or edit `npc.config.yaml` in the repo root. Use `data/*.yaml` lookup tables to resolve FormIDs:

- **data/races.yaml** → race EditorID to FormKey
- **data/voices.yaml** → voice type to FormKey (vanilla only — NEVER dupe VTYP)
- **data/outfits.yaml** → outfit to FormKey, OR use `outfit_items` for custom OTFT
- **data/locations.yaml** → location key to CELL FormKey

### Config Schema

```yaml
# === IDENTITY ===
name: "Grok"
editor_id: "CustomNPC_Grok"
record_id: "0x800"              # ESL object ID (REFR at 0x801 → prompt suffix 801)
plugin_name: "GrokTheSmith"

# === BODY ===
race: "OrcRace"                 # → data/races.yaml
voice_type: "MaleOrc"           # → data/voices.yaml
combat_attitude: "friendly"     # friendly | neutral | hostile
level: 25
respawn: false

outfit: "OrcishArmor"           # vanilla ref (data/outfits.yaml)
# OR
outfit_items:                   # custom OTFT in plugin
  - "OrcishCuirass"
  - "OrcishBoots"

inventory:                      # optional
  - item: "OrcishWarAxe"
    count: 1

factions: []                    # optional

location: "whiterun_warmaidens" # → data/locations.yaml
position: { x: 50.0, y: -30.0, z: 0.0 }
rotation: { x: 0.0, y: 0.0, z: 90.0 }

# === BEHAVIOR ===
ai:
  mode: "sandbox"               # sandbox (friendly) | none (hostile)
  radius: 512

# === SOUL ===
personality:
  summary: "..."
  interject_summary: "..."
  background: "..."
  personality: "..."
  appearance: "..."
  aspirations: ["..."]
  relationships: ["..."]
  occupation: "..."
  skills: ["..."]
  speech_style: "..."
```

## Step 3: Generate Spriggit YAML → .esp

### 3a: Create the Spriggit directory structure

```
output/{PluginName}_spriggit/
├── RecordData.yaml         # From templates/spriggit/RecordData.yaml
├── Npcs/
│   └── {editor_id}.yaml    # From templates/spriggit/npc_base.yaml
└── .spriggit               # Config file
```

### 3b: RecordData.yaml

Copy from `templates/spriggit/RecordData.yaml`. Replace `{{plugin_name}}` with the actual plugin name.

### 3c: NPC YAML

Use the real Spriggit NPC record format from `templates/spriggit/npc_base.yaml`. Key fields (verified against actual serializations):

```yaml
FormKey: 000800:{PluginName}.esp
IsCompressed: True
MajorRecordFlagsRaw: 262144
EditorID: {editor_id}
SkyrimMajorRecordFlags:
- Compressed

Configuration:
  Flags:
  - AutoCalcStats
  - Unique                    # for named NPCs
  # - Respawn                 # for respawning mooks
  # - Essential               # for unkillable NPCs
  # - Protected               # can only be killed by player
  Level:
    MutagenObjectType: NpcLevel
    Level: {level}
  SpeedMultiplier: 100
  DispositionBase: 35

Factions:
- Faction: {faction_formkey}
  Rank: {rank}
  Fluff: 0x000000

Race: {race_formkey}             # e.g. 013747:Skyrim.esm
Voice: {voice_formkey}           # e.g. 02EDD6:Skyrim.esm
Class: 017008:Skyrim.esm         # Warrior class

AIData:
  Aggression: {value}            # Unaggressive / Aggressive / Frenzied
  Confidence: {value}            # Average (friendly) / Foolhardy (hostile)
  EnergyLevel: 50
  Assistance: HelpsFriendsAndAllies
  Responsibility: NoCrime

Name:
  TargetLanguage: English
  Value: {display_name}

DefaultOutfit: {outfit_formkey}
Packages:
- 0BAD0A:Skyrim.esm              # DefaultSandboxEditorLink (friendly only)

Items:
- Item:
    Item: {item_formkey}
    Count: {count}

# Full PlayerSkills block with all 18 skills (see template)
# Height, Weight, SoundLevel, MajorFlags
```

### 3d: Custom Outfit (if using outfit_items)

If the config uses `outfit_items` instead of `outfit`, generate an OTFT record:

```yaml
# Outfits/{editor_id}_Outfit - {formID}_{plugin}.esp.yaml
FormKey: 000802:{PluginName}.esp
EditorID: {editor_id}_Outfit
Items:
- {item_formkey_1}
- {item_formkey_2}
```

Then reference `000802:{PluginName}.esp` in the NPC's `DefaultOutfit` field.

### 3e: Cell Placement (REFR) — CRITICAL

The NPC must be placed in a cell via a PlacedNoc REFR record. Without this, the NPC exists in the plugin but never appears in-game.

The PlacedNpc goes INSIDE a cell override record. See `templates/spriggit/cell_placement.yaml`.

For interior cells, create a cell override:
```
Cells/{group_path}/{cell_editor_id} - {cell_formID}_Skyrim.esm/RecordData.yaml
```

The group path is derived from the cell FormID's first hex digits:
- FormID 0A2C9E → path: Cells/0/A/

Inside the cell RecordData.yaml, add the PlacedNpc to the `Temporary` list:

```yaml
Temporary:
- MutagenObjectType: PlacedNpc
  FormKey: 000801:{PluginName}.esp     # REFR FormID (ALWAYS at 0x801)
  MajorRecordFlagsRaw: 1024
  SkyrimMajorRecordFlags:
  - 0x400
  Base: 000800:{PluginName}.esp        # References the NPC record
  Placement:
    Position: {x}, {y}, {z}            # From config (game units)
    Rotation: 0, -0, {z_radians}       # Convert degrees to radians
  MajorFlags:
  - Persistent
```

**Rotation conversion:** degrees × (π / 180). Common: 90° = 1.5708, 180° = 3.1416.

**FormID allocation for ESL plugin (MVP):**
- 0x800: NPC record
- 0x801: REFR placement (ALWAYS — fixed so prompt suffix is deterministic)
- 0x802: Custom outfit (if outfit_items used)
- 0x803+: additional records

### 3f: RecordData.yaml (Mod Header)

Copy from `templates/spriggit/RecordData.yaml`. Set the plugin name in `ModKey`.

The template includes `ModHeader.Flags: [0x200]` which sets the ESL flag at
deserialization time — no xEdit post-processing required. The MVP FormID
allocation (0x800+) is within the ESL range (0x000–0xFFF), satisfying the
ESL constraint.

### 3g: Combat Attitude → Field Mapping

| Attitude | Aggression | Confidence | Factions | AI Packages |
|----------|-----------|------------|----------|-------------|
| friendly | Unaggressive | Average | none/TownFaction | DefaultSandboxEditorLink |
| neutral | Aggressive | Brave | none | sandbox or none |
| hostile | Frenzied | Foolhardy | BanditFaction (0x0001BCC0) | none |

### 3h: .spriggit config file

```json
{
  "PackageName": "Spriggit.Yaml.Skyrim",
  "Release": "SkyrimSE",
  "Version": "0.40.0"
}
```

### 3i: Pre-Build Gate

Skyrim should be closed before Spriggit deserialization. Before building, run:

```powershell
Get-Process SkyrimSE -ErrorAction SilentlyContinue
```

If Skyrim is running, stop and say: "Close Skyrim before I rebuild the ESP, then tell me when it's closed."

### 3j: Serialize to .esp

```powershell
& "$env:USERPROFILE\.dotnet\tools\spriggit.yaml.skyrim.exe" deserialize `
  --InputPath "output\{PluginName}_spriggit" `
  --OutputPath "output\{PluginName}\{PluginName}.esp" `
  --DataFolder "$env:SKYRIM_DATA"
```

### 3k: ESL Flagging (Automatic)

The ESL flag is set automatically via `ModHeader.Flags: [0x200]` in
RecordData.yaml. When Spriggit deserializes the YAML to `.esp`, the TES4
header flags field is written with bit 0x200 set — the plugin is ESL-flagged
from creation. No xEdit step required.

The MVP FormID allocation (0x800–0x802) is within the ESL range (0x000–0xFFF),
satisfying the ESL constraint. ESL-flagged plugins do not count against the
255-plugin limit.

## Step 4: Generate SkyrimNet Prompt File

### 4a: Derive filename

```
sanitized_name = name.lower().replace(" ", "_").replace("'", "_").replace("/", "_")
suffix = refr_id & 0xFFF formatted as 3-digit uppercase hex
filename = f"{sanitized_name}_{suffix}.prompt"
```

REFR is ALWAYS at 0x801 (mvp allocation), so suffix is always `801`.
Example: "Grok" + REFR at 0x801 → `grok_801.prompt`

### 4b: Fill the prompt template

Use `templates/prompt/character.prompt` as the base. Each block from the config's `personality` section maps directly to a `{% block %}` in the prompt file.

**CRITICAL: ALL prompt files MUST use `{% block %}` Jinja2 format.** SkyrimNet
wraps character bios with `{% extends "dynamic_character_bio.prompt" %}` at
render time (PromptEngine.cpp:1066). Inja's template inheritance discards any
content that is NOT inside a `{% block %}` tag. Plain text prompts render as
empty — the file is loaded but the personality never appears in dialogue.

The prompt file extends SkyrimNet's `dynamic_character_bio.prompt`, which auto-includes all `submodules/character_bio/` components.

**Hostile NPCs DO receive personality prompts.** SkyrimNet has no hostility
gate — `GameMaster::CanNPCSpeakNearPlayer` explicitly states "Combat is NOT
blocked" (GameMaster.cpp:491). Hostile NPCs get a combat-variant dialogue
prompt and load bios identically to friendly NPCs.

### 4c: Place in output structure

```
output/{PluginName}/SKSE/Plugins/SkyrimNet/prompts/characters/{filename}.prompt
```

## Step 5: Assemble Output

Create the final MO2-ready folder with five components:

1. **Compiled plugin** (`.esp`) — from Spriggit serialization
2. **Spriggit YAML source** (`_spriggit/` directory) — editable text source for re-serialization
3. **SkyrimNet prompt** (`.prompt` file) — personality layer
4. **World knowledge pack** (`.sknpack` file) — optional, makes existing NPCs aware of your new NPC
5. **FormKey provenance** (`formkey-provenance.yaml`) — tracks where every external FormKey came from

```
output/{PluginName}/
├── {PluginName}.esp
├── {PluginName}_spriggit/
│   ├── .spriggit
│   ├── RecordData.yaml
│   ├── Npcs/
│   │   └── {editor_id}.yaml
│   ├── Outfits/                            # Present only if outfit_items used
│   │   └── {editor_id}_Outfit.yaml
│   └── Cells/
│       └── {group_path}/
│           └── {cell_editor_id} - {formID}_Skyrim.esm/
│               └── RecordData.yaml
├── formkey-provenance.yaml                 # FormKey source tracking (required)
├── WorldKnowledge-ManuallyImport/
│   └── {PluginName}.sknpack                # Optional — skip if no world_knowledge entries
└── SKSE/
    └── Plugins/
        └── SkyrimNet/
            └── prompts/
                └── characters/
                    └── {name}_{suffix}.prompt
```

## Step 5b: Generate World Knowledge Pack (Optional)

If `world_knowledge.entries` is non-empty, generate a `.sknpack` file:

### Format

```json
{
  "skyrimnet_knowledge_pack": {
    "author": "Generated via Skyrim_NPCTemplate",
    "description": "World knowledge for {NPC name}",
    "entries": [
      {
        "always_inject": false,
        "condition_expr": "is_in_faction(actorUUID, \"CrimeFactionWhiterun\")",
        "content": "There's an Orc blacksmith named Grok working at Warmaiden's...",
        "display_name": "Grok - General Awareness",
        "emotion": "",
        "importance": 0.5,
        "knowledge_key": "grok.general_awareness",
        "location": "Whiterun",
        "tags": ["Grok", "blacksmith", "Orc"],
        "type": "KNOWLEDGE"
      }
    ],
    "format_version": 2,
    "name": "{NPC name} World Knowledge",
    "npc_groups": [],
    "version": "1.0.0"
  }
}
```

### What Knowledge Entries to Generate

For a friendly NPC placed in an existing community, generate entries that answer:

| Question | Who Knows | Type | Condition |
|----------|-----------|------|-----------|
| "Who is this new NPC?" | Local faction members | KNOWLEDGE | `is_in_faction(actorUUID, "CrimeFaction{City}")` |
| "What's their relationship to nearby named NPCs?" | The named NPCs themselves | RELATIONSHIP | `decnpc(actorUUID).name == "Specific Name"` |
| "What do their own people think?" | Same race/faction | KNOWLEDGE | `decnpc(actorUUID).race == "Orc"` |

### Condition Expression Reference

| Pattern | Who Gets It |
|---------|-------------|
| `""` (empty) | All NPCs |
| `is_in_faction(actorUUID, "CrimeFactionWhiterun")` | Whiterun residents |
| `decnpc(actorUUID).name == "Adrianne Avenicci"` | Specific named NPC |
| `decnpc(actorUUID).race == "Orc"` | All Orcs |
| `get_relationship_rank(actorUUID) >= 2` | Player's friends |
| `is_in_faction(actorUUID, "CompanionsFaction")` | Faction members |

### Installation

The `.sknpack` file is imported manually:
1. Open SkyrimNet Web UI (default: http://localhost:7878)
2. Go to Knowledge Packs → Import
3. Upload the `.sknpack` file
4. Test entries against specific NPCs using the Test button

## Post-Generation Verification

After assembling the output, run the verification script:

```powershell
& .\tools\verify_prompt.ps1 -OutputDir "output\{PluginName}"
```

It checks:
1. **Prompt filename** matches the REFR FormID suffix (read from cell placement YAML, not guessed)
2. **Prompt format** has `{% block %}` tags (rejects plain text)
3. **External FormKeys** exist in verified lookup tables for locations, races, voices, outfits, factions, and AI packages
4. **FormKey provenance** is present and all external FormKeys are backed by `skylink-live`, `xedit-dump`, or `verified-table` sources (warns on `user-provided`)

If something's wrong, run with `-Fix` to auto-copy a misnamed prompt:

```powershell
& .\tools\verify_prompt.ps1 -OutputDir "output\{PluginName}" -Fix
```

Then manually verify:
1. The `.esp` exists and is non-zero size
2. The plugin should be ESL-flagged (check in xEdit if possible)
3. In-game: the NPC appears at the expected location with correct outfit and behavior

## Key Rules

### Voice Types — NEVER Dupe
Always reference vanilla voice type FormIDs directly. SkyrimNet's TTS system maps voices by voice type FormID. A duped VTYP record gets a new FormID that SkyrimNet can't map — resulting in silent NPCs or fallback TTS.

### ESL Constraints
- Record ID must be in `0x000-0xFFF` range (4096 max)
- MVP uses `0x800` for the first (and only) NPC
- No WRLD records (exterior world) — interior cells only
- ESL-flagged ESPs don't count against the 255 plugin limit

### Prompt Filename Convention
The suffix is **`formId & 0xFFF`** where `formId` is the PlacedNpc REFR FormID
(`RE::Actor::GetFormID()` in SkyrimNet source). With REFR always at `0x801`,
the `.prompt` suffix is always `801`.

Generate as `{name}_{suffix}.prompt` — e.g. `shank_801.prompt`.

Reference: `UUIDResolver::GenerateBioTemplateName()` in SkyrimNet source.

### Cell Placement
- Interior cells only via `data/locations.yaml` lookup
- If the location is not in the lookup table, ask the user for the cell Editor ID
- Exterior/exotic placement: instruct user to place manually in Creation Kit

### AI Packages
- Friendly NPCs: reference `DefaultSandboxEditorLink` (FormKey `0BAD0A:Skyrim.esm`)
- Hostile NPCs: no packages needed (aggression flags handle combat behavior)
- NO sleep packages (requires placed bed furniture references — CK territory)

### Appearance Scope

In scope now:
- **Tier 1**: race, sex, height, weight/build, outfit, visible armor/clothing, carried equipment.
- **Tier 2**: hair, eyes, brows, scars, warpaint/tints, and other selectable headparts when resolvable to real FormKeys.

Backlog:
- **Tier 3**: captured face morph values from SkyLinkAI `get_appearance`.
- **Tier 4**: FaceGen mesh/texture generation or import.

The interview asks for Tier 1 and Tier 2 appearance details up front. If the user asks for a sculpted/captured face, record it as backlog unless the dedicated appearance pipeline has been implemented.

## NPC Flags Matrix

| Behavior | `Unique` | `Respawn` | Use Case |
|----------|----------|-----------|----------|
| Fully unique, dies once | ✓ | ✗ | Named NPCs, quest characters |
| Named mook, respawns | ✗ | ✓ | Recurring enemies |
| Named mook, stays dead | ✗ | ✗ | One-time encounter |
| Essential (can't die) | ✓ | ✗ + Essential flag | Follower candidates |

## Out of Scope (MVP)

- Multiple NPCs per plugin
- Papyrus follower scripts (use follower framework mods)
- Sleep packages (requires bed furniture references)
- Exterior world placement
- Custom voice types / TTS voice samples
- Quest-driven behavior or dialogue trees
- Leveled character spawns
- Full day/night AI schedules

## After Generation

Users can customize further:
- **Open .esp in Creation Kit** for advanced record editing
- **Edit .prompt file directly** for personality tweaks (hot-reloadable via SkyrimNet web UI)
- **Re-serialize** with Spriggit after CK edits to update the YAML source
