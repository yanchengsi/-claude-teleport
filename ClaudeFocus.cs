using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;

class Program {
    [DllImport("user32.dll")]
    static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")]
    static extern bool IsIconic(IntPtr hWnd);
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    static extern int GetWindowTextLength(IntPtr hWnd);
    [DllImport("user32.dll")]
    static extern int GetWindowThreadProcessId(IntPtr hWnd, out int lpdwProcessId);
    [DllImport("user32.dll")]
    static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll")]
    static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    [DllImport("kernel32.dll")]
    static extern uint GetCurrentThreadId();
    delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    const int SW_RESTORE = 9;
    const int SW_SHOW = 5;

    struct WindowInfo {
        public IntPtr Handle;
        public string Title;
        public int ProcessId;
        public string ProcessName;
    }

    static List<WindowInfo> windows = new List<WindowInfo>();

    static void Main(string[] args) {
        string url = args.Length > 0 ? args[0] : "";
        string logPath = Environment.ExpandEnvironmentVariables(@"%TEMP%\claude_focus_log.txt");

        var log = new List<string>();
        log.Add("=== " + DateTime.Now.ToString("o") + " ===");
        log.Add("URL: " + url);

        // Parse parameters from URL: claudecode://focus?hwnd=XXXXX  or  ?pid=XXXX
        IntPtr directHwnd = IntPtr.Zero;
        int targetPid = 0;
        if (!string.IsNullOrEmpty(url)) {
            // Preferred: direct HWND (set by hook, 100% accurate)
            var hwndMatch = System.Text.RegularExpressions.Regex.Match(url, @"[?&]hwnd=(\d+)");
            if (hwndMatch.Success) {
                directHwnd = new IntPtr(long.Parse(hwndMatch.Groups[1].Value));
            }
            // Fallback: PID
            var pidParts = url.Split(new[] { "?pid=" }, StringSplitOptions.None);
            if (pidParts.Length > 1) int.TryParse(pidParts[1], out targetPid);
        }
        log.Add("Direct HWND: " + directHwnd + "  Target PID: " + targetPid);

        IntPtr hwnd = IntPtr.Zero;

        // Priority 1: Direct HWND from hook (most reliable)
        if (directHwnd != IntPtr.Zero && IsWindowVisible(directHwnd)) {
            hwnd = directHwnd;
            log.Add("Using direct HWND from hook");
        } else {
            if (directHwnd != IntPtr.Zero) {
                log.Add("Direct HWND is not visible, falling back to search");
            }

            // Still enumerate windows for logging and fallback search
            EnumWindows(delegate(IntPtr hWnd, IntPtr param) {
                if (!IsWindowVisible(hWnd)) return true;
                int length = GetWindowTextLength(hWnd);
                var sb = new StringBuilder(Math.Max(length + 1, 256));
                GetWindowText(hWnd, sb, sb.Capacity);
                int pid;
                GetWindowThreadProcessId(hWnd, out pid);
                string pname = "";
                try { pname = Process.GetProcessById(pid).ProcessName; } catch { }
                string title = sb.ToString();
                if (string.IsNullOrEmpty(title) && !IsTerminalProcess(pname)) return true;
                windows.Add(new WindowInfo { Handle = hWnd, Title = title, ProcessId = pid, ProcessName = pname });
                return true;
            }, IntPtr.Zero);

            log.Add(string.Format("All visible windows ({0}):", windows.Count));
            foreach (var w in windows) {
                log.Add(string.Format("  [{0}] {1} : {2}", w.ProcessId, w.ProcessName, w.Title));
            }

            // Find and focus
            hwnd = FindClaudeCodeWindow(targetPid);
        }
        if (hwnd != IntPtr.Zero) {
            var sb = new StringBuilder(512);
            GetWindowText(hwnd, sb, 512);
            int focusedPid;
            GetWindowThreadProcessId(hwnd, out focusedPid);
            log.Add(string.Format(">> FOCUSED: HWND={0} PID={1} Title={2}", hwnd, focusedPid, sb));
            FocusWindow(hwnd);
        } else {
            log.Add(">> No Claude Code window found!");
        }

        System.IO.File.WriteAllLines(logPath, log, Encoding.UTF8);
    }

    static bool IsTerminalProcess(string name) {
        string n = name.ToLowerInvariant();
        return n.Contains("mintty") || n.Contains("cmd") || n.Contains("powershell")
            || n.Contains("pwsh") || n.Contains("windowsterminal") || n.Contains("bash")
            || n.Contains("conhost") || n.Contains("terminal")
            || n.Contains("claudefocus"); // exclude ourselves
    }

    static IntPtr FindClaudeCodeWindow(int targetPid) {
        // Priority 0: If target PID known, find its window via process tree
        if (targetPid > 0) {
            try {
                var proc = Process.GetProcessById(targetPid);
                // Walk up to find terminal window
                var visited = new HashSet<int>();
                var current = proc;
                for (int i = 0; i < 10 && current != null; i++) {
                    if (!visited.Add(current.Id)) break;
                    string name = current.ProcessName.ToLowerInvariant();
                    IntPtr wh = current.MainWindowHandle;
                    if ((name == "mintty" || name == "conhost" || name == "cmd" ||
                         name == "powershell" || name == "pwsh" || name == "windowsterminal")
                        && wh != IntPtr.Zero) {
                        return wh;
                    }
                    try {
                        // Get parent via WMI
                        using (var searcher = new System.Management.ManagementObjectSearcher(
                            "SELECT ParentProcessId FROM Win32_Process WHERE ProcessId=" + current.Id)) {
                            foreach (var obj in searcher.Get()) {
                                uint parentId = (uint)obj["ParentProcessId"];
                                if (parentId > 0)
                                    current = Process.GetProcessById((int)parentId);
                                else
                                    current = null;
                                break;
                            }
                        }
                    } catch { break; }
                }
            } catch { }
        }

        // Priority 1: Window title contains "Claude Code"
        foreach (var w in windows) {
            if (w.Title.Contains("Claude Code")) return w.Handle;
        }
        // Priority 2: "claude"
        foreach (var w in windows) {
            if (w.Title.ToLowerInvariant().Contains("claude")) return w.Handle;
        }
        // Priority 3: MINGW
        foreach (var w in windows) {
            if (w.Title.ToLowerInvariant().Contains("mingw")) return w.Handle;
        }
        // Priority 4: mintty process
        foreach (var w in windows) {
            if (w.ProcessName.ToLowerInvariant() == "mintty") return w.Handle;
        }
        // Priority 5: bash or git
        foreach (var w in windows) {
            if (w.Title.ToLowerInvariant().Contains("bash") || w.Title.ToLowerInvariant().Contains("git"))
                return w.Handle;
        }
        return IntPtr.Zero;
    }

    static void FocusWindow(IntPtr hWnd) {
        if (hWnd == IntPtr.Zero) return;
        if (IsIconic(hWnd)) ShowWindow(hWnd, SW_RESTORE);
        else ShowWindow(hWnd, SW_SHOW);
        uint currentThread = GetCurrentThreadId();
        int processId;
        uint targetThread = (uint)GetWindowThreadProcessId(hWnd, out processId);
        bool attached = false;
        if (currentThread != targetThread) {
            attached = AttachThreadInput(currentThread, targetThread, true);
        }
        SetForegroundWindow(hWnd);
        if (attached) AttachThreadInput(currentThread, targetThread, false);
    }
}
