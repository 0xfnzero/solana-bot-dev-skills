<div align="center">
    <h1>solana-bot-dev-skills</h1>
    <h3><em>面向 Solana Bot 开发的 Agent Skills</em></h3>
</div>

<p align="center">
    <strong>给 Codex、Claude Code、Cursor 等开发工具使用的社区技能，帮助用户用 <a href="https://github.com/0xfnzero/sol-trade-sdk">sol-trade-sdk</a>、<a href="https://github.com/0xfnzero/solana-streamer">solana-streamer</a>、<a href="https://github.com/0xfnzero/sol-parser-sdk">sol-parser-sdk</a>、<a href="https://github.com/0xfnzero/sol-safekey">sol-safekey</a> 更方便地开发 Solana Bot。</strong>
</p>

<p align="center">
    <a href="README.md">English</a> |
    <a href="README_CN.md">中文</a> |
    <a href="https://fnzero.dev/">Website</a> |
    <a href="https://t.me/fnzero_group">Telegram</a> |
    <a href="https://discord.gg/vuazbGkqQE">Discord</a>
</p>

---

## 这个仓库提供什么

本仓库把技能统一存放在顶层 `skills/` 目录。每个技能都是标准的 `SKILL.md` 文件夹，因此不会绑定到某一个开发工具，例如只放在 `.cursor/skills/`。

## 为什么使用这些 Skills

这些 skills 会给开发工具提供基于 FNZero Solana Bot SDK 栈的上下文，而不是只依赖模型的通用记忆。它们可以帮助 agent：

- 正确选择 streaming、parsing、trading、wallet security 的 SDK 边界；
- 在写 Node.js/TypeScript、Python、Go 代码时避免过期 API、未发布包版本和 Rust-only 的错误假设；
- 更稳妥地组织狙击、跟单、账户监听、simulation、安全钱包解锁等常见 Bot 流程；
- 用同一份技能源同时支持 Codex、Claude Code、Cursor 等开发工具。

安装脚本会把同一份源技能分发到：

| 工具 | 默认安装目录 |
|------|--------------|
| Cursor | `~/.cursor/skills/` |
| Codex | `~/.codex/skills/` |
| Claude Code | `~/.claude/skills/` |

也可以用 `CURSOR_SKILLS_DIR`、`CODEX_SKILLS_DIR`、`CLAUDE_SKILLS_DIR` 覆盖安装路径。

## 技能列表

| Skill | 用途 |
|-------|------|
| `solana-bot-sdk-orchestrator` | 为 Solana Bot 选择 SDK 边界，并组织 stream、strategy、execution、risk、wallet 等层。 |
| `solana-streamer-bot` | 使用 `solana-streamer-sdk` 构建 Bot 事件流：Yellowstone gRPC、ShredStream、回调、过滤器、账户更新、RPC 回放。 |
| `sol-parser-sdk-bot` | 直接使用 `sol-parser-sdk`：解析、事件过滤、gRPC 订阅、账户订阅、RPC 解析、ShredStream、parser 贡献开发。 |
| `sol-trade-sdk-bot` | 使用 `sol-trade-sdk` 构建和发送 DEX 交易：买卖参数、SWQoS/MEV、gas 策略、nonce、ALT、狙击和跟单执行。 |
| `sol-safekey-bot` | 集成 `sol-safekey`：加密 keystore、钱包解锁、stdin 密码、Bot 安全启动和密钥管理。 |

SDK 家族包含 Rust 版本，以及可用的多语言版本：

- `sol-parser-sdk`：Rust、Node.js/TypeScript、Python、Go
- `sol-trade-sdk`：Rust、Node.js/TypeScript、Python、Go

当前包名和可直接安装的包版本：

| SDK | Rust | Node.js/TypeScript | Python | Go |
|-----|------|--------------------|--------|----|
| parser | `sol-parser-sdk@0.5.1` | `sol-parser-sdk-nodejs@0.4.4` on npm | `sol-parser-sdk-python==0.4.5` | `github.com/0xfnzero/sol-parser-sdk-golang@v0.4.5` |
| trade | `sol-trade-sdk@4.0.14` | `sol-trade-sdk@0.1.0` on npm | `sol-trade-sdk==0.1.1` | `github.com/0xfnzero/sol-trade-sdk-golang@v0.1.1` |

Node.js SDK 源码仓库当前有比 npm 更新的 tag/package metadata（`sol-parser-sdk-nodejs` `v0.4.5`、`sol-trade-sdk-nodejs` `v0.1.1`）。技能里会明确这一点，避免开发工具生成尚未发布到 npm 的安装命令。

对于非 Rust 代码，技能会要求开发工具先查看目标语言仓库的 README/examples，再生成 API 调用，避免直接套用 Rust API 名称。

## 安装

克隆并安装：

```bash
git clone https://github.com/0xfnzero/solana-bot-dev-skills.git
cd solana-bot-dev-skills
chmod +x scripts/install.sh
./scripts/install.sh
```

脚本会：

1. 把 `skills/` 下所有技能复制到 Cursor、Codex、Claude Code 的用户级技能目录。
2. 在本仓库根目录克隆或更新 SDK 源码：
   - `sol-parser-sdk`
   - `sol-trade-sdk`
   - `solana-streamer`
   - `sol-safekey`
   - parser/trade SDK 的 Node.js、Python、Go 多语言仓库

如果只安装技能、不克隆 SDK 源码：

```bash
./scripts/install.sh --skills-only
```

## 使用方式

在开发工具里用中文或英文正常提问即可。Skills 的触发描述已经包含中文关键词，例如狙击、跟单、监听、解析、发单、钱包、私钥、keystore、多语言 SDK 等，因此中文提问也可以触发对应技能。

- “用 solana-streamer 和 sol-trade-sdk 做一个 PumpFun 狙击 Bot。”
- “用 sol-safekey 管理钱包，Bot 不要保存明文私钥。”
- “写一个跟单 Bot，跟随这个钱包，但先只做 simulation。”
- “用 sol-parser-sdk 按交易签名解析一笔交易。”
- “把这个 Rust Bot 的结构迁移成 TypeScript，使用 Node.js 版本 SDK。”

英文提问也可以，例如：`Build a PumpFun sniper using solana-streamer and sol-trade-sdk.`

当任务跨多个 SDK 时，`solana-bot-sdk-orchestrator` 会先负责整体方案，再交给具体 SDK 技能。

## 目录结构

```text
solana-bot-dev-skills/
├── README.md
├── README_CN.md
├── SKILLS_EXTENSION.md
├── scripts/
│   └── install.sh
├── skills/
│   ├── solana-bot-sdk-orchestrator/
│   │   └── SKILL.md
│   ├── solana-streamer-bot/
│   │   └── SKILL.md
│   ├── sol-parser-sdk-bot/
│   │   └── SKILL.md
│   ├── sol-trade-sdk-bot/
│   │   └── SKILL.md
│   └── sol-safekey-bot/
│       └── SKILL.md
├── sol-parser-sdk/      # install.sh 默认克隆，--skills-only 时跳过
├── sol-trade-sdk/       # install.sh 默认克隆，--skills-only 时跳过
├── solana-streamer/     # install.sh 默认克隆，--skills-only 时跳过
├── sol-safekey/         # install.sh 默认克隆，--skills-only 时跳过
└── sol-*-sdk-{nodejs,python,golang}/
```

## 注意

- `skills/` 是唯一源目录。各工具自己的目录只是安装目标，不是本仓库的存放格式。
- 这些技能服务于 Bot 开发，不构成金融建议。生成的交易 Bot 应默认使用 simulation 或极小测试金额，经过审查后再实盘。
- 不要提交私钥、keystore、API token 或 `.env` 文件。
