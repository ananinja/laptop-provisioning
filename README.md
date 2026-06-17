# Laptop Provisioning

Automates the standard new-laptop app setup so admins don't install each app by hand.
Edit one file, every future machine gets the change.

## What gets installed

| App | Windows | Mac |
|-----|:------:|:---:|
| Microsoft Office 365 | ✅ | ✅ |
| Microsoft Teams | ✅ | — |
| Slack | ✅ | — |
| Google Chrome | ✅ | — |
| Power BI | ✅ | — |

Same set for every user (no per-team variations yet).
Mac devices only require Microsoft Office.

## How to use it

### Windows
On a fresh laptop, open **PowerShell** and paste:

```powershell
irm https://raw.githubusercontent.com/ananinja/laptop-provisioning/main/windows/bootstrap.ps1 | iex
```

Requires Windows 10 (1809+) or Windows 11 — `winget` ships with both. If it's
missing, install **App Installer** from the Microsoft Store and re-run.

### Mac
On a fresh Mac, open **Terminal** and paste:

```bash
curl -fsSL https://raw.githubusercontent.com/ananinja/laptop-provisioning/main/mac/bootstrap.sh | bash
```

Installs Homebrew automatically if it isn't already there.

## ⚠️ Office licensing

The scripts **install** Microsoft Office, but activation is per-user: the new
hire must sign in with their Microsoft 365 Business account to license it.
That step stays manual.

## Changing the app list

- **Windows:** edit `windows/apps.json` — add a line with the app's winget ID.
  Find an ID with `winget search "<app name>"`.
- **Mac:** edit `mac/Brewfile` — add a `cask "<name>"` line.
  Find a name with `brew search <app name>`.

Commit the change. Every laptop provisioned afterward picks it up automatically.
Re-running the command on an existing machine is safe — already-installed apps
are skipped, so it doubles as a "top up missing apps" tool.

## Repo layout

```
laptop-provisioning/
├─ windows/
│  ├─ apps.json        # the app list (winget manifest)
│  └─ bootstrap.ps1    # downloads the list and installs it
├─ mac/
│  ├─ Brewfile         # the app list (Homebrew)
│  └─ bootstrap.sh     # installs Homebrew, then the list
└─ README.md
```

## Roadmap

- **Now — admin pastes a command** (above). Proven, zero infrastructure.
- **Next — fully unattended** (optional). A Windows Provisioning Package (`.ppkg`)
  built with the free Windows Configuration Designer can run the bootstrap at
  first boot with no clicks. Build after the paste-a-command flow is verified.
