# Skyrim NPC Template

Config-driven pipeline for generating complete, self-contained, ESL-flagged Skyrim SE NPC plugins with [SkyrimNet](https://github.com/art-from-the-machine/SkyrimNet) AI dialogue support.

## What It Does

Fill in one config file → get a ready-to-install mod folder with:
1. **ESP plugin** (ESL-flagged, Spriggit-generated) — race, stats, voice, outfit, AI, placement
2. **SkyrimNet prompt file** — personality, background, speech style, relationships

```
npc.config.yaml ──► {PluginName}.esp (ESL, compiled)
                ──► {PluginName}_spriggit/ (YAML source, editable)
                ──► characters/grok_801.prompt (SkyrimNet AI)
                ──► {PluginName}.sknpack (world knowledge — NPCs know about Grok)
```

## Quick Start

### See a Complete Example

**[`examples/GrokTheSmith_output/`](examples/GrokTheSmith_output/)** — a fully verified, in-game tested output (2026-06-13). Orc blacksmith at Warmaiden's forge in Whiterun, custom outfit, sandbox AI, SkyrimNet personality, world knowledge. Every file is there: the `.esp`, the Spriggit YAML source, the `.prompt`, and the `.sknpack`. See its [README](examples/GrokTheSmith_output/README.md) for details.

### For Agents

Read `.opencode/skills/skyrim-npc-template/SKILL.md` — it's the complete recipe.

1. Fill in `npc.config.yaml`
2. Generate Spriggit YAML from `templates/spriggit/`
3. Serialize with `spriggit deserialize`
4. Generate prompt file from `templates/prompt/character.prompt`
5. Assemble into MO2-ready folder in `output/`

### For Humans

1. Copy `npc.config.yaml` and edit the fields
2. Use `examples/grok_the_smith.yaml` as reference
3. Generate the plugin (run the agent, or use Spriggit CLI directly)
4. Drop the `output/{PluginName}/` folder into MO2

## Directory Structure

```
Skyrim_NPCTemplate/
├── npc.config.yaml               # Fill this in — single source of truth
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
│   ├── grok_the_smith.yaml       # Friendly NPC config (input)
│   ├── GrokTheSmith_output/      # Complete verified output (ESL .esp + YAML + prompt + sknpack)
│   └── shank_the_bandit_hostile.yaml # Hostile NPC (minimal example)
└── output/                       # Generated plugins land here
```

## Config Reference

See `npc.config.yaml` for inline comments on every field.

### Combat Attitudes

| Attitude | Behavior | AI Packages | Example |
|----------|----------|-------------|---------|
| `friendly` | Won't attack, sandbox AI | DefaultSandboxEditorLink | Merchant, citizen |
| `neutral` | Aggressive if provoked | Sandbox or none | Guard |
| `hostile` | Attacks on sight | None | Bandit, draugr |

### Voice Types

**Always use vanilla voice type references.** Do not create new voice type records. SkyrimNet's TTS system maps voices by FormID — a duped record breaks TTS.

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

- **Edit the Spriggit YAML** in `{PluginName}_spriggit/` and re-serialize — no CK needed
- **Open the .esp in Creation Kit** for advanced edits (appearance, packages, face sculpting)
- **Edit the .prompt file** — tweak personality, speech style, relationships
- **Re-serialize with Spriggit** after CK edits to keep YAML source in sync

## Requirements

- [Spriggit](https://github.com/Mutagen-Modding/Spriggit) 0.40.0 (`dotnet tool install --global Spriggit.Yaml.Skyrim`)
- Skyrim SE with SkyrimNet installed
- Mod Organizer 2 (recommended)

## Out of Scope (MVP)

- Multiple NPCs per plugin
- Papyrus follower scripts
- Sleep AI packages
- Exterior world placement
- Custom voice types
- Quest-driven behavior
