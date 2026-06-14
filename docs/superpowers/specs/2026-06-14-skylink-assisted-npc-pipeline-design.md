# SkyLink-Assisted NPC Pipeline Design

## Purpose

This design replaces ad hoc NPC generation with a gated workflow that prefers live SkyLinkAI lookup, records provenance for every resolved FormKey, and refuses to invent Skyrim record IDs. It keeps the existing offline lookup-table workflow, but treats it as fallback/cache rather than the first source of truth when live game data is available.

## Goals

- Make NPC generation repeatable from interview through runtime test.
- Prefer live SkyLinkAI resolution for FormKeys, especially mod-added records.
- Stop instead of guessing when records cannot be verified.
- Track where every external FormKey came from.
- Verify SkyrimNet prompt and world-knowledge artifacts before runtime testing.
- Keep Skyrim state requirements explicit: running for live resolution, closed for ESP rebuild.

## Non-Goals

- Replace xEdit as the authoritative bulk-dump tool.
- Require SkyLinkAI for every build when verified offline tables are sufficient.
- Build a full GUI wizard.
- Support exterior placement or multi-NPC plugins in the MVP.
- Automatically edit or trust unverified global lookup tables without provenance.
- Generate captured face morphs or FaceGen mesh/texture assets in the first implementation pass.

## Pipeline Overview

1. Interview the user with a numbered question form.
2. Draft `npc.config.yaml` from intent-level answers.
3. Resolve FormKeys with SkyLinkAI first when available.
4. Fall back to xEdit dumps or verified `data/*.yaml` tables when live lookup is unavailable.
5. Stop and ask the user when a record cannot be verified.
6. Write per-output FormKey provenance.
7. Ask the user to close Skyrim before building.
8. Generate Spriggit YAML and SkyrimNet artifacts.
9. Deserialize to an ESL-flagged ESP.
10. Run offline verification.
11. Load Skyrim and perform runtime testing.

## Interview Gate

The pipeline starts with a numbered form so the user can answer in one block. Follow-up questions are only for missing required answers, contradictions, or resolution blockers.

Initial required form:

```text
1. NPC name:
2. Plugin name:
3. Race/species:
4. Voice style or vanilla voice type:
5. Combat attitude: friendly / neutral / hostile
6. Placement location:
7. Outfit/clothing/armor:
8. Weapons/inventory:
9. Personality summary:
10. Backstory/origin:
11. Speech style:
12. Relationships/factions:
13. World knowledge: yes/no, and who should know about them?
14. Any mod-added gear, location, faction, or voice? If yes, is Skyrim + SkyLinkAI available for lookup?
15. Appearance basics: sex, height, weight/build, hair, eyes, scars/warpaint, or other visible head details?
```

Rules:

- The user may answer with numbers only.
- Optional answers may be blank.
- Required blanks or contradictions trigger targeted follow-up questions.
- The question bank is expandable as real failures reveal missing inputs.
- Each question maps to config fields or FormKey resolution tasks.

## Question Bank Structure

Store question-bank guidance in the skill as structured entries:

```yaml
- id: outfit_concept
  status: required
  question: "What should this NPC wear or carry?"
  maps_to: ["outfit", "outfit_items", "inventory"]
  resolution: "SkyLinkAI first for name-based or mod-added records; verified tables as fallback."
```

Each entry should have:

- `id`: stable identifier for future references.
- `status`: `required`, `conditional`, or `optional`.
- `question`: user-facing prompt.
- `maps_to`: config fields or artifact outputs.
- `resolution`: how unresolved values should be verified.

## Resolution Gate

SkyLinkAI is the preferred source of truth when available.

Resolution priority:

```text
skylink-live > xedit-dump > verified-table > user-provided
```

Process:

1. Check whether Skyrim is running:

```powershell
Get-Process SkyrimSE -ErrorAction SilentlyContinue
```

2. If Skyrim is not running and unresolved records require live lookup, stop and tell the user:

```text
Start Skyrim with SkyLinkAI loaded, then tell me when it's ready.
```

3. If Skyrim is running, call SkyLinkAI `check_connection`.
4. If SkyLinkAI is connected, resolve records with live tools such as `search_forms`, `get_cell_info`, `get_load_order`, and `get_mod_form_id_prefix`.
5. If SkyLinkAI cannot resolve the record, use xEdit dump scripts for bulk or authoritative checks.
6. If xEdit is unavailable, fall back to verified `data/*.yaml` tables.
7. If no source can verify the record, stop and ask the user to start Skyrim/SkyLinkAI, choose a known table option, provide a FormKey, or defer the detail.

## No Guessing Rule

The pipeline must never invent FormKeys, voice types, factions, packages, cells, outfits, or item IDs. If a record cannot be resolved by SkyLinkAI, xEdit, or a verified table, generation stops until the user chooses a verified path.

Accepting a user-provided FormKey is allowed, but it must be marked as `user-provided` and should remain a warning or strict-mode failure until verified later.

## Provenance

Each generated output should include a provenance file:

```text
output/{PluginName}/formkey-provenance.yaml
```

Example shape:

```yaml
plugin: GrokTheSmith
records:
  race:
    label: OrcRace
    form_key: 013747:Skyrim.esm
    source: skylink-live
    evidence: "SkyLinkAI search_forms race OrcRace"
  voice:
    label: MaleOrc
    form_key: 013AEA:Skyrim.esm
    source: verified-table
    evidence: data/voices.yaml
  outfit_item:
    label: "Wayfarer's Skirt"
    form_key: 000ABC:WayfarerMod.esp
    source: skylink-live
    evidence: "SkyLinkAI search_forms armor Wayfarer's Skirt"
```

The verifier should accept `skylink-live`, `xedit-dump`, and `verified-table` records. It should warn or fail on `user-provided` depending on strictness.

## Appearance Scope

Appearance support is split into tiers so the MVP improves useful visible customization without pretending to solve Skyrim's full FaceGen pipeline immediately.

In scope for the first implementation plan:

- **Tier 1: Body basics** — race, sex, height, weight/build, outfit, visible armor/clothing, and carried equipment. These map cleanly to existing or near-existing NPC record fields and generated outfit/inventory data.
- **Tier 2: Headpart choices** — hair, eyes, brows, scars, warpaint/tints, and other selectable head parts when they can be resolved to real FormKeys through SkyLinkAI, xEdit, or verified tables. These require new config fields and Spriggit template coverage, but do not require captured morph generation.

Backlog for later work:

- **Tier 3: Captured face morphs** — use SkyLinkAI `get_appearance` or a similar source to capture face morph values and translate them into generated NPC face data.
- **Tier 4: FaceGen assets** — generate or import the required face mesh/texture assets for fully custom heads. This likely needs Creation Kit, xEdit, RaceMenu, or a dedicated FaceGen export/import workflow.

The interview should ask for Tier 1 and Tier 2 appearance details up front. If the user asks for a sculpted/captured face, record it as backlog unless the dedicated appearance pipeline has been implemented.

## Build Gate

Skyrim should be closed before Spriggit deserialization.

Before building, check:

```powershell
Get-Process SkyrimSE -ErrorAction SilentlyContinue
```

If Skyrim is running, stop and tell the user:

```text
Close Skyrim before I rebuild the ESP, then tell me when it's closed.
```

Then generate Spriggit YAML with fixed MVP allocation:

```text
0x800 NPC base
0x801 PlacedNpc REFR
0x802 Custom OTFT if needed
0x803+ additional records
```

The prompt filename suffix comes from the PlacedNpc REFR FormID. With the fixed allocation, the prompt filename is `{sanitized_name}_801.prompt`.

## Deserialize Gate

Deserialize with Spriggit using `$env:SKYRIM_DATA`:

```powershell
& "$env:USERPROFILE\.dotnet\tools\spriggit.yaml.skyrim.exe" deserialize `
  --InputPath "output\{PluginName}_spriggit" `
  --OutputPath "output\{PluginName}\{PluginName}.esp" `
  --DataFolder "$env:SKYRIM_DATA"
```

The ESP should be ESL-flagged by `ModHeader.Flags: [0x200]` in `RecordData.yaml`.

## Offline Verification Gate

Run:

```powershell
.\tools\verify_prompt.ps1 -OutputDir .\output\{PluginName}
```

The verifier should check:

- Prompt filename matches the actual PlacedNpc REFR suffix.
- Character prompt exists under `SKSE/Plugins/SkyrimNet/prompts/characters/`.
- Character prompt uses Jinja `{% block %}` format.
- Required prompt blocks exist:
  - `summary`
  - `personality`
  - `appearance`
  - `background`
  - `occupation`
  - `skills`
  - `relationships`
  - `aspirations`
  - `speech_style`
  - `interject_summary`
- Prompt artifacts do not contain obvious placeholders such as `TODO`, `TBD`, or unresolved template values.
- `.sknpack` exists when `world_knowledge.entries` is non-empty.
- `.sknpack` structure is importable by SkyrimNet.
- World-knowledge entries include `display_name`, `content`, `type`, `importance`, `condition_expr`, `always_inject`, and `tags`.
- External FormKeys are backed by provenance or verified lookup tables.
- Lookup entries marked `TODO` or `UNVERIFIED` do not count as verified.

## Runtime Test Gate

After successful offline verification, the user launches Skyrim again. Runtime test should confirm:

- NPC appears at the expected placement.
- Outfit, weapons, and inventory match the design.
- Factions and hostility/friendly behavior work.
- Prompt filename is `{sanitized_name}_801.prompt`.
- SkyrimNet loads the bio/personality.
- World knowledge imports and surfaces as configured.

Use SkyLinkAI for runtime inspection when available.

## MCP Skill Preflights

SkyLinkAI skill preflight:

1. Check `Get-Process SkyrimSE -ErrorAction SilentlyContinue`.
2. If absent, ask the user to start Skyrim with SkyLinkAI loaded.
3. If present, call `check_connection`.
4. Do not run SkyLinkAI commands until the check passes.

SkyrimNet skill preflight:

1. Check `Get-Process SkyrimSE -ErrorAction SilentlyContinue`.
2. If absent, ask the user to start Skyrim with SkyrimNet running.
3. If present, verify the MCP/SSE runtime is reachable.
4. If SkyrimNet exposes an exe/runtime health tool, prefer that as the readiness check.

## Error Handling

- Missing live lookup: stop and ask the user to start Skyrim/SkyLinkAI.
- Unresolved record: stop and present choices instead of guessing.
- User-provided FormKey: record provenance and warn until verified.
- Skyrim running during build: stop and ask user to close Skyrim.
- Verifier failure: fix artifacts or provenance before runtime testing.
- Runtime mismatch: inspect with SkyLinkAI, correct YAML/config, rebuild with Skyrim closed.

## Implementation Impact

- Update `.opencode/skills/skyrim-npc-template/SKILL.md` with the gated pipeline, numbered interview form, SkyLinkAI-first resolution, provenance rules, and build/test gates.
- Extend `tools/verify_prompt.ps1` to validate required prompt blocks, placeholders, `.sknpack` structure, and provenance-backed FormKeys.
- Add provenance file generation to the NPC generation workflow.
- Keep `data/*.yaml` as verified fallback/cache tables, not as a license to invent records.
- Keep xEdit scripts for bulk verification and lookup-table promotion.

## Design Decisions

- `user-provided` FormKeys warn by default and fail only in strict mode. This keeps the workflow usable when the user has reliable external information, while still making unverified data visible.
- `formkey-provenance.yaml` v1 uses a top-level `plugin` field and a `records` map. Each record entry must include `label`, `form_key`, `source`, and `evidence`. Optional fields may include `record_type`, `plugin`, `runtime_form_id`, and `notes`.
- `.sknpack` validation v1 checks file presence, parseability, and required fields for every generated world-knowledge entry. Runtime import success remains part of the runtime test gate because SkyrimNet import behavior is the final authority.
