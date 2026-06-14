param(
    [Parameter(Mandatory=$true)]
    [string]$OutputDir,
    [switch]$Fix
)

$ErrorActionPreference = "Stop"
$pluginName = Split-Path $OutputDir -Leaf
$spriggitDir = Join-Path $OutputDir "${pluginName}_spriggit"
$repoRoot = Split-Path $PSScriptRoot -Parent

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

function Test-VerifiedFormKey {
    param(
        [string]$Label,
        [string]$FormKey,
        [hashtable]$VerifiedKeys,
        [string]$TableName,
        [switch]$AllowPluginLocal
    )

    $cleanFormKey = $FormKey.Trim().Trim('"').Trim("'")
    $parts = $cleanFormKey -split ":"
    if ($parts.Count -ne 2) {
        Write-Host "[FAIL] $Label $cleanFormKey is not a valid FormKey" -ForegroundColor Red
        $script:issues += "INVALID_FORMKEY"
        return
    }

    if ($AllowPluginLocal -and $parts[1].ToLowerInvariant() -eq "${pluginName}.esp".ToLowerInvariant()) {
        Write-Host "[PASS] $Label $cleanFormKey (plugin-local)" -ForegroundColor Green
        return
    }

    $normalized = Normalize-FormKey $cleanFormKey
    if ($VerifiedKeys.ContainsKey($normalized)) {
        Write-Host "[PASS] $Label $cleanFormKey (verified lookup)" -ForegroundColor Green
    }
    else {
        Write-Host "[FAIL] $Label $cleanFormKey is not in $TableName" -ForegroundColor Red
        Write-Host "  Verify this FormKey with xEdit or SkyLinkAI, then add it to $TableName." -ForegroundColor DarkRed
        $script:issues += "UNVERIFIED_FORMKEY"
    }
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

Write-Host "Expected prompt: $expectedFilename" -ForegroundColor Cyan
Write-Host "Expected path: $promptPath" -ForegroundColor Cyan
Write-Host ""

$issues = @()
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
}

# 6. Check known external FormIDs against verified lookup tables
Write-Host ""
Write-Host "--- FormKey Checks ---" -ForegroundColor Cyan

foreach ($cellFile in (Get-ChildItem -Path $spriggitDir -Recurse -Filter "RecordData.yaml" | Where-Object { $_.DirectoryName -match "Cells" })) {
    $raw = Get-Content $cellFile.FullName -Raw
    if ($raw -match "(?m)^FormKey:\s+(\S+)") {
        Test-VerifiedFormKey "Location" $Matches[1] $verifiedLocations "data\locations.yaml"
    }
}

$foundFaction = $false
foreach ($f in (Get-ChildItem -Path $spriggitDir -Recurse -Filter "*.yaml" | Where-Object { $_.DirectoryName -match "Npcs" })) {
    $raw = Get-Content $f.FullName -Raw

    if ($raw -match "(?m)^Race:\s+(\S+)") {
        Test-VerifiedFormKey "Race" $Matches[1] $verifiedRaces "data\races.yaml"
    }

    if ($raw -match "(?m)^Voice:\s+(\S+)") {
        Test-VerifiedFormKey "Voice" $Matches[1] $verifiedVoices "data\voices.yaml"
    }

    if ($raw -match "(?m)^DefaultOutfit:\s+(\S+)") {
        Test-VerifiedFormKey "DefaultOutfit" $Matches[1] $verifiedOutfits "data\outfits.yaml" -AllowPluginLocal
    }

    $matches = [regex]::Matches($raw, "Faction:\s+(\S+)")
    foreach ($m in $matches) {
        $foundFaction = $true
        $factionKey = $m.Groups[1].Value
        Test-VerifiedFormKey "Faction" $factionKey $verifiedFactions "data\factions.yaml"
    }

    if ($raw -match "(?ms)^Packages:\s*((?:\s*-\s+\S+\s*)+)") {
        $packageMatches = [regex]::Matches($Matches[1], "-\s+(\S+)")
        foreach ($packageMatch in $packageMatches) {
            Test-VerifiedFormKey "Package" $packageMatch.Groups[1].Value $verifiedPackages "data\ai_packages.yaml"
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
