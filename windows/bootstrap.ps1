<#
  One-line entry point for a fresh Windows laptop (works once the repo is public):

    irm https://raw.githubusercontent.com/ananinja/laptop-provisioning/main/windows/bootstrap.ps1 | iex

  Downloads the toolkit (install.ps1, apps.json, office-config.xml) into a temp
  folder and runs install.ps1 - which self-elevates, installs the baseline, and
  prints a summary. Requires NO git, NO gh, NO GitHub login.
#>

$ErrorActionPreference = "Stop"

$base = "https://raw.githubusercontent.com/ananinja/laptop-provisioning/main/windows"
$dir  = Join-Path $env:TEMP "laptop-provisioning"
New-Item -ItemType Directory -Force -Path $dir | Out-Null

Write-Host "==> Downloading provisioning toolkit..." -ForegroundColor Cyan
foreach ($f in @("install.ps1", "apps.json", "office-config.xml")) {
    Invoke-WebRequest -Uri "$base/$f" -OutFile (Join-Path $dir $f) -UseBasicParsing
}

Write-Host "==> Starting install..." -ForegroundColor Cyan
# Allow the downloaded script to run in THIS process only (no admin, not
# persisted). Fresh laptops default to Restricted, which blocks .ps1 files.
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
& (Join-Path $dir "install.ps1")
