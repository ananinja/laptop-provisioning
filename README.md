# Laptop Provisioning

Automates the standard new-laptop app setup so admins don't install each app by
hand. Edit one file, every future machine gets the change.

**Service desk: see [SERVICE-DESK-GUIDE.md](SERVICE-DESK-GUIDE.md)** for the
simple step-by-step. The rest of this README is for maintainers.

## What gets installed - As Agreed

| App | Windows | Mac |
|-----|:------:|:---:|
| Microsoft Office (Microsoft 365) | ✅ | ✅ |
| Microsoft Teams | ✅ | — |
| Slack | ✅ | — |
| Google Chrome | ✅ | — |
| Power BI | ✅ | — |
| AnyDesk | ✅ | — |
| Cortex XDR | manual¹ | — |

Same set for every user. Office installs last (it's the slowest). Mac devices
only require Microsoft Office.

¹ Cortex XDR is **installed manually by the admin** from the Cortex console — it's
a tenant-specific installer and isn't on winget. The script reminds you at the
end of the run. See [Cortex XDR](#cortex-xdr).

## How to run it

### Windows — one line (recommended)
On a fresh laptop, open **PowerShell** and paste:

```powershell
irm https://raw.githubusercontent.com/ananinja/laptop-provisioning/main/windows/bootstrap.ps1 | iex
```

No git, no GitHub login, nothing to install first. It downloads the toolkit,
**asks for admin once** (a single UAC prompt — accept it), installs everything,
skips apps already present, retries once on a transient failure, and at the end
prints a **summary** — each app marked Installed / Already present / Failed (with
the reason for any failure) — plus a reminder of the manual steps (Cortex XDR,
Office sign-in).

### Windows — from a local copy
If you've cloned/downloaded the repo (see [Getting the files](#getting-the-files)),
just **double-click `install.cmd`** in the `windows` folder, or in PowerShell:

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

For a normal install you **don't need the files** — use the one-line command
above. You only need a local copy to **edit the app list** or run from a folder:

```powershell
git clone https://github.com/ananinja/laptop-provisioning.git
cd laptop-provisioning
```

The repo is public and holds nothing sensitive (Cortex is installed manually and
never touches the repo), which is what lets the one-liner work with no login.


## Repo layout

```
laptop-provisioning/
├─ windows/
│  ├─ apps.json         # winget app list - single source of truth
│  ├─ install.cmd       # double-click installer (launches install.ps1)
│  ├─ install.ps1       # installs the winget apps, prints a summary
│  ├─ uninstall.cmd     # double-click uninstaller (launches uninstall.ps1)
│  ├─ uninstall.ps1     # removes the winget apps (with confirmation)
│  └─ bootstrap.ps1     # one-liner entry point (downloads + runs the toolkit)
├─ mac/
│  ├─ Brewfile          # the app list (Homebrew) - Office only
│  ├─ bootstrap.sh      # installs Homebrew, then the list
│  └─ uninstall.sh      # removes the Mac baseline (Office)
└─ README.md
```
