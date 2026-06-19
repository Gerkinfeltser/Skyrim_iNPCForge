# Skyrim NPC Template

> **⚠ ALPHA — Work in Progress.** This pipeline works for small numbers of verified examples (see below), but this is a template/recipe project still being actively developed. Config formats change without notice, lookup tables are incomplete, and generating a new NPC from scratch involves manual steps (FormKey resolution, location mapping, asset copying). Do not expect plug-and-receive-an-NPC reliability yet. Contributions and issue reports welcome.

Config-driven pipeline for generating complete, self-contained, ESL-flagged Skyrim SE NPC plugins with [SkyrimNet](https://github.com/art-from-the-machine/SkyrimNet) AI dialogue support.

## What It Does

Fill in one config file → get a ready-to-install mod folder with:
1. **ESP plugin** (ESL-flagged, Spriggit-generated) — race, stats, voice, outfit, AI, placement
2. **SkyrimNet prompt file** — personality, background, speech style, relationships
3. **Optional FaceGen assets** — required when cloning a sculpted NPC face from another actor/plugin

```
npc-yaml/{Name}_iNPC.yaml ──► output/{Name}_iNPC/{Name}_iNPC.esp (ESL, compiled)
                         ──► output/{Name}_iNPC/{Name}_iNPC_spriggit/ (YAML source, editable)
                         ──► output/{Name}_iNPC/SKSE/.../characters/{name}_801.prompt
                         ──► output/{Name}_iNPC/WorldKnowledge-ManuallyImport/{Name}_iNPC.sknpack
```

## Quick Start

### See a Complete Example

**[`examples/GrokTheSmith_output/`](examples/GrokTheSmith_output/)** — a fully verified, in-game tested output (2026-06-13). Orc blacksmith at Warmaiden's forge in Whiterun, custom outfit, sandbox AI, SkyrimNet personality, world knowledge. Every file is there: the `.esp`, the Spriggit YAML source, the `.prompt`, and the `.sknpack`. See its [README](examples/GrokTheSmith_output/README.md) for details.

### For Agents

Read `.opencode/skills/skyrim-npc-template/SKILL.md` — it's the complete recipe.

1. Fill in `npc-yaml/{Name}_iNPC.yaml`
2. Generate Spriggit YAML from `templates/spriggit/`
3. Serialize with `spriggit deserialize`
4. Generate prompt file from `templates/prompt/character.prompt`
5. Assemble into MO2-ready folder in `output/`

For mod-added records or load-order-specific clones, use
`.opencode/skills/lookup-table-extension/SKILL.md`. It documents the preferred
resolution chain: SkyLink AI live lookup, SkyrimPatcherMCP offline MO2 lookup,
Spriggit serialization, xEdit dumps, then verified tables.

### For Humans

1. Copy an existing local config in `npc-yaml/` or start a new `npc-yaml/{Name}_iNPC.yaml`
2. Use `examples/grok_the_smith.yaml` and `examples/shank_the_bandit_hostile.yaml` as reference-only examples
3. Generate the plugin (run the agent, or use Spriggit CLI directly)
4. Drop the `output/{PluginName}/` folder into MO2

## Directory Structure

```
Skyrim_NPCTemplate/
├── npc-yaml/                     # Local-only working NPC YAML base
├── npc.config.yaml               # Mad-libs template; copy into npc-yaml/
├── .opencode/
│   └── skills/
│       └── skyrim-npc-template/
│           └── SKILL.md          # Agent recipe (read this first)
├── data/                         # Lookup tables
│   ├── races.yaml                # Race EditorIDs → FormIDs
│   ├── voices.yaml               # Voice types → FormIDs
│   ├── locations.yaml            # Interior cells → CELL FormIDs
│   └── outfits.yaml              # Vanilla outfits → FormIDs
├── templates/
│   ├── spriggit/
│   │   ├── RecordData.yaml         # Mod header template
│   │   ├── npc_base.yaml           # NPC record reference
│   │   ├── cell_placement.yaml     # REFR placement reference (critical)
│   │   └── outfit_custom.yaml      # Custom OTFT record reference
│   ├── prompt/
│   │   └── character.prompt        # Personality template (10 blocks)
│   └── knowledge/
│       └── world_knowledge.sknpack # World knowledge pack template
├── examples/
│   ├── grok_the_smith.yaml       # Friendly NPC config example
│   ├── GrokTheSmith_output/      # Complete verified output (ESL .esp + YAML + prompt + sknpack)
│   └── shank_the_bandit_hostile.yaml # Hostile NPC (minimal example)
└── output/                       # Generated plugins land here
```

## Config Reference

Use `npc-yaml/{Name}_iNPC.yaml` for active NPC configs. Copy `npc.config.yaml`
as the mad-libs starting template, and use `examples/*.yaml` for worked examples.

Default generated naming uses the `_iNPC` suffix for plugin/config/output names,
for example `Brenaen_iNPC.yaml`, `Brenaen_iNPC.esp`, and `output/Brenaen_iNPC/`.

### Combat Attitudes

| Attitude | Behavior | AI Packages | Example |
|----------|----------|-------------|---------|
| `friendly` | Won't attack, sandbox AI | DefaultSandboxEditorLink | Merchant, citizen |
| `neutral` | Aggressive if provoked | Sandbox or none | Guard |
| `hostile` | Attacks on sight | None | Bandit, draugr |

### Voice Types

**Never duplicate voice type records.** For normal generated NPCs, use vanilla
voice type references from `data/voices.yaml`. For full clones that require the
source plugin as a master, reference the source actor's existing VTYP directly
and record provenance. SkyrimNet can clone/map source-master voice types, but a
duped VTYP gets a new FormID and can break TTS mapping.

See `data/voices.yaml` for the full list.

### Outfits

Two options:
- **`outfit: "OrcishArmor"`** — references a vanilla outfit record
- **`outfit_items: [...]`** — generates a custom OTFT record in the plugin with the specified items

### Locations

Interior cells only (taverns, shops, dungeons). See `data/locations.yaml` for pre-mapped locations. For exterior or unmapped locations, place the NPC manually in Creation Kit after generation.

## Installation (After Generation)

The `output/{PluginName}/` folder is MO2-ready. Three steps:

1. **Install the mod** — copy the entire `{PluginName}/` folder into your MO2 mods directory (or zip it and drag into MO2). Enable the `.esp` in your load order.
2. **Import world knowledge** (if you generated a `.sknpack`) — open the SkyrimNet Web UI (`http://localhost:7878` while Skyrim is running), import `WorldKnowledge-ManuallyImport/{PluginName}.sknpack`. This makes existing NPCs aware of your new NPC.
3. **Find your NPC in-game** — they're placed at the interior cell from your config (e.g. Warmaiden's forge). Talk to them. SkyrimNet auto-generates the prompt template on first encounter using the `{name}_{formID & 0xFFF}.prompt` convention.

**The `.prompt` file is hot-reloadable** — edit it and reload via the SkyrimNet Web UI without restarting the game.

## After Generation

The generated plugin is an MVP — functional but basic. To customize further:

- **Edit the Spriggit YAML** in `output/{PluginName}/{PluginName}_spriggit/` and re-serialize — no CK needed
- **Open the .esp in Creation Kit** for advanced edits (packages, placement, new face sculpting)
- **Edit the .prompt file** — tweak personality, speech style, relationships
- **Re-serialize with Spriggit** after CK edits to keep YAML source in sync

If Skyrim is running, do not overwrite the active `.esp`. Build to a staged path
such as `_tmp/staged-esp/{PluginName}.esp` for validation, then replace the
MO2-ready plugin only after Skyrim is closed.

For static NPC appearance data from a modlist load order, use the companion
SkyrimPatcherMCP offline lookup first when available (`search_records` and
`read_record` against the MO2 profile). For full appearance extraction, use the
companion SkyrimNet_iPrompts xEdit runbook when available. Set
`$SKYRIMNET_IPROMPTS_DIR` to that repo root, then read
`$SKYRIMNET_IPROMPTS_DIR\misc\xedit\README.md`. That external runbook dumps
winning `NPC_` records through MO2/xEdit without launching Skyrim; it does not
replace runtime checks for save-state, placement, or the final rendered face.

### Cloned FaceGen Assets

If you recreate or clone an existing sculpted NPC, copying the Spriggit `NPC_`
record fields is not enough. Skyrim also needs baked FaceGen assets named for
the generated plugin and NPC base FormID.

For the standard MVP allocation (`0x800` NPC base), place them here:

```text
output/{PluginName}/meshes/actors/character/FaceGenData/FaceGeom/{PluginName}.esp/00000800.NIF
output/{PluginName}/textures/actors/character/FaceGenData/FaceTint/{PluginName}.esp/00000800.dds
```

Without those files, the NPC can have the right hair/headpart records but still
show the wrong face sculpt, wrong skin tint, or shiny/gold/dark-face artifacts.
For non-standard FormIDs, replace `00000800` with the NPC base object ID as
8-digit uppercase hex. The source FaceGen files may live under the actor's
original master/FormID folder, such as `Skyrim.esm\000B9982`, even when the
winning appearance record comes from an override plugin.

FaceGen is not always the only required asset. If the cloned NPC or its FaceGen
references custom meshes, textures, body files, hair files, armor files, or `.tri`
files under source-mod folders, keep those source assets installed or copy those
folders into the generated output with the same relative paths.

## Requirements

- [Spriggit](https://github.com/Mutagen-Modding/Spriggit) 0.40.0 (`dotnet tool install --global Spriggit.Yaml.Skyrim`)
- Skyrim SE with SkyrimNet installed
- Mod Organizer 2 (recommended)
- Optional: [SkyrimPatcherMCP](https://github.com/ViceReversa/SkyrimPatcherMCP) for offline MO2/load-order record lookup

## Out of Scope (MVP)

- Multiple NPCs per plugin
- Papyrus follower scripts
- Sleep AI packages
- Exterior world placement
- New custom voice types / TTS samples
- Quest-driven behavior

## Credits

This project builds on the work of many others in the Skyrim modding community:

### Required — Core Pipeline

- **[Spriggit](https://github.com/Mutagen-Modding/Spriggit)** / **[Mutagen](https://github.com/Mutagen-Modding/Mutagen)** by Noggog — YAML ↔ ESP serialization; the entire record layer depends on this.
- **[SkyrimNet](https://github.com/MinLL/SkyrimNet-GamePlugin)** by MinLL — AI dialogue runtime that powers generated prompt files and world knowledge packs.
- **[SkyLink AI](https://www.nexusmods.com/skyrimspecialedition/mods/175682)** by JarvannDarr — SKSE MCP server for real-time FormKey resolution and runtime verification during development.
- **[SkyrimPatcherMCP](https://github.com/ViceReversa/SkyrimPatcherMCP)** by ViceReversa — Optional offline MO2/load-order record lookup and patching MCP used for supported FormKey resolution and conflict inspection.
- **[xEdit](https://tes5edit.github.io/)** by ElminsterAU, zilav, Sharlikran, and contributors — Plugin record inspection and load-order FormID verification.

### Required — Indirect

- **[SKSE](https://skse.silverlock.org/)** by ianpatt, behippo, and plb — The Skyrim Script Extender; required by SkyrimNet, SkyLink AI, and any Papyrus-based follower framework.
- **[CommonLibSSE-NG](https://github.com/CharmedBaryon/CommonLibSSE-NG)** by CharmedBaryon — Native API library underpinning the SKSE plugin ecosystem used by this pipeline.

### Templates & Resources

- **[Custom Follower Baseline](https://www.nexusmods.com/skyrimspecialedition/mods/161451)** by Aflin — AA01 Papyrus follower framework used as reference for Spriggit follower templates (see `docs/feature-requests/follower-pipeline.md`).

### Recommended

- **[Mod Organizer 2](https://www.nexusmods.com/skyrimspecialedition/mods/6194)** — Mod manager used for installing and testing generated output.
- **Creation Kit** by Bethesda — Plugin authoring and advanced record editing.

### Testing & Development

- **[Styyx's Tooling for Dev (STD)](https://github.com/Styyx1/ADT)** by Styyx1 and Althro — Wabbajack mod author toolkit used as a development and testing environment for generated plugins.
