---
name: solana-bot-sdk-orchestrator
description: Use this skill when building Solana trading bots or automation that combines solana-streamer, sol-parser-sdk, sol-trade-sdk, and sol-safekey, including multi-language SDK variants for Rust, Node.js/TypeScript, Python, and Go. It helps agents choose the right SDK boundary, wire event streams into trades, handle wallet security, and produce runnable bot code for Codex, Claude Code, Cursor, or similar coding agents.
---

# Solana Bot SDK Orchestrator

Use this as the first skill when a user asks for a Solana bot, sniper, copy trader, monitor, wallet automation, multi-DEX stream, or SDK integration involving more than one FNZero SDK.

## SDK Roles

- `solana-streamer`: preferred bot-facing event stream facade. Use it for gRPC, ShredStream, dynamic subscriptions, event callbacks, account monitoring, and RPC transaction replay when the user is building an app rather than modifying parser internals.
- `sol-parser-sdk`: parser core. Use it directly when the user needs the lowest-level parser API, parse hot path control, specific `EventTypeFilter` behavior, or SDK contribution work.
- `sol-trade-sdk`: transaction builder and sender. Use it for DEX buys/sells, SWQoS/MEV routing, durable nonce, gas fee strategy, address lookup tables, middleware, and shared trading infrastructure.
- `sol-safekey`: wallet and key management. Use it for encrypted keystores, bot wallet unlock, interactive wallet setup, SOL/SPL/WSOL operations, and avoiding plaintext private keys.

## Language Selection

Prefer the user's repo language. If unclear:

- Rust: best for lowest latency and full SDK feature surface.
- Node.js/TypeScript: best for web dashboards, operational tooling, and JS bot stacks.
- Python: best for research workflows, scripting, and async monitoring.
- Go: best for simple concurrent services.

Known multi-language SDK families:

- `sol-parser-sdk`: Rust crate `sol-parser-sdk`; Node package `sol-parser-sdk-nodejs`; Python package `sol-parser-sdk-python`; Go module `github.com/0xfnzero/sol-parser-sdk-golang`.
- `sol-trade-sdk`: Rust crate `sol-trade-sdk`; Node/Python package `sol-trade-sdk`; Go module `github.com/0xfnzero/sol-trade-sdk-golang`.

When generating non-Rust code, inspect installed package docs or examples in the target repo before inventing API names. If docs are unavailable, state the assumption and keep wrappers thin around the documented concepts: protocols, event filters, trade params, sender config, and secure key loading.

## Bot Architecture

For production-style bots, separate these components:

- `config`: RPC URL, gRPC endpoint, auth token, protocol list, slippage, trade sizes, SWQoS providers, wallet path.
- `wallet`: load or unlock encrypted key material through `sol-safekey`; do not hard-code base58 private keys.
- `stream`: subscribe with `solana-streamer` or `sol-parser-sdk`; filter early by protocol/account/event type.
- `strategy`: pure decision logic that receives typed events and returns `Buy`, `Sell`, `Ignore`, or `RiskReject`.
- `executor`: maps decisions to `sol-trade-sdk` params, reuses latest blockhash/nonce, applies slippage and gas strategy, sends or simulates.
- `risk`: position limits, duplicate suppression by signature/mint, max spend, max concurrent trades, allowed quote mints, balance checks.
- `observability`: structured logs with signature, slot, event type, mint, latency, send result, and error cause.

## Common Flows

### Sniper / New Token First Buy

1. Stream PumpFun events with an include-only filter for create and buy events.
2. Detect first creator buy using `is_created_buy` on buy events when available.
3. Build trade params from parser event data; for PumpFun creator buys prefer SDK helpers such as `PumpFunParams::from_dev_trade` or the current language equivalent.
4. Use a duplicate guard keyed by mint or bonding curve.
5. Start with `simulate: true` or a tiny amount, then require explicit user intent before mainnet real spending.

### Copy Trading

1. Use transaction filters with `account_include` or `account_required` for the leader wallet and DEX programs.
2. Match typed buy/sell events and normalize amount, mint, quote mint, protocol, and signature.
3. Apply sizing policy: fixed amount, percentage of leader size, or capped amount.
4. Send with `sol-trade-sdk`; avoid copying unknown instructions blindly.
5. Record copied signatures to avoid duplicate execution.

### Multi-DEX Monitor

1. Choose protocols: PumpFun, PumpSwap, Bonk/Raydium Launchpad, Raydium CPMM/CLMM/AMM V4, Meteora DAMM/DLMM/Pools, Orca Whirlpool.
2. Use event filters for only the event families needed by the strategy.
3. Normalize events into an app-level enum or struct so strategy code is not protocol-specific everywhere.
4. Keep protocol-specific params near the trade construction boundary.

## Safety Defaults

- Never store wallet passwords in environment variables. Prefer stdin, interactive unlock, OS secret manager, or encrypted keystore unlock flow.
- Never commit private keys, keystores, auth tokens, API keys, or `.env` files.
- For examples, use placeholders and make real-money execution opt-in.
- Use `simulate: true` when wiring a new trade path.
- Use allowlists for protocols, quote mints, and wallet addresses.
- If the user asks for "fastest", explain the tradeoff: `Unordered` has lower latency; `MicroBatch` gives near-low-latency ordering; full ordering costs more latency.

## Agent Workflow

1. Inspect the target repo first: language, package manager, current dependencies, and existing bot structure.
2. Pick the smallest SDK set. Stream-only monitors do not need `sol-trade-sdk`; trade-only scripts do not need a stream SDK.
3. Add dependencies using the repo's existing style.
4. Prefer examples from the SDK repos over hand-written API guesses.
5. Implement one vertical path first: config -> wallet -> stream or trade -> logs.
6. Add a dry-run/simulate mode unless the user explicitly has one.
7. Run formatting and the narrowest useful tests or type checks.

## Skill Handoff

After choosing the SDKs, also use the matching specialized skill:

- Event parsing or direct parser APIs: `sol-parser-sdk-bot`
- Streaming facade, gRPC/ShredStream/account/RPC replay: `solana-streamer-bot`
- Buy/sell/SWQoS/trade params: `sol-trade-sdk-bot`
- Wallet encryption/unlock/key handling: `sol-safekey-bot`
