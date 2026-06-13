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
- Skyrim SE Data folder available at `D:\Steam\steamapps\common\Skyrim Special Edition\Data`
- This repo at `D:\gerkgit\Skyrim_NPCTemplate`

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
Grok.esp   grok_800.prompt
(ESL)       (in characters/)
```

## Output Structure (MO2-Ready)

```
{PluginName}/
├── {PluginName}.esp                        # Compiled plugin (install in MO2)
├── {PluginName}_spriggit/                  # Spriggit YAML source (editable, re-serializable)
│   ├── .spriggit                           # Spriggit config
│   ├── RecordData.yaml                     # Mod header
│   └── Npcs/
│       └── {editor_id}.yaml                # NPC record (edit + re-serialize, no CK needed)
├── {PluginName}.sknpack                    # SkyrimNet knowledge pack (import via Web UI)
└── SKSE/
    └── Plugins/
        └── SkyrimNet/
            └── prompts/
                └── characters/
                    └── {name}_{suffix}.prompt   # Personality (hot-reloadable)
```

## Step 1: Gather Requirements

Ask the user (or infer from the request):

| Field | Example | Required? |
|-------|---------|-----------|
| Name | "Grok" | Yes |
| Race | "Orc" | Yes |
| Personality | "Gruff blacksmith, loyal" | Yes |
| Combat attitude | friendly / neutral / hostile | Yes (default: friendly) |
| Location | "Whiterun" | Yes |
| Voice type | "Deep, Orcish" | Optional (agent picks from voices.yaml) |
| Outfit | "Orcish armor" | Optional (agent picks from outfits.yaml) |
| Level | 25 | Optional (default: scales with context) |
| Skills | "Smithing, two-handed" | Optional |

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
record_id: "0x800"              # ESL object ID → prompt suffix
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

Use the real Spriggit NPC record format (based on Spriggit 0.40.0 serialization). Key fields:

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
  # Add conditionally:
  # - Unique       (for unique named NPCs)
  # - Respawn      (for respawning mooks)
  # - Essential    (for plot-critical NPCs)
  Level:
    MutagenObjectType: PcLevelMult
    LevelMult: 1
  SpeedMultiplier: 100
  DispositionBase: 35

Race: {race_formkey}          # e.g. 013747:Skyrim.esm
AIData:
  Aggression: {value}         # See combat attitude mapping below
  Confidence: {value}         # Foolhardy for hostile, Average for friendly
  EnergyLevel: 50
  Responsibility: NoCrime
Voice: {voice_formkey}

Class: {class_formkey}        # e.g. 017008:Skyrim.esm (Warrior)
Name:
  TargetLanguage: English
  Value: {display_name}

DefaultOutfit: {outfit_formkey}    # If using vanilla ref
# OR generate a custom OTFT record

# PackageList for AI (sandbox only for friendly NPCs)
PackageList:
- 0BAD0A:Skyrim.esm            # DefaultSandboxEditorLink

Height: 1
Weight: 100
SoundLevel: Normal

MajorFlags:
- 0x40000
```

### 3d: Combat Attitude → Field Mapping

| Attitude | Aggression | Confidence | Factions | AI Packages |
|----------|-----------|------------|----------|-------------|
| friendly | Unaggressive | Average | none/TownFaction | DefaultSandboxEditorLink |
| neutral | Aggressive | Brave | none | sandbox or none |
| hostile | Frenzied | Foolhardy | BanditFaction/etc | none |

### 3e: .spriggit config file

```json
{
  "PackageName": "Spriggit.Yaml.Skyrim",
  "Release": "SkyrimSE",
  "Version": "0.40.0"
}
```

### 3f: Serialize to .esp

```powershell
& "$env:USERPROFILE\.dotnet\tools\spriggit.yaml.skyrim.exe" deserialize `
  --InputPath "output\{PluginName}_spriggit" `
  --OutputPath "output\{PluginName}\{PluginName}.esp" `
  --DataFolder "D:\Steam\steamapps\common\Skyrim Special Edition\Data"
```

## Step 4: Generate SkyrimNet Prompt File

### 4a: Derive filename

```
sanitized_name = name.lower().replace(" ", "_").replace("'", "_").replace("/", "_")
suffix = record_id & 0xFFF formatted as 3-digit uppercase hex
filename = f"{sanitized_name}_{suffix}.prompt"
```

Example: "Grok" + 0x800 → `grok_800.prompt`

### 4b: Fill the prompt template

Use `templates/prompt/character.prompt` as the base. Each block from the config's `personality` section maps directly to a `{% block %}` in the prompt file.

The prompt file extends SkyrimNet's `dynamic_character_bio.prompt`, which auto-includes all `submodules/character_bio/` components.

### 4c: Place in output structure

```
output/{PluginName}/SKSE/Plugins/SkyrimNet/prompts/characters/{filename}.prompt
```

## Step 5: Assemble Output

Create the final MO2-ready folder with four components:

1. **Compiled plugin** (`.esp`) — from Spriggit serialization
2. **Spriggit YAML source** (`_spriggit/` directory) — editable text source for re-serialization
3. **SkyrimNet prompt** (`.prompt` file) — personality layer
4. **World knowledge pack** (`.sknpack` file) — optional, makes existing NPCs aware of your new NPC

```
output/{PluginName}/
├── {PluginName}.esp
├── {PluginName}_spriggit/
│   ├── .spriggit
│   ├── RecordData.yaml
│   └── Npcs/
│       └── {editor_id}.yaml
├── {PluginName}.sknpack                    # Optional — skip if no world_knowledge entries
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

## Step 6: Verify

1. Check the `.esp` exists and is non-zero size
2. Verify the `.prompt` file has all 10 blocks filled
3. Confirm the prompt filename matches the `_{formId & 0xFFF}` convention
4. The plugin should be ESL-flagged (check in xEdit if possible)

## Key Rules

### Voice Types — NEVER Dupe
Always reference vanilla voice type FormIDs directly. SkyrimNet's TTS system maps voices by voice type FormID. A duped VTYP record gets a new FormID that SkyrimNet can't map — resulting in silent NPCs or fallback TTS.

### ESL Constraints
- Record ID must be in `0x000-0xFFF` range (4096 max)
- MVP uses `0x800` for the first (and only) NPC
- No WRLD records (exterior world) — interior cells only
- ESL-flagged ESPs don't count against the 255 plugin limit

### Prompt Filename Convention
The suffix is **`formId & 0xFFF`** — the last 3 hex digits of the NPC's FormID. For ESL plugins, this is deterministic (the object ID portion).

The SkyrimNet engine auto-generates bio template names as `{sanitized_name}_{formId & 0xFFF:03X}` on first NPC encounter. The prompt file in `characters/` must match this exactly.

Reference: `UUIDResolver::GenerateBioTemplateName()` in SkyrimNet source.

### Cell Placement
- Interior cells only via `data/locations.yaml` lookup
- If the location is not in the lookup table, ask the user for the cell Editor ID
- Exterior/exotic placement: instruct user to place manually in Creation Kit

### AI Packages
- Friendly NPCs: reference `DefaultSandboxEditorLink` (FormKey `0BAD0A:Skyrim.esm`)
- Hostile NPCs: no packages needed (aggression flags handle combat behavior)
- NO sleep packages (requires placed bed furniture references — CK territory)

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
