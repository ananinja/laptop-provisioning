<#
.SYNOPSIS
    One-shot laptop provisioning for new machines.
    Installs the standard app baseline defined in apps.json using winget.

.HOW TO RUN (admin pastes this one line on a fresh laptop)
    irm https://raw.githubusercontent.com/ananinja/laptop-provisioning/main/windows/bootstrap.ps1 | iex

.NOTES
    - Requires Windows 10 1809+ / Windows 11 (winget ships in-box).
    - Microsoft.Office installs the apps; license activation is per-user and stays manual.
#>

$ErrorActionPreference = "Stop"
$ManifestUrl = "https://raw.githubusercontent.com/ananinja/laptop-provisioning/main/windows/apps.json"

Write-Host "==> Laptop provisioning starting" -ForegroundColor Cyan

# 1. Make sure winget exists
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget not found. Install 'App Installer' from the Microsoft Store, then re-run." -ForegroundColor Red
    Write-Host "Store link: https://apps.microsoft.com/detail/9nblggh4nns1" -ForegroundColor Yellow
    exit 1
}

# 2. Pull the manifest to a temp file
$tmp = Join-Path $env:TEMP "apps.json"
Write-Host "==> Downloading app manifest" -ForegroundColor Cyan
Invoke-RestMethod -Uri $ManifestUrl -OutFile $tmp

# 3. Install everything in the manifest. --ignore-unavailable skips anything
#    not offered for this machine instead of aborting the whole run.
Write-Host "==> Installing apps (this can take several minutes)" -ForegroundColor Cyan
winget import --import-file $tmp `
    --accept-package-agreements `
    --accept-source-agreements `
    --ignore-unavailable

Write-Host ""
Write-Host "==> Done. Reminder: sign into Microsoft 365 to activate Office." -ForegroundColor Green
