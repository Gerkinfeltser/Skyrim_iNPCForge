param(
    [Parameter(Mandatory=$true)]
    [string]$OutputDir,
    [switch]$Fix,
    [switch]$Strict
)

$ErrorActionPreference = "Stop"
$pluginName = Split-Path $OutputDir -Leaf
$spriggitDir = Join-Path $OutputDir "${pluginName}_spriggit"
$repoRoot = Split-Path $PSScriptRoot -Parent

if (-not (Test-Path $spriggitDir)) {
    $candidateSpriggitDirs = @(Get-ChildItem -Path $OutputDir -Directory -Filter "*_spriggit" -ErrorAction SilentlyContinue)
    if ($candidateSpriggitDirs.Count -eq 1) {
        $spriggitDir = $candidateSpriggitDirs[0].FullName
    }
}

$pluginLocalName = $pluginName
$spriggitLeaf = Split-Path $spriggitDir -Leaf
if ($spriggitLeaf -match '^(.+)_spriggit$') {
    $pluginLocalName = $Matches[1]
}

function Normalize-FormKey {
    param([string]$FormKey)
    $FormKey = $FormKey.Trim().Trim('"').Trim("'")
    $parts = $FormKey -split ":"
    if ($parts.Count -ne 2) { return $FormKey.ToLowerInvariant() }

    $hex = $parts[0] -replace "^0+", ""
    if ($hex -eq "") { $hex = "0" }
    $objectId = "{0:X6}" -f [Convert]::ToInt64($hex, 16)
    return "${objectId}:$($parts[1].ToLowerInvariant())"
}

function Load-VerifiedFormKeys {
    param([string]$Path)
    $keys = @{}
    if (-not (Test-Path $Path)) { return $keys }

    foreach ($line in Get-Content $Path) {
        $trimmed = $line.Trim()
        if ($trimmed -eq "" -or $trimmed.StartsWith("#")) { continue }
        if ($trimmed -match "(?i)TODO|UNVERIFIED") { continue }
        if ($trimmed -match "^[^:]+:\s*([^\s#]+)") {
            $keys[(Normalize-FormKey $Matches[1])] = $true
        }
    }

    return $keys
}

function Load-ProvenanceFormKeys {
    param([string]$Path)
    $keys = @{}
    if (-not (Test-Path $Path)) { return $keys }

    $currentFormKey = $null
    $currentSource = $null
    foreach ($line in Get-Content $Path) {
        $trimmed = $line.Trim()
        # Strip leading YAML list marker "- " so "- form_key:" matches "form_key:"
        $trimmed = $trimmed -replace '^-+\s+', ''
        if ($trimmed -match '^form_key:\s+(.+)$') {
            $currentFormKey = $Matches[1].Trim().Trim('"').Trim("'")
        }
        elseif ($trimmed -match '^source:\s+(.+)$') {
            $currentSource = $Matches[1].Trim().Trim('"').Trim("'")
        }

        if ($currentFormKey -and $currentSource) {
            $keys[(Normalize-FormKey $currentFormKey)] = $currentSource
            $currentFormKey = $null
            $currentSource = $null
        }
    }

    return $keys
}

function Test-VerifiedFormKey {
    param(
        [string]$Label,
        [string]$FormKey,
        [hashtable]$VerifiedKeys,
        [string]$TableName,
        [switch]$AllowPluginLocal,
        [hashtable]$ProvenanceKeys = @{},
        [switch]$Strict
    )

    $cleanFormKey = $FormKey.Trim().Trim('"').Trim("'")
    $parts = $cleanFormKey -split ":"
    if ($parts.Count -ne 2) {
        Write-Host "[FAIL] $Label $cleanFormKey is not a valid FormKey" -ForegroundColor Red
        $script:issues += "INVALID_FORMKEY"
        return
    }

    if ($AllowPluginLocal -and $parts[1].ToLowerInvariant() -eq "${pluginLocalName}.esp".ToLowerInvariant()) {
        Write-Host "[PASS] $Label $cleanFormKey (plugin-local)" -ForegroundColor Green
        return
    }

    $normalized = Normalize-FormKey $cleanFormKey
    if ($VerifiedKeys.ContainsKey($normalized)) {
        Write-Host "[PASS] $Label $cleanFormKey (verified lookup)" -ForegroundColor Green
        return
    }

    if ($ProvenanceKeys.ContainsKey($normalized)) {
        $source = $ProvenanceKeys[$normalized]
        if ($source -in @("skylink-live", "skyrim-patcher-mcp", "spriggit-serialization", "xedit-dump", "verified-table")) {
            Write-Host "[PASS] $Label $cleanFormKey (provenance: $source)" -ForegroundColor Green
            return
        }
        if ($source -eq "user-provided") {
            if ($Strict) {
                Write-Host "[FAIL] $Label $cleanFormKey from user-provided source not allowed in Strict mode" -ForegroundColor Red
                $script:issues += "USER_PROVIDED_FORMKEY"
                return
            }
            Write-Host "[WARN] $Label $cleanFormKey from user-provided source (use -Strict to fail)" -ForegroundColor Yellow
            return
        }
        # Unknown provenance source: treat like user-provided
        if ($Strict) {
            Write-Host "[FAIL] $Label $cleanFormKey from unknown provenance source '$source' not allowed in Strict mode" -ForegroundColor Red
            $script:issues += "UNKNOWN_PROVENANCE_SOURCE"
            return
        }
        Write-Host "[WARN] $Label $cleanFormKey from unknown provenance source '$source' (use -Strict to fail)" -ForegroundColor Yellow
        return
    }

    Write-Host "[FAIL] $Label $cleanFormKey is not in $TableName" -ForegroundColor Red
    Write-Host "  Verify this FormKey with xEdit or SkyLinkAI, then add it to $TableName." -ForegroundColor DarkRed
    $script:issues += "UNVERIFIED_FORMKEY"
}

function Find-PlacedNpcFormKey {
    param([string]$RootDir)
    $cellFiles = Get-ChildItem -Path $RootDir -Recurse -Filter "*.yaml" | Where-Object { $_.DirectoryName -match "Cells" }
    foreach ($f in $cellFiles) {
        $raw = Get-Content $f.FullName -Raw
        # Match PlacedNpc block and capture its FormKey
        if ($raw -match "MutagenObjectType:\s*PlacedNpc\s+FormKey:\s*(\S+)") {
            return @{Key = $Matches[1]; Path = $f.FullName }
        }
    }
    return $null
}

function Find-NpcName {
    param([string]$RootDir)
    $npcFiles = Get-ChildItem -Path $RootDir -Recurse -Filter "*.yaml" | Where-Object { $_.DirectoryName -match "Npcs" }
    foreach ($f in $npcFiles) {
        $raw = Get-Content $f.FullName -Raw
        # Find the NPC Name block: TargetLanguage must appear, then capture Value
        if ($raw -match "TargetLanguage") {
            if ($raw -match "(?m)^\s+Value:\s+(.+)$") {
                return $Matches[1]
            }
        }
    }
    return $null
}

$placedNpc = Find-PlacedNpcFormKey $spriggitDir
if (-not $placedNpc) {
    Write-Error "No PlacedNpc found in $spriggitDir"
    exit 1
}

$refrKey = $placedNpc.Key
$refrPath = $placedNpc.Path

$keyParts = $refrKey -split ":"
$hexPart = $keyParts[0] -replace "^0+", ""
if ($hexPart -eq "") { $hexPart = "0" }
$suffix = "{0:X3}" -f ([Convert]::ToInt64($hexPart, 16) -band 0xFFF)

Write-Host "REFR FormKey: $refrKey -> suffix $suffix" -ForegroundColor Cyan

$npcName = Find-NpcName $spriggitDir
if (-not $npcName) {
    Write-Error "Could not find NPC name in $spriggitDir"
    exit 1
}
Write-Host "NPC name: $npcName" -ForegroundColor Cyan

$sanitized = $npcName.ToLowerInvariant() -replace "[\s'/\\]", "_"
$expectedFilename = "${sanitized}_${suffix}.prompt"
$promptDir = Join-Path $OutputDir "SKSE\Plugins\SkyrimNet\prompts\characters"
$promptPath = Join-Path $promptDir $expectedFilename

$provenancePath = Join-Path $OutputDir "formkey-provenance.yaml"
$provenanceExists = Test-Path $provenancePath
$provenanceKeys = Load-ProvenanceFormKeys $provenancePath

Write-Host "Expected prompt: $expectedFilename" -ForegroundColor Cyan
Write-Host "Expected path: $promptPath" -ForegroundColor Cyan
Write-Host ""

$issues = @()

if (-not $provenanceExists) {
    if ($Strict) {
        Write-Host "[FAIL] formkey-provenance.yaml missing (required in Strict mode)" -ForegroundColor Red
        $issues += "MISSING_PROVENANCE"
    }
    else {
        Write-Host "[WARN] formkey-provenance.yaml missing (use -Strict to fail)" -ForegroundColor Yellow
    }
}

# Required SkyrimNet prompt blocks; must match templates/prompt/character.prompt
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

$verifiedRaces = Load-VerifiedFormKeys (Join-Path $repoRoot "data\races.yaml")
$verifiedVoices = Load-VerifiedFormKeys (Join-Path $repoRoot "data\voices.yaml")
$verifiedOutfits = Load-VerifiedFormKeys (Join-Path $repoRoot "data\outfits.yaml")
$verifiedFactions = Load-VerifiedFormKeys (Join-Path $repoRoot "data\factions.yaml")
$verifiedPackages = Load-VerifiedFormKeys (Join-Path $repoRoot "data\ai_packages.yaml")
$verifiedLocations = Load-VerifiedFormKeys (Join-Path $repoRoot "data\locations.yaml")

# 4. Check file exists
if (Test-Path $promptPath) {
    Write-Host "[PASS] Prompt file exists" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Prompt file missing at $promptPath" -ForegroundColor Red
    $issues += "MISSING_PROMPT"
    if (Test-Path $promptDir) {
        $existing = Get-ChildItem -Path $promptDir -Filter "*.prompt"
        Write-Host "  Existing prompts:" -ForegroundColor Yellow
        foreach ($e in $existing) {
            Write-Host "    $($e.Name)" -ForegroundColor Yellow
        }
        if ($Fix) {
            $altFile = Get-ChildItem -Path $promptDir -Filter "${sanitized}_*.prompt" | Select-Object -First 1
            if ($altFile) {
                Copy-Item $altFile.FullName $promptPath -Force
                Write-Host "  [FIXED] Copied $($altFile.Name) -> $expectedFilename" -ForegroundColor Green
                $issues = $issues | Where-Object { $_ -ne "MISSING_PROMPT" }
            }
        }
    }
}

# 5. Check prompt has {% block %} format
if (Test-Path $promptPath) {
    $content = Get-Content $promptPath -Raw
    if ($content -match "{%\s*block\s+") {
        Write-Host "[PASS] Prompt has {% block %} format" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Prompt is plain text - no {% block %} tags" -ForegroundColor Red
        Write-Host "  SkyrimNet wraps prompts with {% extends %} so plain text is discarded" -ForegroundColor DarkRed
        $issues += "NO_BLOCK_FORMAT"
    }

    # 5b. Check all required prompt blocks are present
    Write-Host ""
    Write-Host "--- Prompt Block Completeness ---" -ForegroundColor Cyan
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

    # 5c. Check for unresolved placeholder patterns
    Write-Host ""
    Write-Host "--- Placeholder Scan ---" -ForegroundColor Cyan
    # {{player.*}} are legitimate SkyrimNet runtime placeholders; they resolve at
    # dialogue time, not build time, so they must be excluded from the placeholder check.
    $placeholderPatterns = @("TODO", "TBD", "\{\{\s*npc\.", "\{\{\s*(?!player\.)[^}]+\s*\}\}")
    foreach ($placeholderPattern in $placeholderPatterns) {
        if ($content -match $placeholderPattern) {
            Write-Host "[FAIL] Prompt contains unresolved placeholder pattern: $placeholderPattern" -ForegroundColor Red
            $issues += "PROMPT_PLACEHOLDER"
        }
    }
}

# 6. Check SkyrimNet world knowledge packs (.sknpack)
# .sknpack files are JSON documents rendered from the Handlebars template in
# templates/knowledge/world_knowledge.sknpack. They are optional; a plugin
# with no world_knowledge block in its config won't produce one.
Write-Host ""
Write-Host "--- World Knowledge Pack Checks ---" -ForegroundColor Cyan

# Required fields that every entry in the "entries" array MUST contain.
# These match the SkyrimNet skyrimnet_knowledge_pack schema (format_version 2).
$sknpackRequiredEntryFields = @(
    "display_name",
    "content",
    "importance",
    "condition_expr",
    "always_inject"
)

$sknpackDir = Join-Path $OutputDir "WorldKnowledge-ManuallyImport"
$sknpackFiles = @()
if (Test-Path $sknpackDir) {
    $sknpackFiles = Get-ChildItem -Path $sknpackDir -Filter "*.sknpack" -ErrorAction SilentlyContinue
}
if ($sknpackFiles.Count -eq 0) {
    Write-Host "[INFO] No .sknpack files found under $OutputDir; world knowledge is optional" -ForegroundColor Yellow
} else {
    foreach ($sknpack in $sknpackFiles) {
        Write-Host ("  Checking: " + $sknpack.Name) -ForegroundColor Cyan
        $sknpackRaw = Get-Content $sknpack.FullName -Raw

        # --- Parse as JSON ---
        # The rendered .sknpack must be valid JSON.  Unresolved Handlebars
        # markers like {{author}} will break JSON parsing.
        $sknpackObj = $null
        try {
            $sknpackObj = $sknpackRaw | ConvertFrom-Json -ErrorAction Stop
        } catch {
            $parseMessage = $_.Exception.Message
            Write-Host ("[FAIL] .sknpack is not valid JSON: " + $parseMessage) -ForegroundColor Red
            Write-Host ("  File: " + $sknpack.FullName) -ForegroundColor DarkRed
            $issues += "BAD_SKNPACK_STRUCTURE"
            continue
        }

        # --- Navigate to entries array ---
        # Top-level key is "skyrimnet_knowledge_pack", which holds the "entries" array.
        $pack = $sknpackObj.skyrimnet_knowledge_pack
        if (-not $pack) {
            Write-Host "[FAIL] .sknpack missing top-level key 'skyrimnet_knowledge_pack'" -ForegroundColor Red
            $issues += "BAD_SKNPACK_STRUCTURE"
            continue
        }

        $entries = $pack.entries
        if (-not $entries) {
            Write-Host "[FAIL] .sknpack missing 'entries' array inside skyrimnet_knowledge_pack" -ForegroundColor Red
            $issues += "BAD_SKNPACK_STRUCTURE"
            continue
        }

        # --- Validate each entry has required fields ---
        $entryIndex = 0
        $entryFailures = 0
        foreach ($entry in $entries) {
            $entryIndex++
            foreach ($field in $sknpackRequiredEntryFields) {
                # PowerShell ConvertFrom-Json returns PSCustomObject;
                # check property existence via .psobject.properties
                if (-not ($entry.psobject.Properties.Name -contains $field)) {
                    Write-Host "[FAIL] Entry #${entryIndex} missing required field: $field" -ForegroundColor Red
                    $issues += "BAD_SKNPACK_STRUCTURE"
                    $entryFailures++
                } else {
                    # Field exists; check it's not empty/null.
                    # condition_expr is allowed to be "" (means "all NPCs" in SkyrimNet).
                    $val = $entry.$field
                    if ($null -eq $val) {
                        Write-Host "[FAIL] Entry #${entryIndex} has null required field: $field" -ForegroundColor Red
                        $issues += "BAD_SKNPACK_STRUCTURE"
                        $entryFailures++
                    } elseif ($val -is [string] -and $val.Trim() -eq "" -and $field -ne "condition_expr") {
                        Write-Host "[FAIL] Entry #${entryIndex} has empty required field: $field" -ForegroundColor Red
                        $issues += "BAD_SKNPACK_STRUCTURE"
                        $entryFailures++
                    }
                }
            }
        }
        if ($entryFailures -eq 0) {
            Write-Host "[PASS] .sknpack structure valid ($entryIndex entries)" -ForegroundColor Green
        }

        # --- Placeholder scan ---
        # The rendered output must not contain TODO/TBD markers or Handlebars
        # {{...}} template syntax.  These indicate the template was not rendered.
        # {{player.*}} is NOT exempt here because .sknpack files are rendered
        # JSON output, not prompt templates; all Handlebars should be resolved.
        $placeholderPatterns = @("TODO", "TBD", "\{\{[^}]+\}\}")
        foreach ($placeholderPattern in $placeholderPatterns) {
            if ($sknpackRaw -match $placeholderPattern) {
                Write-Host "[FAIL] .sknpack contains unresolved placeholder pattern: $placeholderPattern" -ForegroundColor Red
                $issues += "PROMPT_PLACEHOLDER"
            }
        }

        # --- Importance range check ---
        # importance should be 0.0-1.0 per SkyrimNet spec
        $entryIndex = 0
        foreach ($entry in $entries) {
            $entryIndex++
            if ($entry.psobject.Properties.Name -contains "importance") {
                $imp = $entry.importance
                if ($imp -is [double] -or $imp -is [int]) {
                    if ($imp -lt 0.0 -or $imp -gt 1.0) {
                        Write-Host "[WARN] Entry #$entryIndex importance=$imp is outside recommended 0.0-1.0 range" -ForegroundColor Yellow
                    }
                }
            }
        }
    }
}

# 7. Check known external FormIDs against verified lookup tables
Write-Host ""
Write-Host "--- FormKey Checks ---" -ForegroundColor Cyan

foreach ($cellFile in (Get-ChildItem -Path $spriggitDir -Recurse -Filter "RecordData.yaml" | Where-Object { $_.DirectoryName -match "Cells" })) {
    $raw = Get-Content $cellFile.FullName -Raw
    if ($raw -match "(?m)^FormKey:\s+(\S+)") {
        Test-VerifiedFormKey "Location" $Matches[1] $verifiedLocations "data\locations.yaml" -ProvenanceKeys $provenanceKeys -Strict:$Strict
    }
}

$foundFaction = $false
foreach ($f in (Get-ChildItem -Path $spriggitDir -Recurse -Filter "*.yaml" | Where-Object { $_.DirectoryName -match "Npcs" })) {
    $raw = Get-Content $f.FullName -Raw

    if ($raw -match "(?m)^Race:\s+(\S+)") {
        Test-VerifiedFormKey "Race" $Matches[1] $verifiedRaces "data\races.yaml" -ProvenanceKeys $provenanceKeys -Strict:$Strict
    }

    if ($raw -match "(?m)^Voice:\s+(\S+)") {
        Test-VerifiedFormKey "Voice" $Matches[1] $verifiedVoices "data\voices.yaml" -ProvenanceKeys $provenanceKeys -Strict:$Strict
    }

    if ($raw -match "(?m)^DefaultOutfit:\s+(\S+)") {
        Test-VerifiedFormKey "DefaultOutfit" $Matches[1] $verifiedOutfits "data\outfits.yaml" -AllowPluginLocal -ProvenanceKeys $provenanceKeys -Strict:$Strict
    }

    $matches = [regex]::Matches($raw, "Faction:\s+(\S+)")
    foreach ($m in $matches) {
        $foundFaction = $true
        $factionKey = $m.Groups[1].Value
        Test-VerifiedFormKey "Faction" $factionKey $verifiedFactions "data\factions.yaml" -ProvenanceKeys $provenanceKeys -Strict:$Strict
    }

    if ($raw -match "(?ms)^Packages:\s*((?:\s*-\s+\S+\s*)+)") {
        $packageMatches = [regex]::Matches($Matches[1], "-\s+(\S+)")
        foreach ($packageMatch in $packageMatches) {
            Test-VerifiedFormKey "Package" $packageMatch.Groups[1].Value $verifiedPackages "data\ai_packages.yaml" -ProvenanceKeys $provenanceKeys -Strict:$Strict
        }
    }
}
if (-not $foundFaction) {
    Write-Host "[INFO] No factions on NPC" -ForegroundColor Yellow
}

Write-Host ""
if ($issues.Count -eq 0) {
    Write-Host "All checks passed." -ForegroundColor Green
} else {
    $issueText = $issues -join ", "
    Write-Host "Issues found: $issueText" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Prompt filename: ${sanitized}_${suffix}.prompt" -ForegroundColor Magenta
Write-Host "Suffix: 0x$hexPart & 0xFFF = 0x$suffix" -ForegroundColor Magenta
Write-Host "Source: $refrPath" -ForegroundColor Magenta
