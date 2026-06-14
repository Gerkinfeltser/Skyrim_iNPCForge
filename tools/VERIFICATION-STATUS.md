# FormID Verification Status

Tracking which lookup tables have been verified against live Skyrim records
via xEdit, and what remains.

## Verification Method

All verifications performed by running xEdit Apply Scripts from
`tools/xedit-scripts/` against the live `Skyrim.esm` (or DLC masters) in an
MO2 instance. See that directory's README for usage.

## Status (2026-06-13)

| Table                          | Source              | Status      | Notes |
|--------------------------------|---------------------|-------------|-------|
| `data/voices.yaml`               | Skyrim.esm VTYP     | ✅ VERIFIED | Every FormID corrected; invented EditorIDs removed; race-specific vs generic voices documented |
| `data/outfits.yaml`              | Skyrim.esm OTFT     | ✅ VERIFIED | All FormIDs corrected; outfit EditorIDs now use real names (ArmorOrcishAllOutfit etc.); 80+ outfits covering armor sets, factions, jobs, mages, guilds, nobles |
| `data/races.yaml`                | Skyrim.esm RACE     | ✅ VERIFIED | 6/10 playable race FormIDs were wrong; vampire EditorIDs corrected ({Race}RaceVampire not {Race}VampireRace); 50+ creature races added; GhostRace/BearRace (nonexistent) removed |
| `data/locations.yaml`            | Skyrim.esm CELL     | ✅ VERIFIED | Every FormID was fabricated; 6 EditorIDs wrong (WhiterunBannerMare→BanneredMare etc.); 40+ interior cells verified across all holds |
| `templates/spriggit/outfit_custom.yaml` | Skyrim.esm ARMO     | ✅ VERIFIED | Orcish set FormIDs fixed; ClothingApron → ClothesBlackSmith; reference table with Iron/Steel/Apron verified |
| `examples/grok_the_smith.yaml`   | (derived)           | ✅ FIXED    | ClothingApron → ClothesBlackSmith; outfit_items use Armor* prefix; inventory items verified (OrcishWarAxe 0001398B, Gold001 0000000F) |
| `examples/shank_the_bandit_hostile.yaml`   | (derived)           | ✅ FIXED    | outfit: ArmorHideAllOutfit (0001B3A8); inventory items verified (SteelWarAxe 00013983, Gold001, Lockpick 0000000A) |

## TODO: DLC Coverage

None of the lookup tables include DLC records. To add:

1. **Dawnguard.esm** — Serana's voice, Castle Volkihar cell, Dawnguard armor sets, crossbows
2. **Dragonborn.esm** — Miraak's voice, Raven Rock cells, Stalhrim/Chitin armor sets, Nordic Carved set
3. **Hearthfires.esm** — Buildable player homes (minor; unlikely needed for NPCs)

Process for each:
1. Load the DLC master in xEdit (via MO2)
2. Right-click the DLC node → Apply Script → select the appropriate `dump_*.pas`
3. Paste results here, then append verified entries to the relevant `data/*.yaml`
4. Update this file's status table

## TODO: Additional Scripts Needed

- ~~`dump_factions.pas`~~ — ✅ CREATED `tools/xedit-scripts/dump_factions.pas` — FACT records
- ~~`dump_packages.pas`~~ — ✅ CREATED `tools/xedit-scripts/dump_packages.pas` — PACK records
- `dump_classes.pas` — NPC class records (to verify `Class:` field references in NPC records)

## 2026-06-14: BanditFaction FormID CORRECTION

**BanditFaction FormID was `00033A35` — FABRICATED.** The real FormID is
`0001BCC0:Skyrim.esm`, verified live in-game against a vanilla Bandit NPC
(via SkyLinkAI `get_factions` on refId `00081329`).

Factions were NEVER verified via xEdit (no `dump_factions.pas` existed).
The `dump_weapons_misc_outfits.pas` script only covered OTFT/WEAP/MISC.
New `dump_factions.pas` created — run to enumerate all faction FormIDs.
