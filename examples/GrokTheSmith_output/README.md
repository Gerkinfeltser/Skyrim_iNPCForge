# Grok the Smith — Complete Worked Example

This is a **fully verified, in-game tested** output from the iNPCForge pipeline.
Grok exists in Skyrim right now — Orc blacksmith at Warmaiden's forge in Whiterun,
sandbox AI, custom Orcish outfit, gruff personality, fully voiced via SkyrimNet.

## What This Demonstrates

Input: [`../grok_the_smith.yaml`](../grok_the_smith.yaml) (single config file)
Output: this folder (complete MO2-ready mod)

## File Reference

| File / Directory | Purpose |
|------|---------|
| `GrokTheSmith.esp` | Compiled plugin — ESL-flagged, 4 records (header + NPC + outfit + placement). Install in MO2. |
| `GrokTheSmith_spriggit/` | Spriggit YAML source — the editable artifact. Re-serialize after edits without Creation Kit. |
| `GrokTheSmith_spriggit/RecordData.yaml` | Mod header with ESL flag (`ModHeader.Flags: [0x200]`). |
| `GrokTheSmith_spriggit/Npcs/` | NPC record: stats, race (OrcRace `013747`), voice (MaleOrc `013AEA`), AI packages, inventory. |
| `GrokTheSmith_spriggit/Outfits/` | Custom OTFT record: Orcish cuirass, boots, gauntlets + blacksmith apron. |
| `GrokTheSmith_spriggit/Cells/0/1/` | Cell override for WhiterunWarmaidens (`01DB4E`) — places Grok at the forge. |
| `SKSE/Plugins/SkyrimNet/prompts/characters/grok_800.prompt` | Personality layer — 10 blocks: background, traits, appearance, speech style, skills. |
| `WorldKnowledge-ManuallyImport/GrokTheSmith.sknpack` | World knowledge — makes other NPCs aware of Grok (Adrianne, Ulfberth, Orc strongholds). |

## Verification (2026-06-13)

- `.esp` loads in Skyrim SE with ESL flag (FormIDs in 0x800–0x802 range)
- Grok appears at Warmaiden's forge, Orc model, Orcish armor, war axe equipped
- Sandbox AI working (sits, wanders, uses forge)
- MaleOrc voice type maps to correct TTS via SkyrimNet
- `grok_800.prompt` loaded — personality present in dialogue
- World knowledge imported — Adrianne Avenicci mentions Grok in conversation
- ESL prefix confirmed: `FE018` in load order

## Installation

1. Copy this entire folder's contents into your MO2 mods directory
2. Enable `GrokTheSmith.esp` in your load order
3. Import `WorldKnowledge-ManuallyImport/GrokTheSmith.sknpack` via SkyrimNet Web UI (`http://localhost:7878`)
4. Travel to Warmaiden's in Whiterun — Grok is at the forge

## Re-serializing After Edits

Edit any YAML in `GrokTheSmith_spriggit/`, then re-serialize:

```powershell
& "$env:USERPROFILE\.dotnet\tools\spriggit.yaml.skyrim.exe" deserialize `
  --InputPath "examples/GrokTheSmith_output/GrokTheSmith_spriggit" `
  --OutputPath "examples/GrokTheSmith_output/GrokTheSmith.esp" `
  --DataFolder "$env:SKYRIM_DATA"
```

No Creation Kit required for YAML-level edits.
