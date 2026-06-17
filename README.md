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

Same set for every user (no per-team variations). Mac devices only require Microsoft Office.

## How to run it

### Windows — easiest (double-click)
1. Get the files onto the laptop (see [Getting the files](#getting-the-files) below).
2. Open the `laptop-provisioning\windows` folder and **double-click `install.cmd`**.

That's it. It **asks for admin once** (a single UAC prompt — accept it; Office,
Chrome and Power BI are machine-wide installers that need it), installs the
baseline, skips apps already present, retries once on a transient failure, and at
the end prints a **summary** — each app marked Installed / Already present /
Failed (with the reason for any failure).

Prefer the terminal? In **PowerShell**, from the repo folder:

```powershell
.\windows\install.cmd
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

To remove the baseline apps (e.g. offboarding or resetting a machine),
**double-click `uninstall.cmd`** in the `windows` folder, or run:

```powershell
.\windows\uninstall.ps1
```

It lists what it's about to remove and asks for confirmation first, skips apps that
aren't installed, and prints the same kind of summary (Uninstalled / Not present /
Failed). Add `-Force` to skip the prompt for unattended use.

## Getting the files

The repo is **private**, so a fresh laptop can't fetch it anonymously. Clone it with
an account that has access:

```powershell
gh repo clone ananinja/laptop-provisioning
cd laptop-provisioning
```

**When this repo is public** (an org decision — it holds no secrets, only public
app names and scripts), the clone step disappears and a fresh laptop can run the
whole thing with one pasted line:

```powershell
irm https://raw.githubusercontent.com/ananinja/laptop-provisioning/main/windows/bootstrap.ps1 | iex
```

That's the eventual hands-off goal. Until then, use the clone + `install.cmd` flow above.

## ⚠️ Office licensing

The scripts **install** Microsoft Office, but activation is per-user: the new hire
must sign in with their Microsoft 365 Business account to license it. That step
stays manual.

## Changing the app list

- **Windows:** edit `windows/apps.json` — add a line with the app's winget ID.
  Find an ID with `winget search "<app name>"`.
- **Mac:** edit `mac/Brewfile` — add a `cask "<name>"` line.
  Find a name with `brew search <app name>`.

Commit the change. Every laptop provisioned afterward picks it up automatically.
Re-running is safe — already-installed apps are skipped, so it doubles as a
"top up missing apps" tool.

## Repo layout

```
laptop-provisioning/
├─ windows/
│  ├─ apps.json        # the app list (winget manifest) - single source of truth
│  ├─ install.cmd      # double-click installer (launches install.ps1)
│  ├─ install.ps1      # installs each app, prints a summary at the end
│  ├─ uninstall.cmd    # double-click uninstaller (launches uninstall.ps1)
│  ├─ uninstall.ps1    # removes each app (with confirmation), prints a summary
│  └─ bootstrap.ps1    # one-liner entry point (for when the repo is public)
├─ mac/
│  ├─ Brewfile         # the app list (Homebrew) - Office only
│  ├─ bootstrap.sh     # installs Homebrew, then the list
│  └─ uninstall.sh     # removes the Mac baseline (Office)
└─ README.md
```

## Roadmap

- **Now — clone + `install.cmd`.** Proven, works on a private repo, zero infrastructure.
- **Next — one-line paste.** Make the repo public so `bootstrap.ps1` runs from a single
  pasted command on any fresh laptop.
- **Later — fully unattended (optional).** A Windows Provisioning Package (`.ppkg`)
  built with the free Windows Configuration Designer can run the bootstrap at first
  boot with no clicks. Build after the paste-a-command flow is verified.
