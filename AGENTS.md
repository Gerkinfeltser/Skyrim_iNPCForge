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
2. Resolve FormKeys via SkyLinkAI > xEdit > verified `data/*.yaml` tables (see SkyLink-Assisted Workflow).
3. Generate Spriggit YAML into `output/{PluginName}_spriggit/` from `templates/spriggit/`.
4. Serialize to `.esp` with the Spriggit CLI.
5. Generate the `.prompt` file from `templates/prompt/character.prompt`.
6. (Optional) Generate `.sknpack` from the `world_knowledge` block.
7. Assemble the MO2-ready folder under `output/{PluginName}/`.

## Commands (Windows / PowerShell)

This repo is Windows-only. Set the Skyrim SE Data folder once per session:

```powershell
# Adjust path to your Steam install. Examples:
#   $env:SKYRIM_DATA = "D:\Steam\steamapps\common\Skyrim Special Edition\Data"
#   $env:SKYRIM_DATA = "C:\Program Files (x86)\Steam\steamapps\common\Skyrim Special Edition\Data"
$env:SKYRIM_DATA = "D:\Steam\steamapps\common\Skyrim Special Edition\Data"
```

Spriggit installs to `$env:USERPROFILE\.dotnet\tools\` (portable — resolves to any user).

**Pre-Build Gate:** Skyrim SHOULD be closed before deserializing. If `SkyrimSE` is running, stop and close it first.

**Serialize Spriggit YAML → .esp:**

```powershell
& "$env:USERPROFILE\.dotnet\tools\spriggit.yaml.skyrim.exe" deserialize `
  --InputPath "output\{PluginName}_spriggit" `
  --OutputPath "output\{PluginName}\{PluginName}.esp" `
  --DataFolder "$env:SKYRIM_DATA"
```

**Reverse (CK edit → YAML, to keep source in sync):**

```powershell
& "$env:USERPROFILE\.dotnet\tools\spriggit.yaml.skyrim.exe" serialize `
  --InputPath "output\{PluginName}\{PluginName}.esp" `
  --OutputPath "output\{PluginName}_spriggit" `
  --DataFolder "$env:SKYRIM_DATA"
```

Spriggit 0.40.0 is pinned via `.spriggit`. Install with
`dotnet tool install --global Spriggit.Yaml.Skyrim`.

**ESL flagging is automatic.** The `ModHeader.Flags: [0x200]` field in
RecordData.yaml sets the ESL bit at deserialization time. FormIDs must be in
the `0x000–0xFFF` range (ESL constraint); the MVP allocation `0x800+`
satisfies this. No xEdit post-processing required.

**No lint/test/typecheck commands exist.** Verification is manual:
`.esp` is non-zero, `.prompt` has all 10 blocks filled, prompt filename matches
the `{name}_{formId & 0xFFF:03X}` convention, ESL flag is set.

## Critical Rules

### Named NPCs MUST be Unique
Named NPCs MUST use the Unique flag in Configuration.Flags. Non-Unique NPCs get their names overwritten by mods like Real Names Extended, which breaks SkyrimNet bio matching. Unique and Respawn are mutually exclusive in Skyrim.

### Voice Types — NEVER Dupe
Always reference **vanilla** voice type FormIDs directly from `data/voices.yaml`.
SkyrimNet's TTS maps voices by voice type FormID. A duped VTYP record gets a new
FormID SkyrimNet cannot map → silent NPC or fallback TTS. This is the one rule
that will silently break the output.

### ESL Constraints
- Record IDs MUST be in the `0x000–0xFFF` range (4096 max).
- MVP allocation: `0x800` = NPC base, `0x801` = PlacedNpc REFR (ALWAYS),
  `0x802` = custom OTFT (if `outfit_items`), `0x803+` = additional records.
- Interior cells ONLY. No WRLD records, no exterior placement.
- ESL-flagged ESPs do not count against the 255-plugin limit.

### Rotation Conversion
Config rotation is in **degrees**; Spriggit REFR records use **radians**.
`radians = degrees × (π / 180)`. Common: 90° = 1.5708, 180° = 3.1416.

### Prompt Filename Convention
The `.prompt` suffix is **`formId & 0xFFF`** formatted as 3-digit uppercase hex,
appended to the sanitized name. Example: "Shank" + REFR `0x801` → `shank_801.prompt`.
Must match exactly what SkyrimNet's `UUIDResolver::GenerateBioTemplateName()`
auto-generates on first encounter, or the prompt is never loaded.

**The filename suffix is the REFR FormID from the cell placement (`0x801`).**
SkyrimNet's `RE::Actor::GetFormID()` returns the PlacedNpc reference FormID, not
the NPC base record. With the MVP allocation (REFR always at `0x801`), the
`.prompt` suffix is always `801`.

### FormID Allocation (ESL MVP)

| FormID | Record |
|--------|--------|
| `0x800` | NPC base record |
| `0x801` | PlacedNpc REFR (ALWAYS — fixed so prompt suffix is deterministic) |
| `0x802` | Custom OTFT outfit (if `outfit_items` used) |
| `0x803+` | Additional records |

**Prompt filename uses the REFR FormID suffix** — SkyrimNet's
`GenerateBioTemplateName` receives the PlacedNpc REFR from
`RE::Actor::GetFormID()`, verified in `Entity.h:GetFormID()` and
`UUIDResolver.h:AddMapping()`. The `.prompt` suffix is always
`0x801 & 0xFFF = 0x801` = `801` for the MVP allocation.

### Combat Attitude → Field Mapping

| Attitude | Aggression | Confidence | AI Packages | Factions |
|----------|-----------|------------|-------------|----------|
| friendly | Unaggressive | Average | DefaultSandboxEditorLink (`0BAD0A:Skyrim.esm`) | none/Town |
| neutral | Aggressive | Brave | sandbox or none | none |
| hostile | Frenzied | Foolhardy | none | BanditFaction (`0x0001BCC0`) |

**Hostile NPCs DO receive personality prompts.** SkyrimNet has no hostility
gate — hostile NPCs get a combat-variant dialogue prompt and load bios
normally (verified against SkyrimNet source, `GameMaster.cpp:491`).
`.prompt` files MUST use `{% block %}` Jinja2 format (see
`templates/prompt/character.prompt`) — plain text is discarded by Inja's
template inheritance when SkyrimNet wraps it with
`{% extends "dynamic_character_bio.prompt" %}`.

### Post-Generation Verification

Run `tools\verify_prompt.ps1` after every generation:

```powershell
.\tools\verify_prompt.ps1 -OutputDir .\output\{PluginName}
```

It catches the three common bugs:
1. Prompt filename doesn't match REFR FormID suffix
2. Prompt is plain text instead of `{% block %}` format
3. External FormKeys not present in verified lookup tables for locations, races,
   voices, outfits, factions, and AI packages

Use `-Fix` to auto-copy a misnamed prompt file.

## SkyLink-Assisted Workflow

For new NPCs, use the numbered interview form in the skill, then resolve FormKeys with this priority:

```text
skylink-live > xedit-dump > verified-table > user-provided
```

SkyLinkAI is preferred for live FormKey resolution, especially mod-added gear, cells, factions, voices, and headparts. If Skyrim/SkyLinkAI is unavailable and a record is not in verified tables, stop and ask the user to start Skyrim, choose a known option, or provide a FormKey. Do not invent IDs.

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
| `templates/provenance/` | FormKey provenance file template |
| `output/{PluginName}/formkey-provenance.yaml` | Generated per-output FormKey provenance |
| `tools/xedit-scripts/` | Pascal scripts for FormID verification via xEdit |
| `tools/verify_prompt.ps1` | Post-generation checker: REFR suffix, block format, faction FormIDs |
| `tools/VERIFICATION-STATUS.md` | Tracks which lookup tables are verified vs pending |
| `examples/grok_the_smith.yaml` | Full friendly-NPC worked example |
| `examples/shank_the_bandit_hostile.yaml` | Minimal hostile-NPC example |
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
- **Appearance MVP**: Tier 1 body basics wire race, height, weight, outfit, and equipment
  into the Spriggit record. `sex` is collected in config but Spriggit mapping is deferred
  until the Female flag structure (`Configuration.Flags: Female`) is verified by serializing
  a known-female NPC. Tier 2 headparts have config placeholders (`hair`, `eyes`, `brows`,
  `scar`, `warpaint`) but Spriggit generation is deferred until the HeadParts/Tints record
  structure is verified. Captured face morphs and FaceGen mesh/texture assets are backlog.

## Out of Scope (MVP)

Multiple NPCs per plugin · Papyrus follower scripts · Sleep AI packages ·
Exterior world placement · Custom voice types / TTS samples · Quest-driven
behavior · Leveled spawns · Full day/night schedules.

## After Generation

The plugin is an MVP. To customize: edit the Spriggit YAML and re-serialize
(no CK needed), open the `.esp` in Creation Kit for advanced edits, or tweak the
`.prompt` file directly (hot-reloadable via SkyrimNet Web UI at
`http://localhost:7878`). Re-serialize after CK edits to keep YAML in sync.
