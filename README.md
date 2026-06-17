# Laptop Provisioning

Automates the standard new-laptop app setup so admins don't install each app by
hand. Edit one file, every future machine gets the change.

## What gets installed

| App | Windows | Mac |
|-----|:------:|:---:|
| Microsoft Office (Word, Excel, PowerPoint, Outlook) | ✅ | ✅ |
| Microsoft Teams | ✅ | — |
| Slack | ✅ | — |
| Google Chrome | ✅ | — |
| Power BI | ✅ | — |
| AnyDesk | ✅ | — |
| Cortex XDR | ✅¹ | — |

Same set for every user. Office is **slimmed** to Word/Excel/PowerPoint/Outlook.
Mac devices only require Microsoft Office.

¹ Cortex XDR isn't on winget — it's downloaded from a private URL at runtime.
See [Cortex XDR setup](#cortex-xdr-setup).

## How to run it

### Windows — easiest (double-click)
1. Get the files onto the laptop (see [Getting the files](#getting-the-files)).
2. (Optional) configure the Cortex XDR URL — see [below](#cortex-xdr-setup).
3. Open the `laptop-provisioning\windows` folder and **double-click `install.cmd`**.

It **asks for admin once** (a single UAC prompt — accept it), installs everything,
skips apps already present, retries once on a transient failure, and at the end
prints a **summary** — each app marked Installed / Already present / Skipped /
Failed (with the reason for any failure).

Prefer the terminal? In **PowerShell**, from the repo folder:

```powershell
.\windows\install.ps1
```

### Mac
In **Terminal**, from the repo folder:

```bash
bash mac/bootstrap.sh
```

Installs Homebrew automatically if it isn't already there, then installs Office.
Mac is intentionally Office-only, per the team.

To remove it again:

```bash
bash mac/uninstall.sh
```

### Windows — uninstall

To remove the winget apps (e.g. offboarding), **double-click `uninstall.cmd`**,
or run `.\windows\uninstall.ps1`. It confirms first, skips apps that aren't
installed, and prints a summary. Add `-Force` to skip the prompt.

Note: Cortex XDR is **not** removed by this script — EDR agents are uninstalled
through the Cortex console / with the tamper-protection password, by design.

## Cortex XDR setup

Cortex XDR's agent installer is tenant-specific (carries your org's enrollment
ID), so it's never committed to the repo. The script downloads it from a private
URL you provide via **one** of:

1. Environment variable:
   ```powershell
   setx CORTEX_MSI_URL "https://...private-or-presigned-url..."
   ```
2. A `windows\installers\cortex.url` file containing just the URL (gitignored).

**Recommended hosting:** a private S3 bucket with a presigned URL — no AWS
credentials needed on the laptop, and the link auto-expires. If no URL is set,
the script simply **skips** Cortex (it won't fail the run).

See `windows/installers/README.md` for details.

## Getting the files

The repo is **private**, so a fresh laptop can't fetch it anonymously. Clone it
with an account that has access:

```powershell
gh repo clone ananinja/laptop-provisioning
cd laptop-provisioning
```

**When this repo is public** (an org decision — note Cortex/installers stay out
of git regardless), the clone step disappears and a fresh laptop can run the
whole thing with one pasted line:

```powershell
irm https://raw.githubusercontent.com/ananinja/laptop-provisioning/main/windows/bootstrap.ps1 | iex
```

That's the eventual hands-off goal. Until then, use the clone + `install.cmd` flow.

## ⚠️ Office licensing

The scripts **install** Microsoft Office, but activation is per-user: the new
hire must sign in with their Microsoft 365 account to license it. That step stays
manual.

## Changing the app list

- **Windows (winget apps):** edit `windows/apps.json` — add a line with the app's
  winget ID. Find one with `winget search "<app name>"`.
- **Which Office apps install:** edit `windows/office-config.xml` — add/remove
  `<ExcludeApp>` lines.
- **Mac:** edit `mac/Brewfile` — add a `cask "<name>"` line.

Commit the change. Every laptop provisioned afterward picks it up automatically.
Re-running is safe — already-installed apps are skipped.

## Repo layout

```
laptop-provisioning/
├─ windows/
│  ├─ apps.json         # winget app list - single source of truth
│  ├─ office-config.xml # which Office apps install (Word/Excel/PowerPoint/Outlook)
│  ├─ install.cmd       # double-click installer (launches install.ps1)
│  ├─ install.ps1       # installs winget apps + Cortex, prints a summary
│  ├─ uninstall.cmd     # double-click uninstaller (launches uninstall.ps1)
│  ├─ uninstall.ps1     # removes the winget apps (with confirmation)
│  ├─ bootstrap.ps1     # one-liner entry point (for when the repo is public)
│  └─ installers/       # gitignored - local/tenant installers (e.g. Cortex URL)
├─ mac/
│  ├─ Brewfile          # the app list (Homebrew) - Office only
│  ├─ bootstrap.sh      # installs Homebrew, then the list
│  └─ uninstall.sh      # removes the Mac baseline (Office)
└─ README.md
```

## Roadmap

- **Now — clone + `install.cmd`.** Proven, works on a private repo.
- **Next — one-line paste.** Make the repo public so `bootstrap.ps1` runs from a
  single pasted command on any fresh laptop.
- **Later — fully unattended (optional).** A Windows Provisioning Package
  (`.ppkg`) built with the free Windows Configuration Designer can run the
  bootstrap at first boot with no clicks.
