# Local installers (not committed)

This folder is **gitignored** on purpose. Files here never get pushed to the
repo, so tenant-specific or sensitive installers stay private even if the repo
goes public.

## Cortex XDR

Cortex XDR isn't on winget — its agent installer is tenant-specific (it carries
your org's enrollment ID). The install script downloads it from a **private URL**
at runtime instead of bundling it.

Set the URL in **one** of these ways (the script checks them in this order):

1. Environment variable:

   ```powershell
   setx CORTEX_MSI_URL "https://...your-presigned-or-private-url..."
   ```

2. A `cortex.url` file in this folder containing just the URL:

   ```
   windows/installers/cortex.url
   ```

Recommended hosting: a **private S3 bucket** with a **presigned URL** (no AWS
credentials needed on the laptop, and the link auto-expires). A Google Drive
link can work too, but Drive's large-file "virus scan" redirect can break
scripted downloads — S3 is more reliable.

If no URL is set, the script **skips** Cortex (it won't fail the run) and notes
it in the summary.
