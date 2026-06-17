# Laptop Provisioning

Automates the standard new-laptop app setup so admins don't install each app by
hand. Edit one file, every future machine gets the change.

## What gets installed - As Agreed

| App | Windows | Mac |
|-----|:------:|:---:|
| Microsoft Office (Word, Excel, PowerPoint, Outlook) | ✅ | ✅ |
| Microsoft Teams | ✅ | — |
| Slack | ✅ | — |
| Google Chrome | ✅ | — |
| Power BI | ✅ | — |
| AnyDesk | ✅ | — |
| Cortex XDR | manual¹ | — |

Same set for every user. Office is **slimmed** to Word/Excel/PowerPoint/Outlook.
Mac devices only require Microsoft Office.

¹ Cortex XDR is **installed manually by the admin** from the Cortex console — it's
a tenant-specific installer and isn't on winget. The script reminds you at the
end of the run. See [Cortex XDR](#cortex-xdr).

## How to run it

### Windows — easiest (double-click)
1. Get the files onto the laptop (see [Getting the files](#getting-the-files)).
2. Open the `laptop-provisioning\windows` folder and **double-click `install.cmd`**.

It **asks for admin once** (a single UAC prompt — accept it), installs everything,
skips apps already present, retries once on a transient failure, and at the end
prints a **summary** — each app marked Installed / Already present / Failed (with
the reason for any failure) — plus a reminder of the manual steps (Cortex XDR,
Office sign-in).

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

## Cortex XDR

Cortex XDR is **not automated** — the admin installs it manually from the Cortex
console. The agent installer is tenant-specific (carries your org's enrollment
ID), so it deliberately never touches this repo. The install script prints a
reminder to do this at the end of every run.

## Getting the files

The repo is **private**, so a fresh laptop can't fetch it anonymously. Clone it
with an account that has access:

```powershell
gh repo clone ananinja/laptop-provisioning
cd laptop-provisioning
```

**When this repo is public** (an org decision — nothing sensitive lives here;
Cortex is installed manually and never touches the repo), the clone step
disappears and a fresh laptop can run the whole thing with one pasted line:

```powershell
irm https://raw.githubusercontent.com/ananinja/laptop-provisioning/main/windows/bootstrap.ps1 | iex
```

That's the eventual hands-off goal. Until then, use the clone + `install.cmd` flow.


## Repo layout

```
laptop-provisioning/
├─ windows/
│  ├─ apps.json         # winget app list - single source of truth
│  ├─ office-config.xml # which Office apps install (Word/Excel/PowerPoint/Outlook)
│  ├─ install.cmd       # double-click installer (launches install.ps1)
│  ├─ install.ps1       # installs the winget apps, prints a summary
│  ├─ uninstall.cmd     # double-click uninstaller (launches uninstall.ps1)
│  ├─ uninstall.ps1     # removes the winget apps (with confirmation)
│  └─ bootstrap.ps1     # one-liner entry point (for when the repo is public)
├─ mac/
│  ├─ Brewfile          # the app list (Homebrew) - Office only
│  ├─ bootstrap.sh      # installs Homebrew, then the list
│  └─ uninstall.sh      # removes the Mac baseline (Office)
└─ README.md
```
