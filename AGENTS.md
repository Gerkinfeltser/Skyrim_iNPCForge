# AGENTS.md — Skyrim iNPCForge

Config-driven pipeline for generating self-contained, ESL-flagged Skyrim SE NPC
plugins with [SkyrimNet](https://github.com/art-from-the-machine/SkyrimNet) AI
dialogue. One YAML config in → a ready-to-install MO2 folder out.

There is no application code, build system, or test suite here. This repo is a
**template + recipe**: lookup tables, Jinja-style templates, worked examples,
and an authoritative agent skill. "Running" this project means following the
pipeline in `.opencode/skills/skyrim-npc-template/SKILL.md`.

## Authoritative Recipe

**`.opencode/skills/skyrim-npc-template/SKILL.md`** is the complete, canonical
recipe (480+ lines). READ IT FIRST before generating anything. It supersedes
this file in detail. AGENTS.md is the orientation map; the SKILL is the
step-by-step.

## Pipeline

```
npc.config.yaml ──► Spriggit YAML ──► {PluginName}.esp   (record layer)
                ──► character.prompt ──► {name}_{id}.prompt (personality layer)
                ──► world_knowledge ──► {PluginName}.sknpack (awareness layer)
```

1. Fill `npc.config.yaml` (single source of truth).
2. Resolve FormKeys via `data/*.yaml` lookup tables.
3. Generate Spriggit YAML into `output/{PluginName}_spriggit/` from `templates/spriggit/`.
4. Serialize to `.esp` with the Spriggit CLI.
5. Generate the `.prompt` file from `templates/prompt/character.prompt`.
6. (Optional) Generate `.sknpack` from the `world_knowledge` block.
7. Assemble the MO2-ready folder under `output/{PluginName}/`.

## Commands (Windows / PowerShell)

This repo is Windows-only. Target Skyrim SE Data folder:

```
D:\Steam\steamapps\common\Skyrim Special Edition\Data
```

**Serialize Spriggit YAML → .esp:**

```powershell
& "$env:USERPROFILE\.dotnet\tools\spriggit.yaml.skyrim.exe" deserialize `
  --InputPath "output\{PluginName}_spriggit" `
  --OutputPath "output\{PluginName}\{PluginName}.esp" `
  --DataFolder "D:\Steam\steamapps\common\Skyrim Special Edition\Data"
```

**Reverse (CK edit → YAML, to keep source in sync):**

```powershell
& "$env:USERPROFILE\.dotnet\tools\spriggit.yaml.skyrim.exe" serialize `
  --InputPath "output\{PluginName}\{PluginName}.esp" `
  --OutputPath "output\{PluginName}_spriggit" `
  --DataFolder "D:\Steam\steamapps\common\Skyrim Special Edition\Data"
```

Spriggit 0.40.0 is pinned via `.spriggit`. Install with
`dotnet tool install --global Spriggit.Yaml.Skyrim`.

**ESL flagging is NOT automatic.** Spriggit produces a plain `.esp`. After
deserialization, either rename to `.esl` or set the ESL flag in xEdit
(right-click → "Compact FormIDs for ESL" → "Add ESL flag" → save).

**No lint/test/typecheck commands exist.** Verification is manual:
`.esp` is non-zero, `.prompt` has all 10 blocks filled, prompt filename matches
the `{name}_{formId & 0xFFF:03X}` convention, ESL flag is set.

## Critical Rules

### Voice Types — NEVER Dupe
Always reference **vanilla** voice type FormIDs directly from `data/voices.yaml`.
SkyrimNet's TTS maps voices by voice type FormID. A duped VTYP record gets a new
FormID SkyrimNet cannot map → silent NPC or fallback TTS. This is the one rule
that will silently break the output.

### ESL Constraints
- Record IDs MUST be in the `0x000–0xFFF` range (4096 max).
- MVP allocation: `0x800` = NPC, `0x801` = custom outfit (if `outfit_items`),
  `0x802` = REFR placement, `0x803+` = additional records.
- Interior cells ONLY. No WRLD records, no exterior placement.
- ESL-flagged ESPs do not count against the 255-plugin limit.

### Rotation Conversion
Config rotation is in **degrees**; Spriggit REFR records use **radians**.
`radians = degrees × (π / 180)`. Common: 90° = 1.5708, 180° = 3.1416.

### Prompt Filename Convention
The `.prompt` suffix is **`formId & 0xFFF`** formatted as 3-digit uppercase hex,
appended to the sanitized name. Example: "Grok" + `0x800` → `grok_800.prompt`.
Must match exactly what SkyrimNet's `UUIDResolver::GenerateBioTemplateName()`
auto-generates on first encounter, or the prompt is never loaded.

### Combat Attitude → Field Mapping

| Attitude | Aggression | Confidence | AI Packages | Factions |
|----------|-----------|------------|-------------|----------|
| friendly | Unaggressive | Average | DefaultSandboxEditorLink (`0BAD0A:Skyrim.esm`) | none/Town |
| neutral | Aggressive | Brave | sandbox or none | none |
| hostile | Frenzied | Foolhardy | none | BanditFaction (`0x00033A35`) |

Hostile NPCs generally skip the personality prompt entirely — see
`examples/hostile_bandit.yaml`.

## Directory Map

| Path | Purpose |
|------|---------|
| `npc.config.yaml` | **Fill this in** — single source of truth |
| `.opencode/skills/skyrim-npc-template/SKILL.md` | Authoritative recipe (read first) |
| `data/races.yaml` | Race EditorID → FormKey |
| `data/voices.yaml` | Voice type → FormKey (vanilla only) |
| `data/outfits.yaml` | Vanilla outfit → FormKey |
| `data/locations.yaml` | Interior cell key → CELL FormKey + group path |
| `templates/spriggit/` | `RecordData.yaml`, `npc_base.yaml`, `cell_placement.yaml`, `outfit_custom.yaml` |
| `templates/prompt/character.prompt` | 10-block personality Jinja template |
| `templates/knowledge/world_knowledge.sknpack` | World knowledge pack template |
| `examples/grok_the_smith.yaml` | Full friendly-NPC worked example |
| `examples/hostile_bandit.yaml` | Minimal hostile-NPC example |
| `output/` | Generated plugins land here (gitkept) |
| `_tmp/` | Scratch space (gitignored) |

## Conventions

- **YAML** for all config and Spriggit source. Keep `npc.config.yaml` commented
  — inline comments are the field reference for humans.
- **EditorIDs** MUST use a mod prefix and no spaces (`CustomNPC_Grok`,
  `Bandit_Shard_Shank`).
- **Outfits**: either reference a vanilla record (`outfit: "OrcishArmor"`) OR
  generate a custom OTFT via `outfit_items: [...]`. Never both.
- **Placement**: interior cells only via `data/locations.yaml`. Exterior or
  unmapped locations → instruct the user to place manually in Creation Kit.
- **AI packages**: `sandbox` for friendly, `none` for hostile. No sleep packages
  (requires placed bed furniture references — CK territory).
- **Generated outputs** are disposable; the YAML source in `_spriggit/` is the
  editable artifact. Re-serialize after edits.

## Out of Scope (MVP)

Multiple NPCs per plugin · Papyrus follower scripts · Sleep AI packages ·
Exterior world placement · Custom voice types / TTS samples · Quest-driven
behavior · Leveled spawns · Full day/night schedules.

## After Generation

The plugin is an MVP. To customize: edit the Spriggit YAML and re-serialize
(no CK needed), open the `.esp` in Creation Kit for advanced edits, or tweak the
`.prompt` file directly (hot-reloadable via SkyrimNet Web UI at
`http://localhost:7878`). Re-serialize after CK edits to keep YAML in sync.
