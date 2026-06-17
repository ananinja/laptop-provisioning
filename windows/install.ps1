<#
  Installs the standard app baseline on a new Windows laptop, then prints a
  summary of what was installed, what was already present, and what failed.

  Two kinds of apps:
   1. winget apps  - listed in apps.json (Office, Teams, Slack, Chrome,
      Power BI, AnyDesk). Office is slimmed to Word/Excel/PowerPoint/Outlook
      via office-config.xml.
   2. Cortex XDR   - not on winget. Downloaded from a private URL supplied via
      $env:CORTEX_MSI_URL or a gitignored installers/cortex.url file, then
      installed silently. Skipped (not failed) if no URL is configured.

  Run via install.cmd (double-click) or:  .\windows\install.ps1
#>

$ErrorActionPreference = "Continue"

# Machine-wide installers need admin. Elevate ONCE up front so we don't get a
# cancel-able UAC prompt in the middle of the run.
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host "Re-launching as administrator..." -ForegroundColor Yellow
    Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList @(
        "-NoProfile", "-ExecutionPolicy", "Bypass",
        "-Command", "& '$PSCommandPath'; Read-Host 'Done - press Enter to close'"
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

# Single source of truth: the winget app IDs come straight from apps.json
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

    # Build the winget args. Office is special: a config XML via --override lets
    # us install only Word/Excel/PowerPoint/Outlook.
    if ($id -eq "Microsoft.Office") {
        $cfgPath = Join-Path $PSScriptRoot "office-config.xml"
        Write-Host "    Office config: office-config.xml (Word/Excel/PowerPoint/Outlook)" -ForegroundColor DarkGray
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

# ---------- Cortex XDR (not on winget - download from a private URL) ----------
Write-Host ""
Write-Host "==> Cortex XDR" -ForegroundColor Cyan

# Resolve the URL: env var first, then a gitignored installers/cortex.url file.
$cortexUrl = $env:CORTEX_MSI_URL
$urlFile = Join-Path $PSScriptRoot "installers\cortex.url"
if ([string]::IsNullOrWhiteSpace($cortexUrl) -and (Test-Path $urlFile)) {
    $cortexUrl = (Get-Content $urlFile -Raw).Trim()
}

if (Test-Path "$env:ProgramFiles\Palo Alto Networks\Traps\cytool.exe") {
    Write-Host "    already installed - skipping" -ForegroundColor Yellow
    $results += [pscustomobject]@{ App = "Cortex XDR"; Status = "Already present"; Detail = "" }
} elseif ([string]::IsNullOrWhiteSpace($cortexUrl)) {
    Write-Host "    no URL configured - skipping (set CORTEX_MSI_URL or installers\cortex.url)" -ForegroundColor Yellow
    $results += [pscustomobject]@{ App = "Cortex XDR"; Status = "Skipped"; Detail = "no URL configured" }
} else {
    try {
        $msi = Join-Path $env:TEMP "cortex-xdr.msi"
        Write-Host "    downloading installer..." -ForegroundColor DarkGray
        Invoke-WebRequest -Uri $cortexUrl -OutFile $msi -UseBasicParsing
        $log = Join-Path $env:TEMP "cortex-xdr.log"
        $p = Start-Process msiexec.exe -Wait -PassThru -ArgumentList @(
            "/i", "`"$msi`"", "/qn", "/norestart", "/l*v", "`"$log`"")
        $code = $p.ExitCode
        if ($code -eq 0 -or $code -eq 3010) {
            Write-Host "    installed" -ForegroundColor Green
            $detail = if ($code -eq 3010) { "reboot required" } else { "" }
            $results += [pscustomobject]@{ App = "Cortex XDR"; Status = "Installed"; Detail = $detail }
        } else {
            Write-Host "    FAILED: msiexec exit $code" -ForegroundColor Red
            $results += [pscustomobject]@{ App = "Cortex XDR"; Status = "Failed"; Detail = "msiexec exit $code (see $log)" }
        }
    } catch {
        Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $results += [pscustomobject]@{ App = "Cortex XDR"; Status = "Failed"; Detail = $_.Exception.Message }
    }
}

# ---------- Summary ----------
Write-Host ""
Write-Host "===================== SUMMARY =====================" -ForegroundColor Cyan
$results | Format-Table -AutoSize App, Status, Detail

$installed = @($results | Where-Object { $_.Status -eq "Installed" }).Count
$present   = @($results | Where-Object { $_.Status -eq "Already present" }).Count
$skipped   = @($results | Where-Object { $_.Status -eq "Skipped" }).Count
$failed    = @($results | Where-Object { $_.Status -eq "Failed" }).Count

Write-Host ("Installed now: {0}   |   Already present: {1}   |   Skipped: {2}   |   Failed: {3}" -f $installed, $present, $skipped, $failed) -ForegroundColor White
if ($failed -gt 0) {
    Write-Host "Some apps failed - see the Detail column above for why." -ForegroundColor Red
}
Write-Host "Reminder: sign into Microsoft 365 to activate Office." -ForegroundColor Yellow
