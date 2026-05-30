# Send Claude Code permission prompt notification
# Strategy: GetForegroundWindow (hook fires while user is in Claude Code) > title heuristics

$logFile = "$env:TEMP\claude_notify_log.txt"
$log = @()
$log += "=== $(Get-Date -Format 'o') ==="
$log += "Hook PID: $PID"

# Load WindowHelper from precompiled DLL (install.ps1 compiles this at install time — no JIT delay)
$dllPath = "$PSScriptRoot\lib\WindowHelper.dll"
if (Test-Path $dllPath) {
    Add-Type -Path $dllPath -ErrorAction Stop
} else {
    $log += "DLL not found, falling back to CS compile (will be slow)"
    Add-Type -Path "$PSScriptRoot\lib\WindowHelper.cs" -ErrorAction Stop
}

$hwnd = [IntPtr]::Zero

# Strategy 1: GetForegroundWindow 鈥?hook fires while user is interacting with Claude Code
$fgHwnd = [WindowHelper]::GetForegroundWindow()
$log += "Foreground window HWND: $fgHwnd"

if ($fgHwnd -ne [IntPtr]::Zero) {
    $fgPid = 0
    [WindowHelper]::GetWindowThreadProcessId($fgHwnd, [ref]$fgPid)
    try {
        $fgProc = Get-Process -Id $fgPid -ErrorAction Stop
        $fgTitle = $fgProc.MainWindowTitle
        $log += "Foreground: PID=$fgPid name=$($fgProc.ProcessName) title='$fgTitle'"
        if ($fgProc.ProcessName -eq 'mintty') {
            $hwnd = $fgHwnd
            $log += ">> Using foreground mintty window!"
        }
    } catch {
        $log += "Foreground check failed: $_"
    }
}

# Strategy 2: Title heuristics 鈥?Claude Code windows have long descriptive titles
if ($hwnd -eq [IntPtr]::Zero) {
    $log += "Foreground is not mintty, searching all mintty windows..."
    $windows = [WindowHelper]::GetAllVisibleWindows()

    $minttyWindows = $windows | Where-Object { $_.ProcessName -eq 'mintty' }
    $log += "Mintty windows: $($minttyWindows.Count)"
    foreach ($w in $minttyWindows) {
        $log += "  PID=$($w.ProcessId) title='$($w.Title)' (len=$($w.Title.Length))"
    }

    # Exclude bare cmd.exe terminals (they just show "C:\WINDOWS\system32\cmd.exe")
    $candidates = @($minttyWindows | Where-Object {
        $_.Title -notmatch 'cmd\.exe' -and $_.Title.Trim().Length -gt 0
    })
    $log += "Non-cmd candidates: $($candidates.Count)"

    if ($candidates.Count -gt 0) {
        # Pick the one with the longest title 鈥?Claude Code has descriptive status bar titles
        $best = ($candidates | Sort-Object { $_.Title.Length } -Descending)[0]
        $hwnd = $best.Handle
        $log += ">> Best match: PID=$($best.ProcessId) title='$($best.Title)'"
    } else {
        # Last resort: first mintty
        $first = @($minttyWindows)[0]
        if ($first) {
            $hwnd = $first.Handle
            $log += ">> Last resort: PID=$($first.ProcessId) title='$($first.Title)'"
        }
    }
}

$btnArg = if ($hwnd -ne [IntPtr]::Zero) {
    "claudecode://focus?hwnd=$hwnd"
} else {
    $log += "WARNING: No mintty window found!"
    "claudecode://focus"
}
$log += "Button arg: $btnArg"

# MUST be called before any toast — Windows 10/11 silently drops notifications without AppUserModelID
$ToastFix = Add-Type -MemberDefinition @"
[DllImport("shell32.dll", SetLastError = true)]
public static extern int SetCurrentProcessExplicitAppUserModelID(
    [MarshalAs(UnmanagedType.LPWStr)] string AppID);
"@ -Name "ToastFix" -PassThru
$ToastFix::SetCurrentProcessExplicitAppUserModelID('Microsoft.Windows.Explorer') | Out-Null

Import-Module BurntToast -ErrorAction SilentlyContinue
$btn = New-BTButton -Content 'Go to Claude Code' -Arguments $btnArg
$title = "[ClaudeTeleport] $([char]::ConvertFromUtf32(0x1F6A8)) Claude needs approval"
$body = "Claude Code is waiting for your confirmation!"
New-BurntToastNotification -Text $title, $body -Sound 'IM' -Button $btn

$log += "Toast sent."
$log | Out-File -FilePath $logFile -Encoding UTF8 -Force
if ($hwnd -ne [IntPtr]::Zero) { Write-Output $hwnd }
