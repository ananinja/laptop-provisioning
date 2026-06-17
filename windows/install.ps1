<#
  Installs the standard app baseline from apps.json (next to this file),
  one app at a time, then prints a summary of what was installed, what was
  already present, and what failed (and why).

  Office is slimmed by default (Word/Excel/PowerPoint/Outlook only).
  Use -FullOffice (or install-full.cmd) to install the full suite instead.

  Run via install.cmd (double-click) or:  .\windows\install.ps1 [-FullOffice]
#>
param([switch]$FullOffice)

$ErrorActionPreference = "Continue"

# Machine-wide installers (Office, Chrome, Power BI) need admin. Elevate ONCE up
# front so we don't get a cancel-able UAC prompt in the middle of the run.
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host "Re-launching as administrator..." -ForegroundColor Yellow
    $fwd = if ($FullOffice) { "-FullOffice" } else { "" }
    Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList @(
        "-NoProfile", "-ExecutionPolicy", "Bypass",
        "-Command", "& '$PSCommandPath' $fwd; Read-Host 'Done - press Enter to close'"
    )
    exit
}

$manifestPath = Join-Path $PSScriptRoot "apps.json"

if (-not (Test-Path $manifestPath)) {
    Write-Host "apps.json not found next to this script." -ForegroundColor Red
    exit 1
}
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget not found. Install 'App Installer' from the Microsoft Store, then re-run." -ForegroundColor Red
    exit 1
}

# Single source of truth: the app IDs come straight from apps.json
$ids = (Get-Content $manifestPath -Raw | ConvertFrom-Json).Sources[0].Packages.PackageIdentifier

$results = @()

foreach ($id in $ids) {
    Write-Host ""
    Write-Host "==> $id" -ForegroundColor Cyan

    # Already installed? Skip it.
    $listed = winget list --id $id --exact 2>$null | Out-String
    if ($listed -match [regex]::Escape($id)) {
        Write-Host "    already installed - skipping" -ForegroundColor Yellow
        $results += [pscustomobject]@{ App = $id; Status = "Already present"; Detail = "" }
        continue
    }

    # Build the winget args. Office is special: we pass a config XML via
    # --override so we control which Office apps get installed (slim vs full).
    if ($id -eq "Microsoft.Office") {
        $cfgName = if ($FullOffice) { "office-full.xml" } else { "office-slim.xml" }
        $cfgPath = Join-Path $PSScriptRoot $cfgName
        Write-Host ("    Office config: {0}" -f $cfgName) -ForegroundColor DarkGray
        $wargs = @("install", "--id", $id, "--exact",
                   "--accept-package-agreements", "--accept-source-agreements",
                   "--override", "/configure $cfgPath")
    } else {
        $wargs = @("install", "--id", $id, "--exact", "--silent",
                   "--accept-package-agreements", "--accept-source-agreements")
    }

    # Install, capturing output so we can explain failures. Retry once on
    # failure - rescues transient flakes (e.g. Slack's per-user installer).
    $code = $null; $output = $null
    foreach ($attempt in 1..2) {
        if ($attempt -gt 1) { Write-Host "    retrying ($attempt/2)..." -ForegroundColor Yellow }
        $output = & winget @wargs 2>&1
        $code = $LASTEXITCODE
        if ($code -eq 0) { break }
    }
    $output | ForEach-Object { Write-Host "    $_" }

    if ($code -eq 0) {
        Write-Host "    installed" -ForegroundColor Green
        $results += [pscustomobject]@{ App = $id; Status = "Installed"; Detail = "" }
    } else {
        $hex = '0x{0:X8}' -f ($code -band 0xffffffff)
        $why = $output | Select-String -Pattern 'error|failed|No package|hash|cancel|agreement' |
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

$installed = @($results | Where-Object { $_.Status -eq "Installed" }).Count
$present   = @($results | Where-Object { $_.Status -eq "Already present" }).Count
$failed    = @($results | Where-Object { $_.Status -eq "Failed" }).Count

Write-Host ("Office mode: {0}" -f $(if ($FullOffice) { "FULL suite" } else { "slim (Word/Excel/PowerPoint/Outlook)" })) -ForegroundColor DarkGray
Write-Host ("Installed now: {0}   |   Already present: {1}   |   Failed: {2}" -f $installed, $present, $failed) -ForegroundColor White
if ($failed -gt 0) {
    Write-Host "Some apps failed - see the Detail column above for why." -ForegroundColor Red
}
Write-Host "Reminder: sign into Microsoft 365 to activate Office." -ForegroundColor Yellow
