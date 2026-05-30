<h1 align="center">⚡ ClaudeTeleport</h1>
<p align="center">
  <b>One click. Right window. Every time.</b><br>
  <sub>Never lose your Claude Code terminal again.</sub>
</p>

<p align="center">
  <a href="https://yanchengsi.gumroad.com/l/qzvzii"><img src="https://img.shields.io/badge/Buy%20on%20Gumroad-%244.99-FF90E8?style=flat-square&logo=gumroad&logoColor=white&labelColor=000000" alt="Buy on Gumroad"></a>
  <a href="#"><img src="https://img.shields.io/badge/platform-Windows%2010%2F11-0078D6?style=flat-square&logo=windows" alt="Platform"></a>
  <a href="#"><img src="https://img.shields.io/badge/version-v1.1-44cc11?style=flat-square" alt="Version"></a>
</p>

---

## What is this?

You're deep in flow. Claude Code hits a permission prompt. The terminal is buried under 17 windows. You don't notice for 5 minutes.

**ClaudeTeleport fixes this.** The instant Claude needs your approval, a native Windows notification appears. Click it. You're there — same window, same session, zero delay.

---

## 🚀 Quick Start

```bash
# 1. Download the ZIP (or git clone)
# 2. Double-click:

install.bat

# 3. Done. Seriously, that's it.
```

**Verify it works:** ask Claude Code *"Create a file called hello.txt with the word test in it."* You'll see a toast the moment the permission prompt fires.

To remove: double-click `uninstall.bat`.

---

## 🧠 Why This Actually Works

Most tools guess which terminal to focus. We don't.

| Approach | Accuracy |
|----------|----------|
| Process tree walking (`mintty → bash → claude`) | ❌ Broken on MSYS2 |
| "First mintty wins" | ❌ Wrong window if you have multiple |
| Window title heuristics | ⚠️ Works ~80% of the time |
| **GetForegroundWindow at hook time → direct HWND** | **✅ 100%** |

When Claude Code fires a permission prompt, **your active window IS the correct terminal**. We capture the HWND at that exact millisecond and embed it in the notification button. No guessing. No heuristics. Pointer-level precision.

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

## 🛒 Get It

<p align="center">
  <a href="https://yanchengsi.gumroad.com/l/qzvzii">
    <img src="https://img.shields.io/badge/Buy%20on%20Gumroad-%244.99-FF90E8?style=for-the-badge&logo=gumroad&logoColor=white&labelColor=000000" alt="Buy on Gumroad">
  </a>
  <br>
  <sub>Standard License $4.99 · Full source code included · All sales final</sub>
</p>

---

## ⚖️ Legal

**Refund Policy:** Due to the digital nature of this product and the inclusion of full source code in the package, all sales are final. No refunds. Please check the compatibility list before purchasing.

**Disclaimer:** This is an independent open-source/source-available utility. It is NOT affiliated with, sponsored by, or endorsed by Anthropic or the official Claude Code team.

---

---

<h1 align="center">⚡ ClaudeTeleport</h1>
<p align="center">
  <b>一键跳转。精准窗口。从不落空。</b><br>
  <sub>再也不用盯着 Claude Code 等授权。</sub>
</p>

<p align="center">
  <a href="https://yanchengsi.gumroad.com/l/qzvzii"><img src="https://img.shields.io/badge/Gumroad%20购买-%244.99-FF90E8?style=flat-square&logo=gumroad&logoColor=white&labelColor=000000" alt="Gumroad 购买"></a>
  <a href="#"><img src="https://img.shields.io/badge/平台-Windows%2010%2F11-0078D6?style=flat-square&logo=windows" alt="平台"></a>
  <a href="#"><img src="https://img.shields.io/badge/版本-v1.1-44cc11?style=flat-square" alt="版本"></a>
</p>

---

## 这是什么？

你在专注编码。Claude Code 弹了个权限请求。终端窗口埋在 17 个窗口下面。你 5 分钟后才发现。

**ClaudeTeleport 解决的就是这个。** Claude 需要你批准的那一瞬间，Windows 原生通知弹出。点击它。你直接跳转到那个终端——同一个窗口，同一个会话，零延迟。

---

## 🚀 快速开始

```bash
# 1. 下载 ZIP（或 git clone）
# 2. 双击：

install.bat

# 3. 搞定。真的就这样。
```

**验证效果：** 对 Claude Code 说 *"创建一个叫 hello.txt 的文件，里面写上 test"*。权限弹窗那一刻，通知就会出现在屏幕右下角。

卸载：双击 `uninstall.bat`。

---

## 🧠 为什么这东西真的有用

大多数工具靠"猜"来找窗口。我们不猜。

| 方法 | 准确度 |
|------|--------|
| 进程树回溯（mintty → bash → claude） | ❌ MSYS2 下断裂 |
| "返回第一个 mintty" | ❌ 多窗口时选错 |
| 窗口标题启发式匹配 | ⚠️ 大约 80% 的准确率 |
| **GetForegroundWindow 在 Hook 触发瞬间 → 直接 HWND** | **✅ 100%** |

Claude Code 触发权限请求时，**你正在操作的那个窗口就是正确的终端**。我们在那一毫秒捕获 HWND 并嵌入通知按钮。不猜。不启发式。指针级别的精确。

---

## 💻 兼容性

| 终端 | 支持情况 |
|------|----------|
| Git Bash (mintty) | ✅ 主要目标 — HWND 级别精准 |
| Windows Terminal | ✅ 完全支持 |
| CMD / PowerShell | ✅ 完全支持 |
| VS Code / Cursor 内置终端 | ⚠️ 通过回退匹配可用 |

**运行要求：** Windows 10/11、.NET Framework 4.x（系统自带）、[Claude Code](https://docs.anthropic.com/en/docs/claude-code)。

---

## 🛒 获取

<p align="center">
  <a href="https://yanchengsi.gumroad.com/l/qzvzii">
    <img src="https://img.shields.io/badge/Gumroad%20购买-%244.99-FF90E8?style=for-the-badge&logo=gumroad&logoColor=white&labelColor=000000" alt="Gumroad 购买">
  </a>
  <br>
  <sub>标准版 $4.99 · 含完整源码 · 售出概不退款</sub>
</p>

---

## ⚖️ 法律声明

**退款政策：** 由于本产品为数字商品且包含完整源代码，所有销售均为最终交易，概不退款。购买前请确认兼容性列表。

**免责声明：** 本工具为独立的开源/源码可见工具。与 Anthropic 或 Claude Code 官方团队无任何关联、赞助或背书关系。
