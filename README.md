# Skyrim NPC Template

Config-driven pipeline for generating complete, self-contained, ESL-flagged Skyrim SE NPC plugins with [SkyrimNet](https://github.com/art-from-the-machine/SkyrimNet) AI dialogue support.

## What It Does

Fill in one config file → get a ready-to-install mod folder with:
1. **ESP plugin** (ESL-flagged, Spriggit-generated) — race, stats, voice, outfit, AI, placement
2. **SkyrimNet prompt file** — personality, background, speech style, relationships

```
npc.config.yaml ──► {PluginName}.esp (ESL, compiled)
                ──► {PluginName}_spriggit/ (YAML source, editable)
                ──► characters/grok_800.prompt (SkyrimNet AI)
                ──► {PluginName}.sknpack (world knowledge — NPCs know about Grok)
```

## Quick Start

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
│   ├── grok_the_smith.yaml       # Friendly NPC (full example)
│   └── hostile_bandit.yaml       # Hostile NPC (minimal example)
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
