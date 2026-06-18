# Follower Pipeline — Per-NPC Papyrus Follower Framework

**Template/Resource:** [Custom Follower Baseline](https://www.nexusmods.com/skyrimspecialedition/mods/161451) by Aflin (AA01 Papyrus framework — used as reference for the Spriggit templates and script structure)

## Motivation

Generated NPCs currently support only standalone actors (merchants, citizens, bandits). There is no follower behaviour — no hire/dismiss, no wait/follow, no trade, no outfit switching. To make a generated NPC a follower, the user must either install CustomFollowerBase.esp as a master or manually set up the quest/scripts in CK.

## Goal

When an NPC config has `follower: true`, the build pipeline injects a complete Papyrus follower framework into the generated plugin — quest record, dialogue tree, compiled scripts, alias setup — making the NPC fully self-contained with zero external dependencies.

## Approach: Template the AA01 Framework

Rather than duplicating scripts per NPC or relying on an external master, the AA01 quest/dialogue/scripts become Spriggit templates analogous to the existing `templates/spriggit/` files:

### Template Files

```
templates/spriggit/follower/
├── follower_quest.yaml          # Quest record (AA01FollowerController equivalent)
├── follower_dialogue.yaml       # Dialogue topic/info branches (recruit, wait, follow, trade, dismiss, outfit, combat style, home, rest)
├── follower_scenes.yaml         # Bleedout, get-healed, player-death scenes
├── follower_outfit.yaml         # Custom container + OTFT records
├── follower_aliases.yaml        # ReferenceAlias records (follower, player)
└── follower_factions.yaml       # DismissedFollower, CurrentHireling factions
```

### Scripts

The 6 core `.psc` scripts (AA01FollowerController, AA01FollowerQuestAliasScript, AA01BleedoutLinesScript, AA01PlayerDeathScript, AA01OutfitController, AA01CustomContainerScript) live in a `templates/scripts/` directory as vanilla Papyrus source. On build:

1. Inject quest + dialogue records from Spriggit templates
2. Copy `.pex` (pre-compiled) or `.psc` (source) into output `Scripts/` folder
3. Wire the NPC as the FollowerAlias in the quest

### Per-NPC Customisation Opportunities

- Bleedout lines (per-NPC dialogue in the bleedout scene)
- Default outfit toggle
- Combat style preferences
- Home marker default

## Credits

- **[Custom Follower Baseline](https://www.nexusmods.com/skyrimspecialedition/mods/161451)** by Aflin — AA01 Papyrus follower framework used as template/reference for the Spriggit script and dialogue records.
- **[SkyLink AI](https://www.nexusmods.com/skyrimspecialedition/mods/175682)** by JarvannDarr — SKSE MCP server providing real-time Skyrim engine access for FormKey resolution and runtime verification.
- **[xEdit](https://tes5edit.github.io/)** — Plugin record inspection and load-order FormID verification.
- **[SkyrimNet-GamePlugin](https://github.com/MinLL/SkyrimNet-GamePlugin)** by MinLL — AI dialogue runtime for generated prompt files.

See `README.md` for the master credits list.

## Out of Scope (This Request)

- Marriage quests
- Quest-driven follower behaviour
- Multi-follower systems (UFO, AFT-style)
- Commentary / location-aware lines
- SkyrimNet integration with follower state
