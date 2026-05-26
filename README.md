<div align="center">
    <h1>AI-Skills</h1>
    <h3><em>Agent skills for Solana bot development</em></h3>
</div>

<p align="center">
    <strong>Community-ready skills for Codex, Claude Code, Cursor, and other coding agents when building bots with <a href="https://github.com/0xfnzero/sol-trade-sdk">sol-trade-sdk</a>, <a href="https://github.com/0xfnzero/solana-streamer">solana-streamer</a>, <a href="https://github.com/0xfnzero/sol-parser-sdk">sol-parser-sdk</a>, and <a href="https://github.com/0xfnzero/sol-safekey">sol-safekey</a>.</strong>
</p>

<p align="center">
    <a href="README.md">English</a> |
    <a href="README_CN.md">中文</a> |
    <a href="https://fnzero.dev/">Website</a> |
    <a href="https://t.me/fnzero_group">Telegram</a> |
    <a href="https://discord.gg/vuazbGkqQE">Discord</a>
</p>

---

## What This Repo Provides

This repo stores skills in the neutral top-level `skills/` directory. The skills are plain `SKILL.md` folders, so they can be installed into different agent tools instead of being tied to only Cursor.

The installer copies the same source skills to:

| Tool | Default install path |
|------|----------------------|
| Cursor | `~/.cursor/skills/` |
| Codex | `~/.codex/skills/` |
| Claude Code | `~/.claude/skills/` |

You can override these paths with `CURSOR_SKILLS_DIR`, `CODEX_SKILLS_DIR`, or `CLAUDE_SKILLS_DIR`.

## Skills

| Skill | Purpose |
|-------|---------|
| `solana-bot-sdk-orchestrator` | Chooses SDK boundaries and wires stream, strategy, execution, risk, and wallet layers for Solana bots. |
| `solana-streamer-bot` | Builds bot-facing event streams with `solana-streamer-sdk`: Yellowstone gRPC, ShredStream, callbacks, filters, account updates, and RPC replay. |
| `sol-parser-sdk-bot` | Uses `sol-parser-sdk` directly for parsing, event filters, gRPC subscriptions, account subscriptions, RPC parsing, ShredStream, and parser contribution work. |
| `sol-trade-sdk-bot` | Builds and sends DEX trades with `sol-trade-sdk`: buy/sell params, SWQoS/MEV, gas fee strategy, nonce, ALT, sniping, and copy trading execution. |
| `sol-safekey-bot` | Integrates encrypted wallet and key management with `sol-safekey`: keystores, unlock flow, stdin password handling, and secure bot startup. |

The SDK families include Rust plus multi-language variants where available:

- `sol-parser-sdk`: Rust, Node.js/TypeScript, Python, Go
- `sol-trade-sdk`: Rust, Node.js/TypeScript, Python, Go

Current package names and directly installable package versions:

| SDK | Rust | Node.js/TypeScript | Python | Go |
|-----|------|--------------------|--------|----|
| parser | `sol-parser-sdk@0.5.1` | `sol-parser-sdk-nodejs@0.4.4` on npm | `sol-parser-sdk-python==0.4.5` | `github.com/0xfnzero/sol-parser-sdk-golang@v0.4.5` |
| trade | `sol-trade-sdk@4.0.14` | `sol-trade-sdk@0.1.0` on npm | `sol-trade-sdk==0.1.1` | `github.com/0xfnzero/sol-trade-sdk-golang@v0.1.1` |

The Node.js SDK source repositories currently have newer tags/package metadata than npm (`sol-parser-sdk-nodejs` `v0.4.5`, `sol-trade-sdk-nodejs` `v0.1.1`). The skills call this out so agents do not generate npm install commands for unpublished versions.

For non-Rust code, the skills instruct agents to inspect the target language's README/examples before assuming API names.

## Install

Clone and install:

```bash
git clone https://github.com/0xfnzero/AI-Skills.git
cd AI-Skills
chmod +x scripts/install.sh
./scripts/install.sh
```

The script:

1. Copies all folders from `skills/` into Cursor, Codex, and Claude Code user-level skill directories.
2. Clones or updates the SDK source repos in this repo root:
   - `sol-parser-sdk`
   - `sol-trade-sdk`
   - `solana-streamer`
   - `sol-safekey`
   - multi-language parser/trade SDK repos for Node.js, Python, and Go

Install only the skills without cloning SDK source:

```bash
./scripts/install.sh --skills-only
```

## Usage

Ask your coding agent naturally:

- "Build a PumpFun sniper using solana-streamer and sol-trade-sdk."
- "Use sol-safekey so the bot never stores a plaintext private key."
- "Write a copy-trading bot that follows this wallet and simulates first."
- "Use sol-parser-sdk directly to parse a transaction by signature."
- "Port this Rust bot shape to TypeScript using the Node.js SDK variant."

When a task spans multiple SDKs, the orchestrator skill should trigger first, then hand off to the specialized SDK skill.

## Directory Layout

```text
AI-Skills/
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
├── sol-parser-sdk/      # cloned by install.sh unless --skills-only
├── sol-trade-sdk/       # cloned by install.sh unless --skills-only
├── solana-streamer/     # cloned by install.sh unless --skills-only
├── sol-safekey/         # cloned by install.sh unless --skills-only
└── sol-*-sdk-{nodejs,python,golang}/
```

## Notes

- `skills/` is the canonical source. Tool-specific directories are installation targets, not the repo's storage format.
- The skills are designed for bot development, not financial advice. Generated bots should default to simulation or tiny test amounts until reviewed.
- Do not commit private keys, keystores, API tokens, or `.env` files.
