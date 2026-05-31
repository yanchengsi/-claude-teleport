<h1 align="center">⚡ ClaudeTeleport</h1>
<p align="center">
  <b>One click. Right window. Every time.</b><br>
  <sub>Never lose your Claude Code terminal again.</sub>
</p>

<p align="center">
  <a href="https://yanchengsi.gumroad.com/l/qzvzii"><img src="https://img.shields.io/badge/Buy%20on%20Gumroad-%244.99-FF90E8?style=flat-square&logo=gumroad&logoColor=white&labelColor=000000" alt="Buy on Gumroad"></a>
  <a href="#"><img src="https://img.shields.io/badge/platform-Windows%2010%2F11-0078D6?style=flat-square&logo=windows" alt="Platform"></a>
  <a href="#"><img src="https://img.shields.io/badge/version-v1.1-44cc11?style=flat-square" alt="Version"></a>
  <br>
  <a href="https://github.com/yanchengsi/-claude-teleport"><img src="https://img.shields.io/badge/Open%20Source-%E2%AD%90%20Star%20on%20GitHub-181717?style=flat-square&logo=github" alt="Star on GitHub"></a>
  <a href="https://x.com/vvwnhh"><img src="https://img.shields.io/badge/X-@vvwnhh-1DA1F2?style=flat-square&logo=x" alt="Follow on X"></a>
</p>
<img width="1408" height="736" alt="ClaudeTeleport Windows toast notification screenshot" src="https://github.com/user-attachments/assets/0b3c2c27-3038-4582-888c-b4f6acd5121c" />

---

## What is this?

You're deep in flow. Claude Code hits a permission prompt. The terminal is buried under 17 windows. You don't notice for 5 minutes.

**ClaudeTeleport fixes this.** The instant Claude needs your approval, a native Windows notification appears. Click it. You're there — same window, same session, zero delay.

---

## 🚀 Get It

<p align="center">
  <a href="https://yanchengsi.gumroad.com/l/qzvzii">
    <img src="https://img.shields.io/badge/Buy%20on%20Gumroad-%244.99-FF90E8?style=for-the-badge&logo=gumroad&logoColor=white&labelColor=000000" alt="Buy on Gumroad">
  </a>
  <br>
  <sub>Pre-compiled ZIP · One-click <code>install.bat</code> · All sales final</sub>
</p>

## 🛠 Build from Source

This repo contains the full source code. To build it yourself:

```
# 1. Open PowerShell in this directory
# 2. Compile the focus handler (requires .NET Framework 4.x, built into Windows):

C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /out:ClaudeFocus.exe /target:winexe ClaudeFocus.cs

# 3. Register the claudecode:// protocol manually:
#    HKCU\SOFTWARE\Classes\claudecode\shell\open\command → "ClaudeFocus.exe" "%1"

# 4. Install BurntToast: Install-Module -Name BurntToast -Scope CurrentUser

# 5. Write the permission_prompt hook to ~/.claude/settings.json

# Or: buy the ZIP and run install.bat. Your call.
```

**Verify it works:** ask Claude Code *"Create a file called hello.txt with the word test in it."* You'll see a toast the moment the permission prompt fires.

---

## 🧠 Why This Works (When Raw Hooks Don't)

Claude Code's hooks fire, but they don't know *which* terminal window you're in. ClaudeTeleport calls `GetForegroundWindow()` at hook time — **your active window IS the correct terminal** — and embeds the exact HWND directly into the notification.

| Approach | Accuracy |
|----------|----------|
| Process tree walking (`mintty → bash → claude`) | ❌ Broken on MSYS2 |
| "First mintty wins" | ❌ Wrong window with multiple terminals |
| Window title heuristics | ⚠️ Works ~80% of the time |
| **GetForegroundWindow at hook time → direct HWND** | **✅ 100%** |

Pointer-level precision. No heuristics. Perfect for multi-window setups.

---

## 💻 Compatibility

| Terminal | Support |
|----------|---------|
| Git Bash (mintty) | ✅ Primary target — HWND-level precision |
| Windows Terminal | ✅ Full support |
| CMD / PowerShell | ✅ Full support |
| VS Code / Cursor built-in | ⚠️ Functional via fallback matching |

**Requirements:** Windows 10/11, .NET Framework 4.x (built-in), [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

---

## 💬 Why Pay for Open Source?

The code is here. You can read it, fork it, build it yourself — it'll take an afternoon, and you'll learn something along the way. If that sounds like a fun Saturday, go for it.

**What the $4.99 is really for** is skipping the debugging: the MSYS2 process tree dead ends, the Windows Toast API silently dropping notifications without an AppUserModelID, the registry protocol handler quirks, the reinstall edge cases. All the stuff that isn't in any README.

You're paying for the time the tool saves you, not for the code itself.

This is my first product as a solo dev. If you find it useful, becoming a customer genuinely helps. If you don't want to pay, forking and starring the repo still helps. Either way — thanks for checking it out.

---

## 🔧 Changelog

**v1.1 (2026-05-30)** — Speed optimization

- `WindowHelper.dll` is now precompiled at install time (`/target:library`), replacing runtime JIT compilation
- Notification delay reduced from **~4 seconds → ~1.5 seconds**
- Fallback: if `.dll` is missing for any reason, the script automatically loads `.cs` source instead — no breakage

**v1.0 (2026-05-30)** — Initial release

- `GetForegroundWindow` + direct HWND for 100% accurate terminal focus
- One-click `install.bat` / `uninstall.bat`
- `SetCurrentProcessExplicitAppUserModelID` fix for silent toast drops
- Force-write hook dedup (prevents reinstall failures)

---

## 🐛 Feedback & Issues

Found a bug? Have a feature idea? **Open an issue right here on GitHub.** Pull requests welcome.

You can also reach me on X: [@vvwnhh](https://x.com/vvwnhh)

⭐ **If this helped you, star the repo** — it helps more Claude Code users discover it.

---

## ⚖️ Legal

**Refund Policy:** Due to the digital nature of this product and the inclusion of full source code, all sales are final. No refunds. Please check the compatibility list before purchasing.

**Disclaimer:** This is an independent source-available utility. It is NOT affiliated with, sponsored by, or endorsed by Anthropic or the official Claude Code team.
