# Follower-Framework Compat Option

**Date:** 2026-06-19
**Status:** Design — approved

## Problem

Generated NPCs cannot be recruited as followers by NFF, AFT, or similar frameworks without manually adding the `PotentialFollowerFaction` via console or CK.

## Solution

Add an optional `follower` boolean field to the NPC config. When set to `true`, the pipeline includes `PotentialFollowerFaction` (`01540B:Skyrim.esm`) in the NPC's faction list, signaling to follower frameworks that this NPC is recruitable.

## Changes

### 1. Config — new `follower` field

In `npc.config.yaml`, under the `combat_attitude` block:

```yaml
follower: false        # true = add PotentialFollowerFaction for NFF/AFT compatibility
```

When `true` and `combat_attitude` is not `hostile`, the pipeline adds `PotentialFollowerFaction` to the NPC's Faction list at rank 0. Invalid combo `follower: true` + `combat_attitude: hostile` causes the pipeline to skip the faction with a log (or warn).

### 2. Data table — verify PotentialFollowerFaction FormKey

Add to `data/factions.yaml`:

```yaml
PotentialFollowerFaction: 01540B:Skyrim.esm    # TODO: verify via SkyLinkAI or xEdit dump
```

The FormKey `01540B:Skyrim.esm` needs confirmation against a known follower NPC (e.g. Lydia, refId `000A2C8E`) via SkyLinkAI or xEdit faction dump before marking verified.

### 3. Template updates

- `templates/spriggit/npc_base.yaml`: Add `PotentialFollowerFaction` as a documented conditional faction option in the comments section
- Generation logic: When `follower: true` and not hostile, include `PotentialFollowerFaction` rank 0 in the Factions array

### 4. Example updates

- `examples/grok_the_smith.yaml`: Add `follower: false` as reference
- `examples/shank_the_bandit_hostile.yaml`: Add `follower: false` as reference (hostile guard: skipped)

### 5. Documentation

- SKILL.md: Add note under Combat Attitude mapping that `follower: true` adds PotentialFollowerFaction
- AGENTS.md: Mention the optional follower flag in the config reference

## Files Touched

- `npc.config.yaml` — new field + docs
- `data/factions.yaml` — new verified entry
- `templates/spriggit/npc_base.yaml` — updated comments
- `examples/grok_the_smith.yaml` — reference field
- `examples/shank_the_bandit_hostile.yaml` — reference field
- `.opencode/skills/skyrim-npc-template/SKILL.md` — pipeline docs update
- `AGENTS.md` — config reference update
- Generation logic (in agent prompt / generation process) — conditional faction inclusion

## No New FormIDs

`PotentialFollowerFaction` is a vanilla Skyrim.esm reference. Zero new records in the plugin. Zero additional FormID allocation.
