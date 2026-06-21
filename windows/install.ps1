<#
  Installs the standard app baseline on a new Windows laptop, then prints a
  summary of what was installed, what was already present, and what failed.

  Apps come from apps.json (Teams, Slack, Chrome, Power BI, AnyDesk, Office).
  Office installs last because it's the slowest (full Microsoft 365 suite).

  Cortex XDR is NOT automated here - the admin installs it manually from the
  Cortex console (tenant-specific installer). The script reminds you at the end.

  Shows a live progress heartbeat (so a long Office install never looks frozen)
  and writes a full log file under %TEMP%\laptop-provisioning-logs.

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
$wingetExe = (Get-Command winget).Source

# Logs: per-app output + a full transcript of this run, under %TEMP%.
$logDir = Join-Path $env:TEMP "laptop-provisioning-logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$transcript = Join-Path $logDir ("run-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))
try { Start-Transcript -Path $transcript -Force | Out-Null } catch {}
Write-Host "Logging to: $transcript" -ForegroundColor DarkGray

# Single source of truth: the winget app IDs come straight from apps.json
$ids = (Get-Content $manifestPath -Raw | ConvertFrom-Json).Sources[0].Packages.PackageIdentifier

$results = @()

foreach ($id in $ids) {
    Write-Host ""
    Write-Host "==> $id" -ForegroundColor Cyan

    # Already installed? Skip it. (--accept-source-agreements is required here
    # too: on a fresh machine the FIRST winget call shows a Y/N source-agreement
    # prompt and would hang forever, since this output is captured not shown.)
    $listed = winget list --id $id --exact --accept-source-agreements 2>$null | Out-String
    if ($listed -match [regex]::Escape($id)) {
        Write-Host "    already installed - skipping" -ForegroundColor Yellow
        $results += [pscustomobject]@{ App = $id; Status = "Already present"; Detail = "" }
        continue
    }

    $wargs = @("install", "--id", $id, "--exact", "--silent",
               "--accept-package-agreements", "--accept-source-agreements")

    # Run winget as a child process and poll it, printing an elapsed-time
    # heartbeat every 10s so a long step (Office) never looks frozen. Output
    # goes to per-app log files. Retry once on failure (e.g. Slack flake).
    $code = $null; $output = @(); $elapsed = 0
    foreach ($attempt in 1..2) {
        if ($attempt -gt 1) { Write-Host "    retrying ($attempt/2)..." -ForegroundColor Yellow }
        $outFile = Join-Path $logDir "$id.out.log"
        $errFile = Join-Path $logDir "$id.err.log"
        $started = Get-Date
        Write-Host ("    installing... (started {0:HH:mm:ss})" -f $started) -ForegroundColor DarkGray
        $proc = Start-Process -FilePath $wingetExe -ArgumentList $wargs -PassThru -NoNewWindow `
            -RedirectStandardOutput $outFile -RedirectStandardError $errFile
        while (-not $proc.HasExited) {
            Start-Sleep -Seconds 10
            $secs = [int]((Get-Date) - $started).TotalSeconds
            Write-Host ("    ...still working ({0}s elapsed)" -f $secs) -ForegroundColor DarkGray
        }
        $code = $proc.ExitCode
        $elapsed = [int]((Get-Date) - $started).TotalSeconds
        $output = @()
        if (Test-Path $outFile) { $output += Get-Content $outFile -ErrorAction SilentlyContinue }
        if (Test-Path $errFile) { $output += Get-Content $errFile -ErrorAction SilentlyContinue }
        if ($code -eq 0) { break }
    }

    if ($code -eq 0) {
        Write-Host ("    installed (in {0}s)" -f $elapsed) -ForegroundColor Green
        $results += [pscustomobject]@{ App = $id; Status = "Installed"; Detail = "${elapsed}s" }
    } else {
        $hex = '0x{0:X8}' -f ($code -band 0xffffffff)
        $why = $output | Select-String -Pattern 'error|failed|No package|hash|cancel|agreement' |
            Select-Object -Last 1
        $detail = if ($why) { $why.ToString().Trim() } else { "exit $code ($hex)" }
        Write-Host "    FAILED: $detail" -ForegroundColor Red
        $output | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
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

Write-Host ("Installed now: {0}   |   Already present: {1}   |   Failed: {2}" -f $installed, $present, $failed) -ForegroundColor White
if ($failed -gt 0) {
    Write-Host "Some apps failed - see the Detail column above for why." -ForegroundColor Red
}

Write-Host ""
Write-Host "MANUAL STEPS (not automated):" -ForegroundColor Yellow
Write-Host "  1. Install Cortex XDR from the Cortex console (tenant-specific installer)." -ForegroundColor Yellow
Write-Host "  2. Sign into Microsoft 365 to activate Office." -ForegroundColor Yellow

try { Stop-Transcript | Out-Null } catch {}
Write-Host ""
Write-Host "Full log saved to: $transcript" -ForegroundColor DarkGray
