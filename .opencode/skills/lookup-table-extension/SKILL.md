---
name: lookup-table-extension
description: |-
  Use this when: extend lookup tables, add mod-added records, verify FormIDs, SkyrimPatcherMCP, dump factions/voices/outfits/races/locations/headparts/colors/ai_packages/classes, Skyrim DLC coverage, Dawnguard Dragonborn Hearthfires records, modlist FormID verification, xEdit dump scripts, reconcile data yaml
  Contains: SkyrimPatcherMCP offline lookup workflow, xEdit dump workflow, official master scoping, provenance recording, VERIFICATION-STATUS tracking, data/*.yaml reconciliation
  For: extending iNPCForge lookup tables with official DLC or mod-added records so generated NPCs can reference them

  Examples:
  - user: "Add Dawnguard voices to the tables" -> run dump_voices.pas against Dawnguard.esm, reconcile into data/voices.yaml
  - user: "I need a mod-added outfit from Auri.esp" -> try SkyrimPatcherMCP search_records for outfit, fall back to xEdit dump if needed
  - user: "Verify factions table" -> use SkyrimPatcherMCP for spot checks or dump_factions.pas for full-table verification
  - user: "Get all DLC records" -> run applicable dump scripts against Dawnguard.esm, Dragonborn.esm, Hearthfires.esm in sequence
  - user: "My modlist adds custom headparts" -> run dump_headparts.pas against the mod plugin, append verified entries
---

# Lookup Table Extension

Extend `data/*.yaml` lookup tables with verified FormIDs from official masters or mod-added plugins. The base repo should cover Skyrim.esm plus official DLC; this skill handles verifying gaps and adding user/modlist-specific records.

## When To Use

- Generated NPC references a mod-added record (gear, cell, faction, voice, headpart) not in `data/*.yaml`
- Filling official DLC coverage gaps (Dawnguard, Dragonborn, Hearthfires)
- Re-verifying an existing table suspected of fabricated FormIDs
- User has a modlist with custom records the base tables do not cover

## Prerequisites

- xEdit (SSEEdit) installed and accessible via MO2
- The plugin containing the target records loaded in the MO2 instance
- `tools/xedit-scripts/` from this repo deployed to xEdit's `Edit Scripts\` folder (see `tools/xedit-scripts/README.md`)
- Optional: SkyrimPatcherMCP built and configured with `MO2_ROOT` pointing at the target MO2 root. Use it for supported offline, load-order-aware lookups before falling back to xEdit dumps.

## Resolution Order

Use the most authoritative available source for the specific record type:

```text
SkyLink AI live lookup -> SkyrimPatcherMCP offline lookup -> Spriggit serialization -> xEdit dump -> verified table -> user-provided
```

- **SkyLink AI** is runtime truth: use it when Skyrim is running and save-state/current-world context matters.
- **SkyrimPatcherMCP** is offline MO2/load-order truth: use it when the record type is supported and Skyrim is closed or unavailable.
- **Spriggit serialization** is plugin-file truth: use `spriggit.yaml.skyrim.exe serialize` on a specific `.esp` when the plugin is accessible and you need complete record YAML without launching Skyrim.
- **xEdit dumps** remain required for unsupported record types and bulk table generation.
- **Verified tables** are the repo baseline and should be enough for common official records once DLC coverage is complete.

## Tables, MCP Support, And Dump Scripts

| Table | Record Type | SkyrimPatcherMCP | Dump Script |
| --- | --- | --- | --- |
| `data/races.yaml` | RACE | `search_records` type `race` | `dump_races.pas` |
| `data/voices.yaml` | VTYP | `search_records` type `voiceType` / `voice` (read-only; sensitive write opt-in for writes) | `dump_voices.pas` |
| `data/outfits.yaml` | OTFT | `search_records` type `outfit` | `dump_weapons_misc_outfits.pas` |
| `data/factions.yaml` | FACT | `search_records` type `faction` | `dump_factions.pas` |
| `data/locations.yaml` | CELL | Not supported by generic record search | `dump_cells_whiterun.pas` as a filtered pattern; clone/adapt for other regions |
| `data/ai_packages.yaml` | PACK | `search_records` type `package` (read-only; sensitive write opt-in for writes) | `dump_packages.pas` |
| `data/headparts.yaml` | HDPT | `search_records` type `headPart` / `hdpt` (read-only; sensitive write opt-in for writes) | `dump_headparts.pas` |
| `data/colors.yaml` | CLFM | `search_records` type `colorRecord` / `color` (read-only; sensitive write opt-in for writes) | `dump_clfm.pas` |
| NPC class references | CLAS | `search_records` type `class` (read-only; sensitive write opt-in for writes) | `dump_classes.pas` TODO; no `data/classes.yaml` table yet |
| Individual armor items | ARMO | `search_records` type `armor` | Add `dump_armors.pas` if a persistent `data/armors.yaml` table is needed |
| Individual weapon items | WEAP | `search_records` type `weapon` | Add `dump_weapons.pas` or extend `dump_weapons_misc_outfits.pas` if needed |

SkyrimPatcherMCP also supports NPC lookup (`recordType: npc`), which is useful for cloned appearances, FaceMorph/TintLayers reference reads, and override-chain inspection even though NPC records are not a lookup table.

Confirmed supported `search_records` types on the `feat-record-search-types` fork: `weapon`, `armor`, `npc`, `race`, `spell`, `perk`, `book`, `ingestible`, `ingredient`, `miscItem`, `ammunition`, `container`, `faction`, `keyword`, `leveledItem`, `leveledNpc`, `magicEffect`, `objectEffect`, `quest`, `light`, `outfit`, `voiceType`, `package`, `headPart`, `colorRecord`, `class`, `constructibleObject`, and `formList`.

## Scoping

The dump scripts process whatever node you right-click. Control scope by selecting the correct node before applying the script.

### Official Masters Only

Right-click each master individually and run the relevant dump script:

1. `Skyrim.esm`
2. `Dawnguard.esm`
3. `Dragonborn.esm`
4. `Hearthfires.esm`

This excludes mod-added records. Output contains only official content for the selected master.

### Single Mod Plugin

Right-click the specific mod plugin (for example `Auri.esp`) and apply the relevant dump script. Output contains records from that plugin only. Use this when an NPC needs a mod-added outfit, voice, faction, cell, or headpart.

### Full Modlist

Right-clicking the top node can include records and overrides from the whole load order. Avoid this for table population because it is noisy and easy to misread. Prefer official-master scope or single-plugin scope.

## Workflow

### 1. Identify The Gap

Check `data/*.yaml` for the record the NPC config references. If missing or marked `TODO`/`UNVERIFIED`, resolve it with SkyLink AI or SkyrimPatcherMCP if supported. Use xEdit dumps for unsupported record types or full-table coverage.

### 2. Try SkyrimPatcherMCP For Supported Types

If SkyrimPatcherMCP is available and the record type is supported, call `search_records` against the target MO2 root/profile. Prefer exact EditorID matches and inspect `definedIn`, `winner`, and `overrideCount` before adding entries. Use `read_record` for one record when you need fields such as HeadParts, HairColor, FaceMorph, FaceParts, TintLayers, HeadTexture, or the winning override source.

Example evidence:

```text
SkyrimPatcherMCP search_records faction BanditFaction in ADT profile -> 01BCC0:Skyrim.esm, winner Unofficial Skyrim Modders Patch.esp
SkyrimPatcherMCP search_records armor Forsworn in ASSOS profile -> ForswornHelmet 0D8D52:Skyrim.esm, winner unofficial skyrim special edition patch.esp
SkyrimPatcherMCP read_record npc 0371D6:Skyrim.esm fromPlugin Skyrim.esm -> Maul's vanilla male Orc FaceMorph/TintLayers reference
```

When using `read_record` for appearance, read from the original plugin (`fromPlugin:"Skyrim.esm"`) if you want vanilla race/sex tint structure, or omit `fromPlugin` if you intentionally want the modlist-winning appearance. Do not blindly copy a reference NPC's skin tint: Maul's male Orc skin base (`#00C6B0A8`, Index 1) rendered pale/Nord-like on Uri. Use the reference for indices/presets, then choose a race-appropriate skin color.

### 3. Run The Dump Script When Needed

```text
xEdit via MO2 -> load target plugin -> right-click plugin -> Apply Script -> select tools/xedit-scripts/<script>.pas -> OK
```

Output appears in the Messages panel. Click in Messages, press Ctrl+A then Ctrl+C, and paste into `_tmp/dumps/<plugin>_<record_type>.tsv` if you need an audit trail.

### 4. Reconcile Into `data/*.yaml`

For each needed record from the dump:

1. Verify the EditorID matches what the NPC config expects.
2. Convert the load-order FormID to master-relative FormKey format.
3. Append to the relevant `data/*.yaml` under the correct section.
4. Mark with a comment if the source is DLC or mod-added.

FormKey format:

| Source | Format |
| --- | --- |
| Skyrim.esm | `XXXXXX:Skyrim.esm` |
| Dawnguard.esm | `XXXXXX:Dawnguard.esm` |
| Dragonborn.esm | `XXXXXX:Dragonborn.esm` |
| Hearthfires.esm | `XXXXXX:Hearthfires.esm` |
| Regular mod | `XXXXXX:ModName.esp` |
| ESL/light mod | `XXXXXX:ModName.esp`; use the object ID after the `FE` load-order prefix |

Use the last six hex digits/object ID for the left side of the FormKey. Do not preserve the runtime load-order index.

### 5. Record Provenance

For NPCs that use the new entries, `formkey-provenance.yaml` must record the source with evidence naming the lookup or dump:

```yaml
outfit_item:
  label: "Auri's Outfit"
  form_key: 000ABC:Auri.esp
  source: xedit-dump
  evidence: "_tmp/dumps/Auri.esp_OTFT.tsv line 42"
```

For SkyrimPatcherMCP lookups, use:

```yaml
faction:
  label: BanditFaction
  form_key: 01BCC0:Skyrim.esm
  source: skyrim-patcher-mcp
  evidence: "search_records faction BanditFaction in ADT profile"
```

### 6. Update Verification Status

After reconciling a table, update `tools/VERIFICATION-STATUS.md`:

- Change status from blank/TODO to `VERIFIED` with date when appropriate
- Note the source plugin and dump script used
- Record any corrections to fabricated entries
- Record partial coverage honestly, e.g. "Dawnguard hair colors only" rather than claiming full DLC coverage

## Adding New Dump Scripts

If no dump script exists for a record type (for example CLAS), create one following `tools/xedit-scripts/README.md` -> "Adding New Scripts". Skeleton:

```pascal
unit dump_<type>;
function Process(e: IInterface): integer;
var sig: string;
begin
  sig := Signature(e);
  if sig = '<SIG>' then
    AddMessage(IntToHex(GetLoadOrderFormID(e), 8) + #9 + EditorID(e) + #9 + Name(e));
  Result := 0;
end;
end.
```

## Critical Rules

- Never invent FormIDs. If a dump fails or a record is missing, stop and ask the user.
- Always record provenance. New table entries must trace back to an xEdit dump, not a guess.
- Mark unverified entries. If an entry cannot be dumped, mark it `TODO` or `UNVERIFIED`.
- DLC entries are additive. Append to existing tables; do not overwrite Skyrim.esm entries.
- Mod-added entries create master dependencies. An NPC referencing `000ABC:Auri.esp` requires Auri.esp as a master. Record this in provenance and generated plugin masters.
