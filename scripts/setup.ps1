# Fleet Snowfluff — one-shot local install (theme extension + Vibrancy assets + settings).
# Usage: from repo root  .\scripts\setup.ps1
#
# Prerequisites: Cursor (or VS Code) + Vibrancy Continued extension installed.
# Then: Vibrancy: Enable (first time only) → Vibrancy: Reload → fully quit and restart.

& (Join-Path $PSScriptRoot 'setup-vibrancy.ps1') @args
