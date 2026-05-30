# ClaudeTeleport — One-Click Installer
# Run as: powershell -ExecutionPolicy Bypass -File install.ps1
# Or double-click install.bat

$ErrorActionPreference = "Stop"
$installDir = $PSScriptRoot
$settingsPath = "$env:USERPROFILE\.claude\settings.json"
$localSettingsPath = "$installDir\.claude\settings.local.json"
$claudeFocusCs = "$installDir\ClaudeFocus.cs"
$claudeFocusExe = "$installDir\ClaudeFocus.exe"
$notifyScript = "$installDir\send-claude-notification.ps1"
$libCs = "$installDir\lib\WindowHelper.cs"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ClaudeTeleport Installer" -ForegroundColor Cyan
Write-Host "  Install dir: $installDir" -ForegroundColor DarkGray
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ---- Step 1: Check .NET Framework (csc.exe) ----
Write-Host "[1/5] Checking .NET Framework compiler..." -ForegroundColor Yellow
$cscPaths = @(
    "$env:windir\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
    "$env:windir\Microsoft.NET\Framework\v4.0.30319\csc.exe"
)
$cscExe = $null
foreach ($p in $cscPaths) {
    if (Test-Path $p) { $cscExe = $p; break }
}
if (-not $cscExe) {
    Write-Host "  ERROR: .NET Framework 4.x compiler not found." -ForegroundColor Red
    Write-Host "  Install .NET Framework 4.8: https://dotnet.microsoft.com/download/dotnet-framework" -ForegroundColor Red
    exit 1
}
Write-Host "  OK: $cscExe" -ForegroundColor Green

# ---- Step 2: Check & Install BurntToast ----
Write-Host "[2/5] Checking BurntToast module..." -ForegroundColor Yellow
$bt = Get-Module -Name BurntToast -ListAvailable -ErrorAction SilentlyContinue
if (-not $bt) {
    Write-Host "  BurntToast not found. Installing..." -ForegroundColor DarkYellow
    try {
        Install-Module -Name BurntToast -Scope CurrentUser -Force -ErrorAction Stop
        Write-Host "  BurntToast installed." -ForegroundColor Green
    } catch {
        Write-Host "  ERROR: Failed to install BurntToast." -ForegroundColor Red
        Write-Host "  Try manually: Install-Module -Name BurntToast -Scope CurrentUser -Force" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  OK: BurntToast $($bt[0].Version)" -ForegroundColor Green
}

# ---- Step 3: Compile ClaudeFocus.exe ----
Write-Host "[3/5] Compiling ClaudeFocus.exe..." -ForegroundColor Yellow
try {
    $compileResult = & $cscExe /out:$claudeFocusExe /target:winexe /platform:x86 /nologo $claudeFocusCs 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Compilation output:" -ForegroundColor Red
        Write-Host $compileResult
        throw "csc.exe returned exit code $LASTEXITCODE"
    }
    if (Test-Path $claudeFocusExe) {
        Write-Host "  OK: $claudeFocusExe ($((Get-Item $claudeFocusExe).Length) bytes)" -ForegroundColor Green
    } else {
        throw "EXE not found after compilation"
    }
} catch {
    Write-Host "  ERROR: Compilation failed: $_" -ForegroundColor Red
    Write-Host "  Try running: & '$cscExe' /out:'$claudeFocusExe' /target:winexe /platform:x86 '$claudeFocusCs'" -ForegroundColor Red
    exit 1
}

# ---- Step 4: Register claudecode:// Protocol ----
Write-Host "[4/5] Registering claudecode:// protocol..." -ForegroundColor Yellow
$regPath = "HKCU:\SOFTWARE\Classes\claudecode"
$regCommand = "$regPath\shell\open\command"

# Create protocol handler
New-Item -Path $regPath -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path $regPath -Name "(default)" -Value "URL:Claude Code Protocol" -Force
Set-ItemProperty -Path $regPath -Name "URL Protocol" -Value "" -Force

New-Item -Path "$regPath\shell" -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -Path "$regPath\shell\open" -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -Path $regCommand -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path $regCommand -Name "(default)" -Value "`"$claudeFocusExe`" `"%1`"" -Force

Write-Host "  OK: Protocol registered -> $claudeFocusExe" -ForegroundColor Green

# ---- Step 5: Configure Claude Code Hook ----
Write-Host "[5/5] Configuring Claude Code hook..." -ForegroundColor Yellow

# 5a: Write settings.local.json (permissions)
$localSettingsDir = Split-Path $localSettingsPath -Parent
if (-not (Test-Path $localSettingsDir)) {
    New-Item -ItemType Directory -Path $localSettingsDir -Force | Out-Null
}

$localSettings = @{}
if (Test-Path $localSettingsPath) {
    try {
        $localSettings = Get-Content $localSettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction SilentlyContinue
        if (-not $localSettings) { $localSettings = @{} }
    } catch { $localSettings = @{} }
}

# PowerShell hashtable conversion
$localSettingsJson = $localSettings | ConvertTo-Json -Depth 10
$localSettings = $localSettingsJson | ConvertFrom-Json

# Ensure permissions structure
$hasPermissions = Get-Member -InputObject $localSettings -Name 'permissions' -MemberType Properties -ErrorAction SilentlyContinue
if (-not $hasPermissions) {
    $localSettings | Add-Member -MemberType NoteProperty -Name 'permissions' -Value ([PSCustomObject]@{allow=@()})
}
$hasAllow = Get-Member -InputObject $localSettings.permissions -Name 'allow' -MemberType Properties -ErrorAction SilentlyContinue
if (-not $hasAllow) {
    $localSettings.permissions | Add-Member -MemberType NoteProperty -Name 'allow' -Value @()
}

# Add our permission entries
$newPerms = @(
    "PowerShell(powershell.exe -ExecutionPolicy Bypass -File `"$($notifyScript -replace '\\','\\')`")",
    "PowerShell(New-BurntToastNotification *)",
    "PowerShell(Get-BTAppId *)",
    "PowerShell(Get-Command *)",
    "PowerShell(Add-Type *)"
)

$allowList = @($localSettings.permissions.allow)
$changed = $false
foreach ($perm in $newPerms) {
    if ($perm -notin $allowList) {
        $allowList += $perm
        $changed = $true
    }
}
if ($changed) {
    $localSettings.permissions.allow = $allowList
    $localSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath $localSettingsPath -Encoding UTF8 -Force
    Write-Host "  Permissions updated: $localSettingsPath" -ForegroundColor Green
} else {
    Write-Host "  Permissions already exist: $localSettingsPath" -ForegroundColor DarkGray
}

# 5b: Always write our hook to ~/.claude/settings.json (force-write, deduplicate)
$globalSettings = @{}
if (Test-Path $settingsPath) {
    try {
        $raw = Get-Content $settingsPath -Raw -Encoding UTF8
        if ($raw.Trim()) {
            $globalSettings = ConvertFrom-Json $raw -ErrorAction SilentlyContinue
            if (-not $globalSettings) { $globalSettings = @{} }
        }
    } catch { $globalSettings = @{} }
}
$globalSettingsJson = $globalSettings | ConvertTo-Json -Depth 10
$globalSettings = $globalSettingsJson | ConvertFrom-Json

# Build our hook entry
$ourHook = [PSCustomObject]@{
    matcher = 'permission_prompt'
    hooks = @(
        [PSCustomObject]@{
            type = 'command'
            command = "powershell.exe -ExecutionPolicy Bypass -File `"$notifyScript`""
            shell = 'powershell'
        }
    )
}

# Read existing hooks safely — @() handles null/missing/empty
$oldHooks = @($globalSettings.hooks.Notification)

# Remove any previous ClaudeTeleport entries (by matcher), keep everything else
$cleanHooks = @($oldHooks | Where-Object { $_.matcher -ne 'permission_prompt' })

# Append ours
$allHooks = $cleanHooks + @($ourHook)

# Write back
if (-not (Get-Member -InputObject $globalSettings -Name 'hooks' -MemberType Properties -ErrorAction SilentlyContinue)) {
    $globalSettings | Add-Member -MemberType NoteProperty -Name 'hooks' -Value ([PSCustomObject]@{})
}
$globalSettings.hooks | Add-Member -MemberType NoteProperty -Name 'Notification' -Value $allHooks -Force
$globalSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath $settingsPath -Encoding UTF8 -Force

if ($cleanHooks.Count -eq $oldHooks.Count) {
    Write-Host "  Hook added to: $settingsPath" -ForegroundColor Green
} else {
    Write-Host "  Hook refreshed in: $settingsPath (removed $($oldHooks.Count - $cleanHooks.Count) stale entry)" -ForegroundColor Green
}

# ---- Done ----
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Installation Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  What was set up:" -ForegroundColor White
Write-Host "    - BurntToast module" -ForegroundColor Gray
Write-Host "    - ClaudeFocus.exe (winexe)" -ForegroundColor Gray
Write-Host "    - claudecode:// protocol handler" -ForegroundColor Gray
Write-Host "    - permission_prompt hook" -ForegroundColor Gray
Write-Host "    - Permissions allowlist" -ForegroundColor Gray
Write-Host ""
Write-Host "  To test: trigger a permission prompt in Claude Code" -ForegroundColor White
Write-Host "  Or run: powershell -File `"$PSScriptRoot\test_toast.ps1`"" -ForegroundColor Gray
Write-Host ""
Write-Host "  To uninstall: double-click uninstall.bat" -ForegroundColor White
Write-Host ""
