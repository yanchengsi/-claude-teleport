using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Collections.Generic;
using System.Diagnostics;

public class WindowHelper {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr hWnd);
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern int GetWindowTextLength(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern int GetWindowThreadProcessId(IntPtr hWnd, out int lpdwProcessId);
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll")]
    public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")]
    public static extern uint GetWindowModuleFileName(IntPtr hWnd, StringBuilder sb, uint max);
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    private const int SW_RESTORE = 9;
    private const int SW_SHOW = 5;

    public class WindowInfo {
        public IntPtr Handle;
        public string Title;
        public int ProcessId;
        public string ProcessName;
    }

    public static void FocusWindow(IntPtr hWnd) {
        if (hWnd == IntPtr.Zero) return;
        if (IsIconic(hWnd)) { ShowWindow(hWnd, SW_RESTORE); }
        else { ShowWindow(hWnd, SW_SHOW); }
        uint currentThread = GetCurrentThreadId();
        int processId;
        uint targetThread = (uint)GetWindowThreadProcessId(hWnd, out processId);
        bool attached = false;
        if (currentThread != targetThread) {
            attached = AttachThreadInput(currentThread, targetThread, true);
        }
        SetForegroundWindow(hWnd);
        if (attached) { AttachThreadInput(currentThread, targetThread, false); }
    }

    public static List<WindowInfo> GetAllVisibleWindows() {
        var windows = new List<WindowInfo>();
        EnumWindows(delegate(IntPtr hWnd, IntPtr param) {
            if (!IsWindowVisible(hWnd)) return true;
            int length = GetWindowTextLength(hWnd);
            var sb = new StringBuilder(Math.Max(length + 1, 256));
            GetWindowText(hWnd, sb, sb.Capacity);
            int pid;
            GetWindowThreadProcessId(hWnd, out pid);
            string pname = "";
            try { pname = Process.GetProcessById(pid).ProcessName; } catch {}
            string title = sb.ToString();
            // Include even windows with empty titles - they might be mintty/Git Bash
            if (string.IsNullOrEmpty(title) && !IsTerminalProcess(pname)) return true;
            windows.Add(new WindowInfo { Handle = hWnd, Title = title, ProcessId = pid, ProcessName = pname });
            return true;
        }, IntPtr.Zero);
        return windows;
    }

    private static bool IsTerminalProcess(string name) {
        string n = name.ToLowerInvariant();
        return n.Contains("mintty") || n.Contains("cmd") || n.Contains("powershell")
            || n.Contains("pwsh") || n.Contains("windowsterminal") || n.Contains("bash")
            || n.Contains("conhost") || n.Contains("terminal");
    }

    public static List<WindowInfo> FindAllTerminalWindows() {
        var windows = GetAllVisibleWindows();
        var terminals = new List<WindowInfo>();
        foreach (var w in windows) {
            string t = w.Title.ToLowerInvariant();
            string p = w.ProcessName.ToLowerInvariant();
            if (IsTerminalProcess(p)) terminals.Add(w);
            else if (t.Contains("mingw") || t.Contains("bash") || t.Contains("claude")
                  || t.Contains("powershell") || t.Contains("cmd")) terminals.Add(w);
        }
        return terminals;
    }

    public static IntPtr FindClaudeCodeWindow() {
        // Priority 1: Window title contains "Claude Code"
        var windows = GetAllVisibleWindows();
        foreach (var w in windows) {
            if (w.Title.Contains("Claude Code")) return w.Handle;
        }
        // Priority 2: Window title contains "claude" (case insensitive)
        foreach (var w in windows) {
            if (w.Title.ToLowerInvariant().Contains("claude")) return w.Handle;
        }
        // Priority 3: Git Bash / MINGW / mintty windows (most common for Claude Code on Windows)
        foreach (var w in windows) {
            string t = w.Title.ToLowerInvariant();
            if (t.Contains("mingw")) return w.Handle;
        }
        foreach (var w in windows) {
            string p = w.ProcessName.ToLowerInvariant();
            if (p == "mintty") return w.Handle;
        }
        // Priority 4: "bash" or "git" in title
        foreach (var w in windows) {
            string t = w.Title.ToLowerInvariant();
            if (t.Contains("bash") || t.Contains("git")) return w.Handle;
        }
        // Priority 5: PowerShell
        foreach (var w in windows) {
            string t = w.Title.ToLowerInvariant();
            if (t.Contains("powershell") || w.ProcessName.ToLowerInvariant().Contains("powershell")) return w.Handle;
        }
        // Priority 6: Cmd or Windows Terminal
        foreach (var w in windows) {
            string t = w.Title.ToLowerInvariant();
            string p = w.ProcessName.ToLowerInvariant();
            if (t.Contains("cmd") || p.Contains("windowsterminal") || p.Contains("conhost")) return w.Handle;
        }
        return IntPtr.Zero;
    }
}
