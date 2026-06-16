param(
    [Parameter(Mandatory=$true)]
    [string]$PluginName,
    [Parameter(Mandatory=$true)]
    [string]$NpcEditorId,
    [Parameter(Mandatory=$false)]
    [string]$NpcFormId,
    [Parameter(Mandatory=$false)]
    [string]$OutputFile
)

<#
.SYNOPSIS
    Capture NPC preview via SkyrimNet Dashboard or MCP.

.DESCRIPTION
    Checks if SkyrimNet services are running (Dashboard on :8080, MCP on :8889).
    If available, navigates to the NPC's actor card in the Dashboard and captures
    a screenshot. Falls back to console-summon + screenshot via MCP if available.

    If neither service is running, reports what needs to be running.

    Usage:
      .\tools\capture_npc.ps1 -PluginName "Lilatha" -NpcEditorId "VampireNPC_Lilatha" -NpcFormId "FE019800"
      
    Output: output\{PluginName}\{NpcEditorId}_preview.png
#>

Add-Type -AssemblyName System.Net.Http

# --- Config ---
$skyrimNetDashboard = "http://localhost:8080"
$mcpEndpoint = "http://localhost:8889"
if (-not $OutputFile) {
    $OutputFile = "output\$PluginName\${NpcEditorId}_preview.png"
}

# --- Preflight Checks ---
$dashboardUp = $false
$mcpUp = $false

try {
    $r = (New-Object System.Net.Http.HttpClient).GetAsync("$skyrimNetDashboard/assets/web-new/main.cde7ece4.css").Result
    if ($r.IsSuccessStatusCode) { $dashboardUp = $true }
} catch {}

try {
    $r2 = (New-Object System.Net.Http.HttpClient).GetAsync($mcpEndpoint).Result
    if ($r2.StatusCode -ne 0) { $mcpUp = $true }
} catch {}

# --- Dashboard approach (preferred) ---
if ($dashboardUp) {
    Write-Host "[OK] SkyrimNet Dashboard on :8080"
    # Open the NPC's dashboard card if actor ID known
    # The dashboard doesn't have direct URL routing to specific NPCs,
    # so this requires the user to navigate there manually or via Playwright
    Write-Host "[INFO] Dashboard found. Open http://localhost:8080 and navigate to"
    Write-Host "       the Actors tab, search for '$NpcEditorId' or '$PluginName'"
    Write-Host "       to see the actor card."
    # TODO: Add Playwright automation when browser debugging is available
    return
}

# --- MCP screenshot approach ---
if ($mcpUp) {
    Write-Host "[OK] SkyrimNet MCP on :8889"
    Write-Host "[WARN] Console-summon + screenshot not yet implemented"
    Write-Host "[HINT] Target: $NpcEditorId (FormID: $NpcFormId)"
    return
}

# --- Neither available ---
Write-Host "[FAIL] Neither SkyrimNet Dashboard (:8080) nor MCP (:8889) is running."
Write-Host ""
Write-Host "To capture NPC previews, start one of:"
Write-Host "  1. Skyrim + SkyrimNet (for Dashboard on :8080)"
Write-Host "  2. SkyrimNet MCP server on :8889"
Write-Host ""
Write-Host "Once running, re-run this script."
