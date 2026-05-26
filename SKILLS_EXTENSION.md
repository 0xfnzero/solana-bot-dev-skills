# 技能拓展建议 / Skills extension ideas

本仓库的技能统一存放在顶层 `skills/` 目录，再由 `scripts/install.sh` 分发到 Cursor、Codex、Claude Code 等工具的用户级目录。
Skills are stored in the top-level `skills/` directory and installed into tool-specific user directories by `scripts/install.sh`.

---

## 已实现 / Implemented

| 技能 | 说明 |
|------|------|
| `solana-bot-sdk-orchestrator` | 跨 SDK 的 Solana Bot 架构编排：stream、strategy、execution、risk、wallet |
| `solana-streamer-bot` | 使用 solana-streamer-sdk 构建 gRPC/ShredStream/account/RPC replay 事件流 |
| `sol-parser-sdk-bot` | 直接使用 sol-parser-sdk：解析、过滤、RPC 解析、账户订阅、parser 开发 |
| `sol-trade-sdk-bot` | 使用 sol-trade-sdk 构建/发送交易、SWQoS/MEV、gas、nonce、狙击/跟单执行 |
| `sol-safekey-bot` | 使用 sol-safekey 做加密 keystore、钱包解锁、stdin 密码和安全启动 |

---

## 可选拓展 / Optional extensions

1. **多语言 SDK 深化 / Multi-language SDK details**
   - 为 Node.js/TypeScript、Python、Go 分别补充更具体的安装、类型、异步和错误处理约定。
   - 可作为现有 `sol-parser-sdk-bot`、`sol-trade-sdk-bot` 的 reference 文件，也可拆分成独立技能。

2. **测试与调试 / Testing and debugging**
   - 用 RPC 按签名解析单笔交易做回归；为新事件写单元测试；维护真实签名样例。
   - 技能名建议：`solana-bot-testing-debug`。

3. **交易安全与风控 / Trading safety and risk**
   - 仿真、滑点、限频、仓位上限、重复交易防护、quote mint allowlist、日志脱敏。
   - 技能名建议：`solana-trading-risk-controls`。

4. **SWQoS / MEV 专项 / SWQoS and MEV sending**
   - Jito、Nextblock、ZeroSlot、Temporal、Bloxroute、FlashBlock、BlockRazor、Node1、Astralane 等配置和权衡。
   - 可并入 `sol-trade-sdk-bot` 或单独 `sol-trade-sdk-swqos-mev`。

5. **多协议聚合 / Multi-DEX aggregation**
   - PumpFun、PumpSwap、Bonk/Raydium Launchpad、Raydium、Meteora、Orca 的事件归一化、去重和策略接口。
   - 技能名建议：`solana-multi-dex-bot`。

6. **SDK 贡献开发 / SDK contribution**
   - sol-trade-sdk 或 solana-streamer 的项目结构、添加协议、参数扩展、性能测试和发布前检查。
   - 技能名建议：`sol-trade-sdk-dev`、`solana-streamer-dev`。

7. **代币元数据 / Token metadata**  
   - 从 mint 获取 name、symbol、decimals、Metaplex metadata，用于展示、筛选和风控。
   - 技能名建议：`solana-token-metadata`。

---

## 新增方式 / How to add a skill

- 在 `skills/<skill-name>/SKILL.md` 新增技能。
- 在 `README.md` 和 `README_CN.md` 的技能表中登记。
- 不要把源技能只放到 `.cursor/skills/`、`.codex/skills/` 或 `.claude/skills/`；这些是安装目标。
- `scripts/install.sh` 会复制 `skills/` 下所有包含 `SKILL.md` 的目录，通常无需修改脚本。
