---
name: lookup-table-extension
description: |-
  Use this when: extend lookup tables, add mod-added records, verify FormIDs, dump factions/voices/outfits/races/locations/headparts/colors/ai_packages/classes, Skyrim DLC coverage, Dawnguard Dragonborn Hearthfires records, modlist FormID verification, xEdit dump scripts, reconcile data yaml
  Contains: xEdit dump workflow, official master scoping, provenance recording, VERIFICATION-STATUS tracking, data/*.yaml reconciliation
  For: extending iNPCForge lookup tables with official DLC or mod-added records so generated NPCs can reference them

  Examples:
  - user: "Add Dawnguard voices to the tables" -> run dump_voices.pas against Dawnguard.esm, reconcile into data/voices.yaml
  - user: "I need a mod-added outfit from Auri.esp" -> run dump script against Auri.esp, add verified entry to the appropriate data table
  - user: "Verify factions table" -> run dump_factions.pas against the source plugin, compare to data/factions.yaml, fix fabrications
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

## Tables And Dump Scripts

| Table | Record Type | Dump Script |
| --- | --- | --- |
| `data/races.yaml` | RACE | `dump_races.pas` |
| `data/voices.yaml` | VTYP | `dump_voices.pas` |
| `data/outfits.yaml` | OTFT | `dump_weapons_misc_outfits.pas` |
| `data/factions.yaml` | FACT | `dump_factions.pas` |
| `data/locations.yaml` | CELL | `dump_cells_whiterun.pas` as a filtered pattern; clone/adapt for other regions |
| `data/ai_packages.yaml` | PACK | `dump_packages.pas` |
| `data/headparts.yaml` | HDPT | `dump_headparts.pas` |
| `data/colors.yaml` | CLFM | `dump_clfm.pas` |
| NPC class references | CLAS | `dump_classes.pas` TODO; no `data/classes.yaml` table yet |

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

Check `data/*.yaml` for the record the NPC config references. If missing or marked `TODO`/`UNVERIFIED`, dump the source plugin.

### 2. Run The Dump Script

```text
xEdit via MO2 -> load target plugin -> right-click plugin -> Apply Script -> select tools/xedit-scripts/<script>.pas -> OK
```

Output appears in the Messages panel. Click in Messages, press Ctrl+A then Ctrl+C, and paste into `_tmp/dumps/<plugin>_<record_type>.tsv` if you need an audit trail.

### 3. Reconcile Into `data/*.yaml`

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

### 4. Record Provenance

For NPCs that use the new entries, `formkey-provenance.yaml` must record `source: xedit-dump` with evidence naming the dump file or xEdit run:

```yaml
outfit_item:
  label: "Auri's Outfit"
  form_key: 000ABC:Auri.esp
  source: xedit-dump
  evidence: "_tmp/dumps/Auri.esp_OTFT.tsv line 42"
```

### 5. Update Verification Status

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
