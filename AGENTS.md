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
npc-yaml/{Name}_iNPC.yaml ──► Spriggit YAML ──► {Name}_iNPC.esp   (record layer)
                          ──► character.prompt ──► {name}_{id}.prompt (personality layer)
                          ──► world_knowledge ──► WorldKnowledge-ManuallyImport/{Name}_iNPC.sknpack (awareness layer)
```

1. Fill `npc-yaml/{Name}_iNPC.yaml` (single source of truth for working NPC configs).
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

**Pre-Build Gate:** Skyrim SHOULD be closed before deserializing to the active
MO2-ready `.esp` path. If `SkyrimSE` is running, do not overwrite the loaded
plugin. Either stop and ask the user to close Skyrim first, or deserialize to a
staged path under `_tmp/` for validation only.

**Serialize Spriggit YAML → .esp:**

```powershell
& "$env:USERPROFILE\.dotnet\tools\spriggit.yaml.skyrim.exe" deserialize `
  --InputPath "output\{PluginName}_spriggit" `
  --OutputPath "output\{PluginName}\{PluginName}.esp" `
  --DataFolder "$env:SKYRIM_DATA"
```

**Safe staged build while Skyrim is open:**

```powershell
& "$env:USERPROFILE\.dotnet\tools\spriggit.yaml.skyrim.exe" deserialize `
  --InputPath "output\{PluginName}_spriggit" `
  --OutputPath "_tmp\staged-esp\{PluginName}.esp" `
  --DataFolder "$env:SKYRIM_DATA"
```

Staged builds prove the YAML deserializes and produce a reviewable `.esp`, but
only after Skyrim is closed and the file lock is released.

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
the `{name}_{formId & 0xFFF:03X}` convention, ESL flag is set, and any cloned
or sculpted face has matching FaceGen mesh/tint assets in the generated output.

## Critical Rules

### Named NPCs MUST be Unique
Named NPCs MUST use the Unique flag in Configuration.Flags. Non-Unique NPCs get their names overwritten by mods like Real Names Extended, which breaks SkyrimNet bio matching. Unique and Respawn flags can coexist — the CK UI prevents both being set, but xEdit/Spriggit accepts the combination and the engine honors both.

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

For static NPC appearance in the ADT load order, prefer the offline xEdit dump
workflow in `D:\gerkgit\SkyrimNet_iPrompts\misc\xedit\README.md` when available.
That dump reads winning `NPC_` records through MO2/xEdit and can provide
headparts, face morphs, tint layers, race, weight, hair color, outfit, voice,
and class without launching Skyrim. It does not replace runtime checks for
save-state, dead/disabled refs, placement, or the final rendered face.

When cloning a specific NPC's appearance from a load-order override, copying the
`NPC_` record fields is not enough. Skyrim uses baked FaceGen assets for the
actual head sculpt and tint. Copy the source actor's FaceGeom/FaceTint pair into
the generated output under the generated plugin name and NPC base FormID:

```text
output/{PluginName}/meshes/actors/character/FaceGenData/FaceGeom/{PluginName}.esp/00000800.NIF
output/{PluginName}/textures/actors/character/FaceGenData/FaceTint/{PluginName}.esp/00000800.dds
```

For the MVP allocation, `0x800` is the NPC base, so the FaceGen filename is
`00000800`. If the NPC base FormID changes, use that object ID as 8-digit hex.
The source FaceGen files may be stored under the actor's original master/FormID
folder (for example `Skyrim.esm\000B9982`) even when the winning appearance
record comes from an override plugin.
Without the matching FaceGen files, the actor may load with the wrong sculpt,
wrong tint, or shiny/gold/dark-face style rendering artifacts even when the YAML
record values look correct.

## Directory Map

| Path | Purpose |
|------|---------|
| `npc-yaml/` | **Fill this in** — local-only working NPC YAML base. Use `{Name}_iNPC.yaml` naming. Contents are ignored by git unless explicitly promoted. |
| `npc.config.yaml` | Mad-libs config template/reference; copy to `npc-yaml/{Name}_iNPC.yaml` for active NPCs. |
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
| `examples/grok_the_smith.yaml` | Full friendly-NPC worked example; keep as reference material |
| `examples/shank_the_bandit_hostile.yaml` | Minimal hostile-NPC example; keep as reference material |
| `output/` | Generated plugins land here (gitkept) |
| `_tmp/` | Scratch space (gitignored) |

## Conventions

- **YAML** for all config and Spriggit source. Put active NPC base YAML in
  `npc-yaml/`; keep `examples/` for specific worked examples like Grok and
  Shank, not local experiments.
- **Generated naming**: use `_iNPC` for new generated plugin/config/output names,
  e.g. `Brenaen_iNPC.yaml`, `Brenaen_iNPC.esp`, `output/Brenaen_iNPC/`.
- **EditorIDs** MUST be unique and have no spaces. Prefer the same suffix style
  for generated NPCs, e.g. `Brenaen_iNPC`.
- **Outfits**: either reference a vanilla record (`outfit: "OrcishArmor"`) OR
  generate a custom OTFT via `outfit_items: [...]`. Never both.
- **Placement**: interior cells only via `data/locations.yaml`. Exterior or
  unmapped locations → instruct the user to place manually in Creation Kit.
- **AI packages**: `sandbox` for friendly, `none` for hostile. No sleep packages
  (requires placed bed furniture references — CK territory).
- **Generated outputs** are disposable; the YAML source in `_spriggit/` is the
  editable artifact. Re-serialize after edits.
- **Appearance support**: Tier 1 body basics wire race, sex, height, weight,
  outfit, and equipment into the Spriggit record. `sex: "female"` maps to
  `Configuration.Flags: Female`; male is the absence of that flag. Tier 2
  Spriggit fields are verified for `HeadParts`, `HairColor`, `FaceParts`,
  `FaceMorph`, and `TintLayers`. For cloned/sculpted faces, also copy the baked
  FaceGen mesh/tint assets into the generated plugin's FaceGenData paths.

## Out of Scope (MVP)

Multiple NPCs per plugin · Papyrus follower scripts · Sleep AI packages ·
Exterior world placement · Custom voice types / TTS samples · Quest-driven
behavior · Leveled spawns · Full day/night schedules.

## After Generation

The plugin is an MVP. To customize: edit the Spriggit YAML and re-serialize
(no CK needed), open the `.esp` in Creation Kit for advanced edits, or tweak the
`.prompt` file directly (hot-reloadable via SkyrimNet Web UI at
`http://localhost:7878`). Re-serialize after CK edits to keep YAML in sync.
