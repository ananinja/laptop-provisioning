# New Laptop Setup — Service Desk Guide

Set up a new Windows laptop with all the standard apps using **one command**.

---

## Before you start

- The laptop is **Windows 10 or 11**.
- It's **connected to the internet**.
- You can sign in / click "Yes" on an admin prompt.

## Step 1 — Open PowerShell

Click **Start**, type **PowerShell**, and press **Enter**.

## Step 2 — Paste this one command and press Enter

```powershell
irm https://raw.githubusercontent.com/ananinja/laptop-provisioning/main/windows/bootstrap.ps1 | iex
```

## Step 3 — Click "Yes" on the admin prompt

A Windows prompt will ask for permission (User Account Control). Click **Yes**.
A new window opens and does the work — you can watch the progress.

## Step 4 — Wait for it to finish

It installs these automatically, one by one:

- Microsoft Teams
- Slack
- Google Chrome
- Power BI
- AnyDesk
- Microsoft Office *(installed last — it's the biggest, can take 10–30 min)*

You'll see a **"...still working"** progress line so you know it's running.
When it's done, a **SUMMARY** lists each app as *Installed* or *Already present*.

---

## After it finishes — 2 manual steps

The script reminds you of these at the end:

1. **Install Cortex XDR** from the Cortex console (the usual way — its installer is private, so it can't be automated).
2. **Sign into Microsoft 365** in any Office app (Word/Outlook) to activate Office.

---

## Good to know

- **Safe to re-run.** If something was interrupted, just run the command again — it skips anything already installed and only does what's missing.
- **Already have some apps?** No problem — they're detected and skipped.
- **Office looks frozen?** It doesn't — it's just large. As long as you see activity, let it finish.

## If something fails

- The summary shows which app failed and why.
- A full log is saved here (helpful if you need to report an issue):
  `C:\Users\<you>\AppData\Local\Temp\laptop-provisioning-logs\`
- Re-running the command often fixes a one-off hiccup.

## Questions / issues

Contact **Abdalrahman** (IT) with a screenshot of the summary.
