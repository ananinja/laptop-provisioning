<#
  Uninstalls the standard app baseline listed in apps.json (next to this file),
  one app at a time, then prints a summary of what was removed, what wasn't
  present, and what failed (and why).

  Run via uninstall.cmd (double-click) or:  .\windows\uninstall.ps1
  Add -Force to skip the confirmation prompt.
#>
param([switch]$Force)

$ErrorActionPreference = "Continue"
$manifestPath = Join-Path $PSScriptRoot "apps.json"

if (-not (Test-Path $manifestPath)) {
    Write-Host "apps.json not found next to this script." -ForegroundColor Red
    exit 1
}
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget not found." -ForegroundColor Red
    exit 1
}

# Single source of truth: the app IDs come straight from apps.json
$ids = (Get-Content $manifestPath -Raw | ConvertFrom-Json).Sources[0].Packages.PackageIdentifier

# Confirm before removing anything
Write-Host "This will UNINSTALL the following apps:" -ForegroundColor Yellow
$ids | ForEach-Object { Write-Host "  - $_" }
if (-not $Force) {
    $answer = Read-Host "Continue? (y/N)"
    if ($answer -notmatch '^(y|yes)$') {
        Write-Host "Cancelled. Nothing was removed." -ForegroundColor Cyan
        exit 0
    }
}

$results = @()

foreach ($id in $ids) {
    Write-Host ""
    Write-Host "==> $id" -ForegroundColor Cyan

    # Not installed? Nothing to do.
    $listed = winget list --id $id --exact 2>$null | Out-String
    if ($listed -notmatch [regex]::Escape($id)) {
        Write-Host "    not installed - skipping" -ForegroundColor Yellow
        $results += [pscustomobject]@{ App = $id; Status = "Not present"; Detail = "" }
        continue
    }

    # Uninstall, capturing output so we can explain failures.
    $output = winget uninstall --id $id --exact --silent 2>&1
    $code = $LASTEXITCODE
    $output | ForEach-Object { Write-Host "    $_" }

    if ($code -eq 0) {
        Write-Host "    uninstalled" -ForegroundColor Green
        $results += [pscustomobject]@{ App = $id; Status = "Uninstalled"; Detail = "" }
    } else {
        $hex = '0x{0:X8}' -f ($code -band 0xffffffff)
        $why = $output | Select-String -Pattern 'error|failed|No package|cancel|in use|running' |
            Select-Object -Last 1
        $detail = if ($why) { $why.ToString().Trim() } else { "exit $code ($hex)" }
        Write-Host "    FAILED: $detail" -ForegroundColor Red
        $results += [pscustomobject]@{ App = $id; Status = "Failed"; Detail = $detail }
    }
}

# ---------- Summary ----------
Write-Host ""
Write-Host "===================== SUMMARY =====================" -ForegroundColor Cyan
$results | Format-Table -AutoSize App, Status, Detail

$removed  = @($results | Where-Object { $_.Status -eq "Uninstalled" }).Count
$absent   = @($results | Where-Object { $_.Status -eq "Not present" }).Count
$failed   = @($results | Where-Object { $_.Status -eq "Failed" }).Count

Write-Host ("Uninstalled: {0}   |   Not present: {1}   |   Failed: {2}" -f $removed, $absent, $failed) -ForegroundColor White
if ($failed -gt 0) {
    Write-Host "Some apps failed - see the Detail column above (often: app still running)." -ForegroundColor Red
}
