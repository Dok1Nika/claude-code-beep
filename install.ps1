#Requires -Version 5.1
<#
  claude-code-beep - one-click installer
  - copies cc-beep.ps1 to install dir (default %USERPROFILE%\.cc-beep\)
  - merges hooks (permission / stop / subagent) into target settings.json, preserving existing keys

  Usage:
    powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1
        # default: user-level ~/.claude/settings.json (global, recommended)
    powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1 -Target .claude\settings.json
        # project-level (shared via git)
    powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1 -ScriptDir D:\my-tools
        # custom script install dir

  Idempotent: safe to re-run (merges, never clobbers).
#>
param(
    [string]$Target = "",
    [string]$ScriptDir = ""
)

$ErrorActionPreference = 'Stop'

if (-not $ScriptDir) { $ScriptDir = Join-Path $env:USERPROFILE ".cc-beep" }
if (-not $Target)    { $Target    = Join-Path $env:USERPROFILE ".claude\settings.json" }

# 1) copy the playback script
New-Item -ItemType Directory -Path $ScriptDir -Force | Out-Null
$src = Join-Path $PSScriptRoot "cc-beep.ps1"
if (-not (Test-Path $src)) { throw "cc-beep.ps1 not found next to install.ps1" }
Copy-Item $src (Join-Path $ScriptDir "cc-beep.ps1") -Force

# 2) build hook commands. Use forward-slash path (avoids backslash/JSON escaping)
#    and quote filenames that contain spaces.
$script = (Join-Path $ScriptDir "cc-beep.ps1").Replace('\', '/')

$cmdPerm = "powershell -NoProfile -NonInteractive -File `"$script`" `"Windows Exclamation.wav`""
$cmdStop = "powershell -NoProfile -NonInteractive -File `"$script`" tada.wav"
$cmdSub  = "powershell -NoProfile -NonInteractive -File `"$script`" `"Windows Notify.wav`" 3"

$hooks = @{
    PermissionRequest = @(
        @{ matcher = '*'; hooks = @(@{ type = 'command'; command = $cmdPerm; timeout = 10 }) }
    )
    Stop = @(
        @{ matcher = 'Stop'; hooks = @(@{ type = 'command'; command = $cmdStop; timeout = 10 }) }
    )
    Notification = @(
        @{ matcher = 'SubagentStop'; hooks = @(@{ type = 'command'; command = $cmdSub; timeout = 10 }) }
    )
}

# 3) merge into target settings.json, preserving existing keys
$targetDir = Split-Path $Target
if ($targetDir -and -not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }

$existing = @{}
if (Test-Path $Target) {
    $raw = Get-Content $Target -Raw -Encoding UTF8
    if ($raw -and $raw.Trim()) {
        $parsed = $raw | ConvertFrom-Json
        foreach ($p in $parsed.PSObject.Properties) { $existing[$p.Name] = $p.Value }
    }
}
$existing['hooks'] = $hooks

$json = $existing | ConvertTo-Json -Depth 12
[System.IO.File]::WriteAllText($Target, $json, (New-Object System.Text.UTF8Encoding $false))

Write-Host ""
Write-Host "[OK] script installed at: $script"
Write-Host "[OK] hooks merged into:   $Target"
Write-Host ""
Write-Host "Next: fully quit VS Code and reopen (or start a new Claude Code session) - hooks load at session start."
Write-Host "Verify: ask Claude to run a non-allowlisted command (hear Windows Exclamation), then send any message (hear tada when the reply finishes)."
Write-Host "Diagnose: check log at %USERPROFILE%\.cc-beep\cc-beep.log"
