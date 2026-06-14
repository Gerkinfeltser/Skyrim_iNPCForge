# SkyLink-Assisted NPC Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the SkyLinkAI-first NPC generation workflow described in `docs/superpowers/specs/2026-06-14-skylink-assisted-npc-pipeline-design.md`.

**Architecture:** This repo is a template/recipe project, not an application. Implementation primarily updates the authoritative skill, config examples, Spriggit templates, verification script, and documentation so future NPC generation follows a gated workflow: numbered interview, SkyLinkAI-first FormKey resolution, provenance, build-state checks, artifact verification, and Tier 1/Tier 2 appearance support.

**Tech Stack:** Markdown skills/docs, YAML config/templates, PowerShell verifier, Spriggit YAML conventions, SkyrimNet prompt/sknpack artifacts, SkyLinkAI/xEdit workflow notes.

---

## Delegation Guide

- **Fast/less-smart agent OK:** mechanical docs edits, example comment updates, simple YAML field additions, straightforward string checks in `verify_prompt.ps1` after exact requirements are specified.
- **Smart agent required:** verifier/provenance logic, `.sknpack` validation, any change that interprets Skyrim/Spriggit/FormKey semantics, and final review of the full pipeline for contradictions.
- **Do not delegate blindly:** anything involving invented FormIDs, FaceGen claims, SkyrimNet prompt loading semantics, or REFR/base FormID naming rules.

## File Structure

- Modify `.opencode/skills/skyrim-npc-template/SKILL.md`: authoritative workflow, numbered interview form, SkyLinkAI-first resolution, provenance, appearance tiers, build/test gates.
- Modify `AGENTS.md`: concise repo-level summary matching the skill, including live resolution and provenance rules.
- Modify `npc.config.yaml`: add commented Tier 1/Tier 2 appearance fields and clarify intent-first values before resolution.
- Modify `examples/grok_the_smith.yaml`: align example comments/fields with new appearance and provenance-capable workflow.
- Modify `examples/WIP-shank_the_bandit_hostile.yaml`: same as Grok, ensuring hostile NPCs retain prompt/personality requirements.
- Modify `templates/spriggit/npc_base.yaml`: add supported Tier 1 appearance mappings if missing, and placeholders/comments for Tier 2 headpart fields only when backed by actual Spriggit fields.
- Modify `tools/verify_prompt.ps1`: required prompt block validation, placeholder scanning, `.sknpack` validation, provenance file loading, and FormKey acceptance rules.
- Add `output/{PluginName}/formkey-provenance.yaml` generation instructions to the skill; do not add generated output files unless updating existing examples intentionally.
- Optionally add `templates/provenance/formkey-provenance.yaml`: a reusable provenance template if the skill needs concrete file shape.

## Task 1: Update Authoritative Skill Workflow

**Model requirement:** Smart agent required. This file is the canonical recipe and subtle wording mistakes caused previous runtime failures.

**Files:**
- Modify: `.opencode/skills/skyrim-npc-template/SKILL.md`
- Reference: `docs/superpowers/specs/2026-06-14-skylink-assisted-npc-pipeline-design.md`

- [ ] **Step 1: Read the current skill and design spec**

Run:

```powershell
Get-Content .\.opencode\skills\skyrim-npc-template\SKILL.md -Raw
Get-Content .\docs\superpowers\specs\2026-06-14-skylink-assisted-npc-pipeline-design.md -Raw
```

Expected: current skill content and design spec are visible. Do not edit before reading both.

- [ ] **Step 2: Add the numbered interview form**

Insert an `Interview Gate` section near the start of the workflow, before config generation. Use this exact form:

````markdown
## Interview Gate

Start every new NPC with this numbered form. The user may answer with numbers only. Ask follow-up questions only for missing required answers, contradictions, or unresolved FormKey needs.

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
````

Expected: the form is present exactly once and is placed before generation steps.

- [ ] **Step 3: Add SkyLinkAI-first resolution gate**

Add this resolution priority and stop rule to the skill:

````markdown
## FormKey Resolution Gate

Resolution priority:

```text
skylink-live > xedit-dump > verified-table > user-provided
```

Before live lookup, check Skyrim:

```powershell
Get-Process SkyrimSE -ErrorAction SilentlyContinue
```

If Skyrim is not running and unresolved records require live lookup, stop and say: "Start Skyrim with SkyLinkAI loaded, then tell me when it's ready."

If Skyrim is running, use SkyLinkAI `check_connection` before other SkyLinkAI commands. Use `search_forms`, `get_cell_info`, `get_load_order`, and `get_mod_form_id_prefix` for live resolution. Never invent FormKeys.
````

Expected: the skill clearly says SkyLinkAI is first source of truth when available, verified tables are fallback/cache, and unresolved records stop generation.

- [ ] **Step 4: Add build-state gates**

Add this rule before Spriggit deserialization:

````markdown
## Build State Gate

Skyrim should be closed before Spriggit deserialization. Before building, run:

```powershell
Get-Process SkyrimSE -ErrorAction SilentlyContinue
```

If Skyrim is running, stop and say: "Close Skyrim before I rebuild the ESP, then tell me when it's closed."
````

Expected: the skill distinguishes Skyrim-running-for-resolution from Skyrim-closed-for-build.

- [ ] **Step 5: Add provenance requirements**

Add a `FormKey Provenance` section with this v1 schema:

```yaml
plugin: GrokTheSmith
records:
  race:
    label: OrcRace
    form_key: 013747:Skyrim.esm
    source: skylink-live
    evidence: "SkyLinkAI search_forms race OrcRace"
```

Required per record: `label`, `form_key`, `source`, `evidence`.

Allowed sources: `skylink-live`, `xedit-dump`, `verified-table`, `user-provided`.

Expected: the skill instructs generation to write `output/{PluginName}/formkey-provenance.yaml`.

- [ ] **Step 6: Add appearance scope**

Add this appearance tier summary:

```markdown
## Appearance Scope

In scope now:
- Tier 1: race, sex, height, weight/build, outfit, visible armor/clothing, carried equipment.
- Tier 2: hair, eyes, brows, scars, warpaint/tints, and other selectable headparts when resolvable to real FormKeys.

Backlog:
- Tier 3: captured face morph values from SkyLinkAI `get_appearance`.
- Tier 4: FaceGen mesh/texture generation or import.
```

Expected: no claim that Tier 3/Tier 4 is implemented.

- [ ] **Step 7: Verify skill consistency**

Run:

```powershell
Select-String -Path .\.opencode\skills\skyrim-npc-template\SKILL.md -Pattern "grok_800|shank_800|NPC BASE record FormID|skip personality|00033A35|TODO|TBD"
```

Expected: no matches except legitimate historical warning text if clearly marked as wrong. If any old incorrect instruction appears, remove or correct it.

- [ ] **Step 8: Commit Task 1**

Run:

```powershell
git add .\.opencode\skills\skyrim-npc-template\SKILL.md
git commit -m "Update NPC template skill workflow gates"
```

Expected: commit succeeds.

## Task 2: Sync Repo-Level Documentation

**Model requirement:** Fast/less-smart agent OK if Task 1 is complete; smart review recommended.

**Files:**
- Modify: `AGENTS.md`

- [ ] **Step 1: Read `AGENTS.md` and updated skill**

Run:

```powershell
Get-Content .\AGENTS.md -Raw
Get-Content .\.opencode\skills\skyrim-npc-template\SKILL.md -Raw
```

Expected: both files visible for consistency check.

- [ ] **Step 2: Add concise pipeline summary**

Add or update the pipeline section in `AGENTS.md` so it says:

````markdown
## SkyLink-Assisted Workflow

For new NPCs, use the numbered interview form in the skill, then resolve FormKeys with this priority:

```text
skylink-live > xedit-dump > verified-table > user-provided
```

SkyLinkAI is preferred for live FormKey resolution, especially mod-added gear, cells, factions, voices, and headparts. If Skyrim/SkyLinkAI is unavailable and a record is not in verified tables, stop and ask the user to start Skyrim, choose a known option, or provide a FormKey. Do not invent IDs.
````

Expected: AGENTS.md points to the skill for details and does not duplicate the whole spec.

- [ ] **Step 3: Add appearance scope summary**

Add this concise note near conventions or out-of-scope:

```markdown
Appearance MVP supports Tier 1 body basics and Tier 2 selectable headparts when FormKeys can be verified. Captured face morphs and FaceGen mesh/texture assets are backlog.
```

Expected: no unsupported promise of FaceGen generation.

- [ ] **Step 4: Verify old bad claims are absent**

Run:

```powershell
Select-String -Path .\AGENTS.md -Pattern "grok_800|shank_800|NPC BASE record FormID|skip personality|00033A35|TODO|TBD"
```

Expected: no stale bad guidance.

- [ ] **Step 5: Commit Task 2**

Run:

```powershell
git add .\AGENTS.md
git commit -m "Sync repo docs with SkyLink-assisted workflow"
```

Expected: commit succeeds.

## Task 3: Extend Config And Examples For Appearance

**Model requirement:** Fast/less-smart agent OK for comments/fields; smart review required before commit because YAML examples are user-facing.

**Files:**
- Modify: `npc.config.yaml`
- Modify: `examples/grok_the_smith.yaml`
- Modify: `examples/WIP-shank_the_bandit_hostile.yaml`

- [ ] **Step 1: Read config and examples**

Run:

```powershell
Get-Content .\npc.config.yaml -Raw
Get-Content .\examples\grok_the_smith.yaml -Raw
Get-Content .\examples\WIP-shank_the_bandit_hostile.yaml -Raw
```

Expected: current YAML fields are visible.

- [ ] **Step 2: Add Tier 1 appearance fields to `npc.config.yaml`**

Add this block after `respawn`:

```yaml
# --- Appearance (Tier 1: body basics) ---
sex: "male"                           # male | female
height: 1.0                            # Vanilla scale. 1.0 = normal height.
weight: 100                            # 0-100 body weight/build slider.
```

Expected: comments clearly say these are Tier 1 basics.

- [ ] **Step 3: Add Tier 2 appearance comments to `npc.config.yaml`**

Add this commented block below Tier 1:

```yaml
# --- Appearance (Tier 2: selectable headparts; optional) ---
# Resolve these through SkyLinkAI/xEdit/verified tables before generation.
# hair: ""
# eyes: ""
# brows: ""
# scar: ""
# warpaint: ""
```

Expected: Tier 2 fields are documented but optional.

- [ ] **Step 4: Add matching fields to Grok example**

Set Grok to male, height 1.0, weight 100. Add Tier 2 comments but leave them blank unless already verified.

Expected YAML snippet:

```yaml
sex: "male"
height: 1.0
weight: 100
# hair: ""
# eyes: ""
# brows: ""
# scar: ""
# warpaint: ""
```

- [ ] **Step 5: Add matching fields to Shank example**

Set Shank to male, height 1.0, weight 75 unless the existing concept says otherwise. Add Tier 2 comments but leave them blank unless verified.

Expected YAML snippet:

```yaml
sex: "male"
height: 1.0
weight: 75
# hair: ""
# eyes: ""
# brows: ""
# scar: ""
# warpaint: ""
```

- [ ] **Step 6: Validate YAML parse shape manually**

Run if PowerShell has a YAML parser unavailable, perform a structural check by reading files and confirming indentation. If `yq` exists, run:

```powershell
yq e . .\npc.config.yaml
yq e . .\examples\grok_the_smith.yaml
yq e . .\examples\WIP-shank_the_bandit_hostile.yaml
```

Expected: YAML parses successfully if `yq` is available; otherwise no obvious indentation errors after inspection.

- [ ] **Step 7: Commit Task 3**

Run:

```powershell
git add .\npc.config.yaml .\examples\grok_the_smith.yaml .\examples\WIP-shank_the_bandit_hostile.yaml
git commit -m "Add appearance fields to NPC configs"
```

Expected: commit succeeds.

## Task 4: Update Spriggit NPC Template For Tier 1 Appearance

**Model requirement:** Smart agent required. This touches generated record semantics.

**Files:**
- Modify: `templates/spriggit/npc_base.yaml`
- Reference: existing generated NPC YAML under `output/GrokTheSmith/GrokTheSmith_spriggit/Npcs/`

- [ ] **Step 1: Read template and generated NPC example**

Run:

```powershell
Get-Content .\templates\spriggit\npc_base.yaml -Raw
Get-ChildItem .\output\GrokTheSmith\GrokTheSmith_spriggit\Npcs
Get-Content .\output\GrokTheSmith\GrokTheSmith_spriggit\Npcs\*.yaml -Raw
```

Expected: confirm current generated fields include `Height` and `Weight`, and determine whether sex is currently modeled.

- [ ] **Step 2: Wire height and weight to config if not already dynamic**

Ensure template contains values driven by config fields:

```yaml
Height: {{ appearance.height | default(1.0) }}
Weight: {{ appearance.weight | default(50) }}
```

If the template engine does not use an `appearance` object, use existing config variable style and map `height` and `weight` directly. Do not invent syntax; match the existing template style exactly.

Expected: generated NPC can vary height and weight from config.

- [ ] **Step 3: Handle sex only if Spriggit field is already known**

Search existing YAML for sex/female flags:

```powershell
Select-String -Path .\output\*\*_spriggit\Npcs\*.yaml -Pattern "Female|Sex|Configuration|Flags"
```

If a clear existing field exists, add the mapping. If not, leave `sex` as config-only for now and document that Spriggit sex mapping still needs xEdit/Spriggit verification.

Expected: no guessed sex field is added.

- [ ] **Step 4: Do not add Tier 2 headpart fields unless known**

If no verified Spriggit headpart/tint structure exists in current examples, add only comments in the skill/config and do not modify template for hair/eyes/brows/scars/warpaint yet.

Expected: plan preserves Tier 2 as config/resolution-ready without fabricating record structure.

- [ ] **Step 5: Commit Task 4**

Run:

```powershell
git add .\templates\spriggit\npc_base.yaml .\.opencode\skills\skyrim-npc-template\SKILL.md
git commit -m "Wire Tier 1 appearance into NPC template"
```

Expected: commit succeeds. If no template change was safe, commit only the documentation note explaining why sex/headparts are deferred until verified.

## Task 5: Add Provenance Template And Skill Instructions

**Model requirement:** Fast/less-smart agent OK for template creation; smart review required for source acceptance rules.

**Files:**
- Create: `templates/provenance/formkey-provenance.yaml`
- Modify: `.opencode/skills/skyrim-npc-template/SKILL.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: Create provenance template**

Create `templates/provenance/formkey-provenance.yaml` with:

```yaml
plugin: "{{ plugin_name }}"
records:
  # record_key:
  #   label: "Human-readable source label"
  #   form_key: "000000:Skyrim.esm"
  #   source: "skylink-live" # skylink-live | xedit-dump | verified-table | user-provided
  #   evidence: "Tool, file, or user statement used as evidence"
  #   record_type: "optional record category"
  #   plugin: "optional source plugin"
  #   runtime_form_id: "optional runtime FormID from live game"
  #   notes: "optional notes"
```

Expected: template is comments-only except top-level shape.

- [ ] **Step 2: Add generation instruction to skill**

In `.opencode/skills/skyrim-npc-template/SKILL.md`, add a step after FormKey resolution:

```markdown
Generate `output/{PluginName}/formkey-provenance.yaml` from `templates/provenance/formkey-provenance.yaml`. Every external FormKey used by generated Spriggit YAML must have a provenance entry unless it is plugin-local.
```

Expected: skill requires provenance before build.

- [ ] **Step 3: Add source acceptance rules**

Add:

```markdown
Accepted sources: `skylink-live`, `xedit-dump`, `verified-table`.
`user-provided` is allowed but should warn by default and fail in strict verification mode.
Entries marked `TODO` or `UNVERIFIED` in lookup tables do not count as verified.
```

Expected: no ambiguity about TODO lookup rows.

- [ ] **Step 4: Commit Task 5**

Run:

```powershell
git add .\templates\provenance\formkey-provenance.yaml .\.opencode\skills\skyrim-npc-template\SKILL.md .\AGENTS.md
git commit -m "Add FormKey provenance template"
```

Expected: commit succeeds.

## Task 6: Extend Prompt Verification

**Model requirement:** Smart agent required. PowerShell parser mistakes already happened; review carefully.

**Files:**
- Modify: `tools/verify_prompt.ps1`
- Test with: `output/GrokTheSmith`, `output/ShankTheBandit`

- [ ] **Step 1: Read verifier**

Run:

```powershell
Get-Content .\tools\verify_prompt.ps1 -Raw
```

Expected: understand current functions before editing.

- [ ] **Step 2: Add required prompt block list**

Add near the top after `$issues = @()` or equivalent initialization:

```powershell
$requiredPromptBlocks = @(
    "summary",
    "personality",
    "appearance",
    "background",
    "occupation",
    "skills",
    "relationships",
    "aspirations",
    "speech_style",
    "interject_summary"
)
```

Expected: exact block names match `templates/prompt/character.prompt`.

- [ ] **Step 3: Add block completeness check**

After existing prompt block-format check, add:

```powershell
foreach ($blockName in $requiredPromptBlocks) {
    $pattern = "{%\s*block\s+$([regex]::Escape($blockName))\s*%}"
    if ($content -match $pattern) {
        Write-Host "[PASS] Prompt block '$blockName' exists" -ForegroundColor Green
    }
    else {
        Write-Host "[FAIL] Prompt block '$blockName' missing" -ForegroundColor Red
        $issues += "MISSING_PROMPT_BLOCK"
    }
}
```

Expected: missing individual blocks fail verification.

- [ ] **Step 4: Add placeholder scan**

Add this after block checks:

```powershell
$placeholderPatterns = @("TODO", "TBD", "\{\{\s*npc\.", "\{\{\s*[^}]+\s*\}\}")
foreach ($placeholderPattern in $placeholderPatterns) {
    if ($content -match $placeholderPattern) {
        Write-Host "[FAIL] Prompt contains unresolved placeholder pattern: $placeholderPattern" -ForegroundColor Red
        $issues += "PROMPT_PLACEHOLDER"
    }
}
```

Expected: unresolved placeholders fail verification. If legitimate SkyrimNet runtime placeholders like `{{player.name}}` are present in prompts, narrow the regex to allow `player.*` and fail only unknown placeholders.

- [ ] **Step 5: Test prompt checks**

Run:

```powershell
& .\tools\verify_prompt.ps1 -OutputDir .\output\ShankTheBandit
& .\tools\verify_prompt.ps1 -OutputDir .\output\GrokTheSmith
```

Expected: Shank passes prompt block checks. Grok may still fail on unverified package if `data/ai_packages.yaml` remains TODO; that is acceptable and should be noted.

- [ ] **Step 6: Commit Task 6**

Run:

```powershell
git add .\tools\verify_prompt.ps1
git commit -m "Verify required SkyrimNet prompt blocks"
```

Expected: commit succeeds.

## Task 7: Add Provenance-Aware FormKey Verification

**Model requirement:** Smart agent required. This is core verification logic.

**Files:**
- Modify: `tools/verify_prompt.ps1`
- Create or use sample: temporary provenance files under `_tmp/` only if needed; do not commit `_tmp/`.

- [ ] **Step 1: Add provenance loader**

Add a function that reads `formkey-provenance.yaml` if present. Because PowerShell 5.1 has no built-in YAML parser, implement minimal line-based parsing for v1 shape or require provenance values also be checked by regex.

Minimal acceptable function:

```powershell
function Load-ProvenanceFormKeys {
    param([string]$Path)
    $keys = @{}
    if (-not (Test-Path $Path)) { return $keys }

    $currentFormKey = $null
    $currentSource = $null
    foreach ($line in Get-Content $Path) {
        $trimmed = $line.Trim()
        if ($trimmed -match "^form_key:\s*['\"]?([^'\"#]+)") {
            $currentFormKey = $Matches[1].Trim()
        }
        elseif ($trimmed -match "^source:\s*['\"]?([^'\"#]+)") {
            $currentSource = $Matches[1].Trim()
        }

        if ($currentFormKey -and $currentSource) {
            $keys[(Normalize-FormKey $currentFormKey)] = $currentSource
            $currentFormKey = $null
            $currentSource = $null
        }
    }

    return $keys
}
```

Expected: the loader returns normalized FormKey to source mappings.

- [ ] **Step 2: Load provenance file**

After `$promptPath` is known, add:

```powershell
$provenancePath = Join-Path $OutputDir "formkey-provenance.yaml"
$provenanceKeys = Load-ProvenanceFormKeys $provenancePath
```

Expected: verifier can accept per-output provenance.

- [ ] **Step 3: Update `Test-VerifiedFormKey`**

Change `Test-VerifiedFormKey` to accept an extra hashtable parameter `$ProvenanceKeys`. Acceptance order:

1. plugin-local with `-AllowPluginLocal`: pass
2. verified table: pass
3. provenance source `skylink-live`, `xedit-dump`, or `verified-table`: pass
4. provenance source `user-provided`: warn by default and add `USER_PROVIDED_FORMKEY` warning, not fatal unless strict mode exists
5. otherwise fail

Expected: modded SkyLinkAI-resolved FormKeys can pass without being promoted into global `data/*.yaml`.

- [ ] **Step 4: Add optional `-Strict` switch**

Update param block:

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$OutputDir,
    [switch]$Fix,
    [switch]$Strict
)
```

In strict mode, `user-provided` provenance should add a fatal issue.

Expected: default mode warns on user-provided, strict mode fails.

- [ ] **Step 5: Test without provenance**

Run:

```powershell
& .\tools\verify_prompt.ps1 -OutputDir .\output\ShankTheBandit
```

Expected: Shank still passes because all external FormKeys are in verified tables.

- [ ] **Step 6: Test with temporary provenance**

Create a temporary copy of an output in `_tmp/verify-provenance-test` or temporarily create `output/ShankTheBandit/formkey-provenance.yaml` and remove it before commit if not wanted. Use a known FormKey and source `skylink-live`.

Expected: verifier reports provenance-backed pass for entries not in global tables. Do not commit temporary test output.

- [ ] **Step 7: Commit Task 7**

Run:

```powershell
git add .\tools\verify_prompt.ps1
git commit -m "Support provenance-backed FormKey verification"
```

Expected: commit succeeds.

## Task 8: Add `.sknpack` Verification

**Model requirement:** Smart agent required. Need to inspect actual generated sknpack format before coding.

**Files:**
- Modify: `tools/verify_prompt.ps1`
- Reference: existing `output/*/*.sknpack` and `templates/knowledge/world_knowledge.sknpack`

- [ ] **Step 1: Inspect existing sknpack files**

Run:

```powershell
Get-ChildItem .\output -Recurse -Filter "*.sknpack"
Get-Content .\templates\knowledge\world_knowledge.sknpack -Raw
Get-ChildItem .\output -Recurse -Filter "*.sknpack" | ForEach-Object { $_.FullName; Get-Content $_.FullName -Raw }
```

Expected: determine whether `.sknpack` is JSON, YAML, or another importable text format.

- [ ] **Step 2: Add world-knowledge expected detection**

If `npc.config.yaml` for the output is accessible, detect whether `world_knowledge.entries` is non-empty. If not accessible per-output, check for any `.sknpack` and validate if present.

Expected: verifier does not require `.sknpack` when no world knowledge exists.

- [ ] **Step 3: Add required-field validation**

For each `.sknpack` found, parse according to observed format. Validate every entry has:

```text
display_name
content
importance
condition_expr
always_inject
```

Expected: missing fields fail with `BAD_SKNPACK_STRUCTURE`.

- [ ] **Step 4: Add placeholder scan for sknpack**

Fail if `.sknpack` contains unresolved `TODO`, `TBD`, or unknown `{{...}}` template placeholders.

Expected: generated knowledge artifacts cannot silently contain placeholders.

- [ ] **Step 5: Test Grok and Shank outputs**

Run:

```powershell
& .\tools\verify_prompt.ps1 -OutputDir .\output\GrokTheSmith
& .\tools\verify_prompt.ps1 -OutputDir .\output\ShankTheBandit
```

Expected: Grok validates any generated `.sknpack`; Shank should pass or report no `.sknpack` if world knowledge is intentionally absent. Existing Grok package may still fail only on unverified package FormKey until that is resolved.

- [ ] **Step 6: Commit Task 8**

Run:

```powershell
git add .\tools\verify_prompt.ps1
git commit -m "Verify SkyrimNet world knowledge artifacts"
```

Expected: commit succeeds.

## Task 9: Final End-To-End Documentation Review

**Model requirement:** Smart agent required for final consistency pass.

**Files:**
- Modify if needed: `.opencode/skills/skyrim-npc-template/SKILL.md`, `AGENTS.md`, `tools/VERIFICATION-STATUS.md`, examples.

- [ ] **Step 1: Search for stale bad guidance**

Run:

```powershell
Select-String -Path .\AGENTS.md,.\.opencode\skills\skyrim-npc-template\SKILL.md,.\npc.config.yaml,.\examples\*.yaml -Pattern "grok_800|shank_800|NPC BASE record FormID|00033A35|skip personality|hostile NPCs skip|Generate Bio button"
```

Expected: no stale incorrect instructions. Mentions of web UI Generate Bio are allowed only if framed as not authoritative for pipeline generation.

- [ ] **Step 2: Run verifier on known outputs**

Run:

```powershell
& .\tools\verify_prompt.ps1 -OutputDir .\output\ShankTheBandit
& .\tools\verify_prompt.ps1 -OutputDir .\output\GrokTheSmith
```

Expected: Shank passes. Grok either passes or fails only on explicitly documented unverified `DefaultSandboxEditorLink` package.

- [ ] **Step 3: Inspect git diff**

Run:

```powershell
git status --short
git diff --stat
git diff --check
```

Expected: only intended files changed; no whitespace errors.

- [ ] **Step 4: Final commit**

If Step 1 or Step 2 required cleanup, commit it:

```powershell
git add .
git commit -m "Finalize SkyLink-assisted NPC pipeline docs"
```

Expected: commit succeeds or no changes remain.

## Task 10: Optional Push And Handoff

**Model requirement:** Fast/less-smart agent OK after smart final review.

**Files:**
- No file edits expected.

- [ ] **Step 1: Review recent commits**

Run:

```powershell
git status --short
git log --oneline -10
```

Expected: clean tree and recent task commits visible.

- [ ] **Step 2: Push if user requested pushing**

Run only if user requested push:

```powershell
git push origin main
```

Expected: push succeeds.

- [ ] **Step 3: Summarize implementation state**

Report:

```text
Implemented SkyLink-assisted pipeline updates.
Verified: [commands run]
Known remaining limitations: Tier 3/4 appearance backlog; any still-unverified lookup entries.
```

Expected: user knows what changed and what remains.

---

## Self-Review Checklist

- Spec coverage: Tasks cover interview form, SkyLinkAI-first resolution, no guessing, provenance, build gates, prompt/sknpack verification, appearance tiers, docs, and runtime-test guidance.
- Placeholder scan: This plan intentionally uses no `TODO`/`TBD` placeholders. Where behavior is conditional, the condition and expected action are explicit.
- Type/name consistency: Provenance sources are consistently `skylink-live`, `xedit-dump`, `verified-table`, and `user-provided`. Prompt blocks match the design spec. Fixed FormID allocation remains `0x800` NPC, `0x801` REFR, `0x802` OTFT.
