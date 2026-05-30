# ClaudeTeleport — Post-Mortem & Lessons Learned

**Date shipped:** 2026-05-30  
**Total dev time:** ~1 day  
**Final artifact:** 15KB ZIP, one-click installer, open source, $4.99 on Gumroad  
**Repos:** `yanchengsi/cc-notificion` (private dev) → `yanchengsi/-claude-teleport` (public)  
**Commits:** 7 (dev) + 12 (marketing)

---

## 1. 独立开发者视角

### 1.1 技术决策日志

| # | 决策 | 结果 | 教训 |
|---|------|------|------|
| 1 | C# + PowerShell（非 Python/Electron/Node） | ✅ 编译产物 10KB，零运行时依赖 | 目标平台有原生能力时不引入外部依赖 |
| 2 | `winexe` 而非控制台程序 | ✅ 通知按钮点击不闪现黑窗 | 分发型工具的第一印象在毫秒级 |
| 3 | 惰性进程架构（非常驻） | ✅ 零内存占用，无限期运行不泄漏 | 不是所有工具都需要守护进程 |
| 4 | 提前编译 `WindowHelper.dll` | ✅ 通知延迟从 4s→1.5s | 安装时多编译一行的成本，远低于每次用户等待的累积成本 |
| 5 | `GetForegroundWindow` 而非进程树回溯 | ✅ 多窗口场景 100% 准确 | MSYS2 进程树对 Windows WMI 不可见——这个坑在任何文档里都没有 |

### 1.2 Bug 清单

| Bug | 症状 | 根因 | 严重度 |
|-----|------|------|--------|
| AppUserModelID 缺失 | Toast API 返回成功但通知不显示 | Windows 10/11 要求非 Explorer 进程声明 AppID | 🔴 致命 |
| Hook 安装不稳定 | 卸载重装后 hook 消失 | 检测逻辑用脆弱的存在性检查，卸载后 JSON 残留空对象导致误判 | 🔴 致命 |
| `$pid` 变量冲突 | 子进程搜索报错 | PowerShell `$PID` 是只读系统变量 | 🟡 静默失败 |
| UTF-8 BOM 缺失 | 中文/emoji 乱码 | PowerShell 5.1 默认读取 ANSI 编码 | 🟡 显示异常 |
| `<` 比较运算符 | 脚本报错不执行 | PowerShell 5.1 不支持 `<`，只能用 `-lt` | 🟡 版本兼容 |

**最关键的教训：** "Toast sent" 在日志里不代表通知真的弹出来了。AppUserModelID 这个问题如果不在真机上肉眼验证，永远发现不了。

### 1.3 独立开发者 Checklist

**写软件之前：**
- 搞清楚目标平台的隐性约束（Windows Toast API 的 AppUserModelID 要求）
- 搞清楚进程模型的极限（MSYS2 进程树不可见）

**写软件之后，发布之前：**
- [] 真实环境肉眼验证（不是看日志，是看屏幕）
- [] 卸载→重装→卸载→重装 至少 3 轮
- [] 测试 fallback 路径（DLL 不存在时、权限文件缺失时、hook 为空时）
- [] PowerShell 5.1 兼容性（不是 7.x，不是 pwsh）
- [] UTF-8 BOM 编码（中文/emoji 不乱码）

---

## 2. 产品经理视角

### 2.1 产品决策日志

| # | 决策 | 结果 | 教训 |
|---|------|------|------|
| 1 | **弃用免费模式，直接定价 $4.99** | 还未验证市场，但定价锚定了"值这个钱"的心态 | 低价不是劣势——对于工具类产品，$4.99 是冲动消费区间 |
| 2 | **开源而非闭源** | 代码公开消除了安全疑虑，README 里写了"You can build it yourself"反而增加了信任 | 对于 14KB 的脚本工具，源代码保密毫无意义。护城河在"省时间"不在"代码秘密" |
| 3 | **双重仓库策略**（代码仓 vs 文档仓） | `cc-notificion` 放代码，`-claude-teleport` 放 Landing Page | 买前看文档仓，买后看代码仓——信息架构清晰 |
| 4 | **英文单语言** | 删掉中文版 | 付费客户是海外开发者，中文会增加认知负担 |
| 5 | **Landing Page 用纯 HTML 暗色主题** | 比 GitHub README 正式，比框架轻 | 目标用户是开发者，他们喜欢暗色终端风格 |

### 2.2 文案迭代历程

| 版本 | 问题 | 修改 |
|------|------|------|
| v1 | "But if your time is worth more than $4.99" | ✅ 傲慢激将 → 尊重式 "What the $4.99 is really for" |
| v2 | "buying a copy" 与开源矛盾 | ✅ → "becoming a customer" |
| v3 | "install.bat takes five seconds" 触发安全焦虑 | ✅ 删掉速度描述，改强调代码透明性 |
| v4 | "Zero runtime dependencies" 但下一句就写 BurntToast 自动装 | ✅ 删掉歧义句 |
| v5 | 缺少 "Why Pay for Open Source?" | ✅ Landing page 新增专属 section |

**最关键的教训：** 独立开发者的"真实"和"卖惨"在情绪上是满分的，但在 PR 技巧上缺圆滑。同一句话，用"你不想付钱，fork + star 也帮我"比用"你不付钱就是觉得时间不值钱"效果好 100 倍。

### 2.3 营销决策

| 决策 | 理由 |
|------|------|
| **X/Twitter 引流，不发外链垃圾** | 目标用户聚集在 Claude Code 社区和开发者 Twitter |
| **GitHub Stars 作为 social proof** | 开源工具的可信度指标 |
| **Gumroad 而非自建支付** | Paddle 需要公司注册，Gumroad 不需要；Gumroad 处理 VAT/GST 税务 |
| **截图是第一优先级** | 开发者买工具看图决定，没有截图的 landing page 等于没有 landing page |
| **"Buy on Gumroad" 按钮贯穿全文** | 每滚动一屏都有一个 CTA |

### 2.4 产品 Roadmap（按优先级）

| 优先级 | 功能 | 触发条件 |
|--------|------|----------|
| P2 | Support $14.99 Supporter Tier | 有 5+ 付费用户后再上线 |
| P2 | Mac/Linux 移植 | 有用户明确需求 + Windows 版收入稳定后 |
| P3 | 通知按钮 Approve/Reject | 等 Claude Code 提供 IPC 接口 |
| P3 | 系统托盘 + 历史日志 | 用户基数够大后 |

---

## 3. Pivot 记录

| 时间点 | 从 | 到 | 原因 |
|--------|-----|-----|------|
| v4→v5 | 进程树回溯 + 启发式匹配 | `GetForegroundWindow` + 直接 HWND | MSYS2 进程树不可见 |
| v6 | 手工配置 4 个地方 | `install.bat` 一键安装 | 可分发性要求 |
| 命名 | `Claude Code Notification` | `ClaudeTeleport` | 品牌化、差异化、简短 |
| 定价 | 免费 | $4.99 | 你的时间值钱，代码开源，不用保密 |

---

*Written 2026-05-30 by the developer of ClaudeTeleport.*
