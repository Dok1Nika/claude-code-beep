# claude-code-beep - Claude Code event notification sound (Windows)
#
# Usage: powershell -NoProfile -NonInteractive -File cc-beep.ps1 <Sound.wav> [Count]
#   e.g. powershell -NoProfile -NonInteractive -File cc-beep.ps1 "Windows Notify.wav" 3
#
# Env vars (optional):
#   CC_BEEP_MEDIA  sound directory (default C:/Windows/Media)
#   CC_BEEP_LOG    log file path   (default %USERPROFILE%\.cc-beep\cc-beep.log)
param([string]$Sound = "tada.wav", [int]$Count = 1)

$mediaDir = if ($env:CC_BEEP_MEDIA) { $env:CC_BEEP_MEDIA } else { "C:/Windows/Media" }
if ($env:CC_BEEP_LOG) {
    $log = $env:CC_BEEP_LOG
} else {
    $logDir = Join-Path $env:USERPROFILE ".cc-beep"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $log = Join-Path $logDir "cc-beep.log"
}
$wav = Join-Path $mediaDir $Sound

# one log line per play (diagnostics)
Add-Content -Path $log -Value ("{0}  sound={1} x{2}  cwd={3}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Sound, $Count, (Get-Location).Path) -Encoding UTF8

if (-not (Test-Path $wav)) {
    Add-Content -Path $log -Value "  ERROR: wav not found: $wav"
    Write-Output "WAV_NOT_FOUND"
    exit 1
}

try {
    $p = New-Object System.Media.SoundPlayer $wav
    $p.Load()
    for ($i = 0; $i -lt $Count; $i++) {
        $p.PlaySync()
        if ($i -lt ($Count - 1)) { Start-Sleep -Milliseconds 100 }
    }
    Write-Output "PLAYED_OK"
    exit 0
} catch {
    Add-Content -Path $log -Value ("  ERROR: {0}" -f $_.Exception.Message)
    Write-Output "PLAY_ERROR"
    exit 1
}
