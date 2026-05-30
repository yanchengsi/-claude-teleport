# ClaudeTeleport — Uninstaller
# Run as: powershell -ExecutionPolicy Bypass -File uninstall.ps1
# Or double-click uninstall.bat

$ErrorActionPreference = "Continue"
$installDir = $PSScriptRoot
$settingsPath = "$env:USERPROFILE\.claude\settings.json"
$localSettingsPath = "$installDir\.claude\settings.local.json"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ClaudeTeleport Uninstaller" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ---- 1: Remove claudecode:// protocol ----
Write-Host "[1/3] Removing claudecode:// protocol..." -ForegroundColor Yellow
$regPath = "HKCU:\SOFTWARE\Classes\claudecode"
if (Test-Path $regPath) {
    Remove-Item -Path $regPath -Recurse -Force
    Write-Host "  OK: Protocol registration removed" -ForegroundColor Green
} else {
    Write-Host "  Protocol not registered, skipping." -ForegroundColor DarkGray
}

# ---- 2: Remove ClaudeTeleport hook from settings.json ----
Write-Host "[2/3] Removing hook from settings.json..." -ForegroundColor Yellow
if (Test-Path $settingsPath) {
    try {
        $raw = Get-Content $settingsPath -Raw -Encoding UTF8
        if ($raw.Trim()) {
            $settings = ConvertFrom-Json $raw -ErrorAction SilentlyContinue
            if ($settings) {
                # Get existing hooks safely, filter out ours
                $allHooks = @($settings.hooks.Notification)
                $keptHooks = @($allHooks | Where-Object { $_.matcher -ne 'permission_prompt' })
                $removedCount = $allHooks.Count - $keptHooks.Count

                if ($removedCount -gt 0) {
                    # Rebuild hooks structure cleanly
                    if (-not (Get-Member -InputObject $settings -Name 'hooks' -MemberType Properties -ErrorAction SilentlyContinue)) {
                        $settings | Add-Member -MemberType NoteProperty -Name 'hooks' -Value ([PSCustomObject]@{})
                    }
                    $settings.hooks | Add-Member -MemberType NoteProperty -Name 'Notification' -Value $keptHooks -Force
                    $settings | ConvertTo-Json -Depth 10 | Out-File -FilePath $settingsPath -Encoding UTF8 -Force
                    Write-Host "  OK: Removed $removedCount ClaudeTeleport hook entry" -ForegroundColor Green
                } else {
                    Write-Host "  Hook not found, skipping." -ForegroundColor DarkGray
                }
            }
        }
    } catch {
        Write-Host "  Warning: Could not process settings.json: $_" -ForegroundColor DarkYellow
    }
} else {
    Write-Host "  settings.json not found, skipping." -ForegroundColor DarkGray
}

# ---- 3: Remove permissions from settings.local.json ----
Write-Host "[3/3] Cleaning up permissions..." -ForegroundColor Yellow
if (Test-Path $localSettingsPath) {
    Remove-Item $localSettingsPath -Force
    Write-Host "  OK: Permissions file removed" -ForegroundColor Green
} else {
    Write-Host "  Permissions file not found, skipping." -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Uninstall Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Files in $installDir were NOT deleted." -ForegroundColor DarkGray
Write-Host "  You can safely delete this folder yourself." -ForegroundColor DarkGray
Write-Host ""
