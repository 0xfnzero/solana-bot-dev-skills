---
name: sol-trade-sdk-bot
description: Use this skill when building or modifying Solana trading code with sol-trade-sdk, including Rust and multi-language variants, DEX buy/sell params, PumpFun/PumpSwap/Bonk/Raydium/Meteora trading, SWQoS/MEV services, gas fee strategy, durable nonce, address lookup tables, middleware, sniping, and copy trading execution.
---

# Sol Trade SDK Bot

Use this skill for transaction construction and sending with `sol-trade-sdk`.

## What The SDK Provides

- Unified buy/sell interface for PumpFun, PumpSwap/Pump AMM, Bonk/Raydium Launchpad, Raydium CPMM, Raydium AMM V4, and Meteora DAMM v2.
- SWQoS/MEV sender integrations including Jito, Nextblock, ZeroSlot, Temporal, Bloxroute, FlashBlock, BlockRazor, Node1, Astralane, SpeedLanding, and default RPC.
- Shared infrastructure for multi-wallet bots.
- Gas fee strategy, durable nonce, address lookup table, middleware, and token account helpers.

## Dependency

```toml
sol-trade-sdk = "4.0.14"
```

Multi-language package names and directly installable package versions:

| Language | Package/module | Version | Install |
|----------|----------------|---------|---------|
| Rust | `sol-trade-sdk` | `4.0.14` | `cargo add sol-trade-sdk@4.0.14` |
| Node.js/TypeScript | `sol-trade-sdk` | `0.1.0` on npm | `npm install sol-trade-sdk@0.1.0` |
| Python | `sol-trade-sdk` | `0.1.1` | `pip install sol-trade-sdk==0.1.1` |
| Go | `github.com/0xfnzero/sol-trade-sdk-golang` | `v0.1.1` | `go get github.com/0xfnzero/sol-trade-sdk-golang@v0.1.1` |

The Node.js repository has a `v0.1.1` tag/package.json, but npm `latest` is `0.1.0` as of the source review. Do not generate `npm install sol-trade-sdk@0.1.1` unless that package version is published or the user is installing from GitHub/tag source.

Language-specific entry points:

- Node.js/TypeScript: `import { TradingClient, TradeConfigBuilder, createTradeConfig, DexType, TradeTokenType, SwqosType, SwqosRegion, GasFeeStrategy, PumpFunParams } from "sol-trade-sdk";`. Current examples create clients with `new TradingClient(payer, config)`.
- Python: `from sol_trade_sdk import TradingClient, TradeConfig, TradeConfigBuilder, DexType, TradeTokenType, SwqosConfig, SwqosType, SwqosRegion, PumpFunParams`. Current examples create clients with `TradingClient(payer, config)`.
- Go: import root package as `soltradesdk "github.com/0xfnzero/sol-trade-sdk-golang/pkg"` and create clients with `soltradesdk.NewTradingClient(ctx, payer, config)`. Current examples often wrap this with `examples/internal/exampleutil.NewClient(ctx)` for setup. Lower-level factory clients use `trading.NewTradingClient(factory)`.

Use the target language examples instead of Rust field names when generating code. The Rust SDK has the richest low-level param surface; Node/Python/Go expose equivalent concepts with language-native constructors and modules.

Source-verified API map:

| Concept | Rust | Node.js/TypeScript | Python | Go |
|---------|------|--------------------|--------|----|
| Client | `SolanaTrade::new` / `TradingClient` | `new TradingClient(payer, config)` | `TradingClient(payer, config)` | `soltradesdk.NewTradingClient(ctx, payer, config)`; examples may wrap with `exampleutil.NewClient(ctx)` |
| Config | `TradeConfig::builder(...)` | `TradeConfigBuilder` or `createTradeConfig` / example `tradeConfig(...)` | `TradeConfig.builder(...)` / example `trade_config(...)` | `soltradesdk.NewTradeConfigBuilder(rpcURL)` / example `exampleutil.TradeConfig()` |
| SWQoS | `SwqosConfig::*` enum variants | `SwqosConfig` object with `type`, `region`, `apiKey` | `SwqosConfig(type=SwqosType.DEFAULT, region=..., api_key=...)` | `soltradesdk.SwqosConfig{Type: ..., Region: ...}` |
| Buy/sell params | `TradeBuyParams` / `TradeSellParams` snake_case fields | `TradeBuyParams` / `TradeSellParams` camelCase fields | `TradeBuyParams` / `TradeSellParams` dataclasses snake_case fields | `soltradesdk.TradeBuyParams` / `TradeSellParams` Go fields |
| PumpFun params | `PumpFunParams::from_dev_trade` | `PumpFunParams.fromTrade` / `fromMintByRpc`; check source before assuming `fromDevTrade` | `PumpFunParams.from_trade`, `from_parser_trade_event`, `from_mint_by_rpc`; check source before assuming Rust parity | check `pkg/params` and examples; do not assume Rust method names |

Common imports:

```rust
use std::sync::Arc;
use sol_trade_sdk::{
    common::{GasFeeStrategy, TradeConfig},
    swqos::{SwqosConfig, SwqosRegion},
    trading::{core::params::DexParamEnum, factory::DexType},
    SolanaTrade, TradeBuyParams, TradeSellParams, TradeTokenType,
};
use solana_commitment_config::CommitmentConfig;
use solana_sdk::signature::Keypair;
```

## Client Setup

```rust
let payer = Arc::new(keypair);
let rpc_url = std::env::var("RPC_URL")?;
let swqos = vec![SwqosConfig::Default(rpc_url.clone())];
let config = TradeConfig::builder(rpc_url, swqos, CommitmentConfig::processed())
    .log_enabled(true)
    .mev_protection(false)
    .build();
let client = SolanaTrade::new(payer, config).await;
```

For multiple wallets, create shared infrastructure once and build clients from it instead of creating RPC/SWQoS clients repeatedly.

## Trade Param Rules

`TradeBuyParams` and `TradeSellParams` require:

- `dex_type`: protocol enum such as `DexType::PumpFun` or `DexType::PumpSwap`.
- `input_token_type` or `output_token_type`: usually `SOL`, `WSOL`, or token type supported by the SDK.
- `mint`: token mint.
- `input_token_amount`: smallest-unit amount.
- `slippage_basis_points`: `Some(100)` means 1%.
- `recent_blockhash`: fetch close to send time.
- `extension_params`: protocol-specific `DexParamEnum` built from parser event data, pool lookup, or RPC.
- ATA flags: create/close token accounts according to the route.
- `simulate`: set true while wiring new bots.
- `durable_nonce`: required for some multi-sender or nonce workflows.
- `gas_fee_strategy`: explicit strategy object, even if defaults are used.

## From Stream Event To Trade

For sniper or copy-trading flows:

1. Match a typed event from `solana-streamer` or `sol-parser-sdk`.
2. Verify every field required by the protocol-specific params is present.
3. Build `DexParamEnum::<Protocol>(...)`.
4. Fetch a recent blockhash late.
5. Execute `client.buy(params).await?` or `client.sell(params).await?`.

For PumpFun first creator buys, prefer `PumpFunParams::from_dev_trade` or the current equivalent because it derives bonding-curve state from creator-trade event data. Include cashback/mayhem/quote-mint fields when the current SDK requires them.

Current Rust `PumpFunParams::from_dev_trade` signature:

```rust
PumpFunParams::from_dev_trade(
    e.mint,
    e.token_amount,
    max_quote_cost,
    e.creator,
    e.bonding_curve,
    e.associated_bonding_curve,
    e.creator_vault,
    None, // close_token_account_when_sell
    e.fee_recipient,
    e.token_program,
    e.is_cashback_coin,
    Some(e.mayhem_mode),
)
```

For PumpFun V2/USDC-paired coins, use `from_dev_trade_with_quote_mint(..., e.quote_mint)` when the event exposes the quote mint. For sell params from parsed trade data, use `PumpFunParams::from_trade` with bonding curve, associated bonding curve, mint, quote mint, creator, creator vault, reserves, fee recipient, token program, cashback, and mayhem fields from the event.

Required `TradeBuyParams` fields in v4.0.14 include `wait_tx_confirmed`, `create_input_token_ata`, `close_input_token_ata`, `create_mint_ata`, `durable_nonce`, `fixed_output_token_amount`, `gas_fee_strategy`, `simulate`, `use_exact_sol_amount`, and `grpc_recv_us`; do not use older field names such as `wait_transaction_confirmed`.

## Gas And Sender Strategy

Use `GasFeeStrategy::new()` and set explicit fee/tip policy for bots:

```rust
let gas_fee_strategy = GasFeeStrategy::new();
gas_fee_strategy.set_global_fee_strategy(150000, 150000, 500000, 500000, 0.001, 0.001);
```

Guidance:

- Use default RPC while developing.
- Add SWQoS providers only after the basic path works.
- When sending through multiple services concurrently, check durable nonce requirements in the SDK docs/examples.
- Keep min-tip checks and MEV protection explicit in config so production behavior is visible.

## Safety Defaults

- Keep real-money execution behind config.
- Start with `simulate: true` or tiny amounts.
- Enforce max spend, max slippage, allowed protocols, and allowed quote mints.
- Deduplicate buy attempts by mint or signature.
- Log signature, slot, mint, amount, slippage, recent blockhash age, sender provider, and error.
- Do not load private keys directly from literals; use `sol-safekey` or the repo's secure key loader.

## Multi-Language Guidance

The SDK family has Rust plus Node.js, Python, and Go repos. For non-Rust:

- Inspect target-language examples before writing API calls.
- Preserve the same boundaries: client config, sender/SWQoS config, gas strategy, protocol params, buy/sell call, simulate flag.
- Use async/await in Node.js and Python where exposed.
- Use `context.Context` and goroutines carefully in Go send loops.
- If a language binding lacks a helper present in Rust, either call the documented lower-level builder or add a small adapter with tests.
- Do not copy Rust struct field names into TypeScript or Go; TypeScript uses camelCase (`dexType`, `waitTxConfirmed`, `useExactSolAmount`), Rust/Python use snake_case, and Go uses exported PascalCase fields.
- Example paths:
  - Node.js: `examples/trading_client.ts`, `examples/pumpfun_sniper_trading.ts`, `examples/pumpfun_copy_trading.ts`, `examples/pumpswap_trading.ts`.
  - Python: `examples/trading_client.py`, `examples/pumpfun_sniper_trading.py`, `examples/pumpfun_copy_trading.py`, `examples/pumpswap_trading.py`.
  - Go: `examples/trading_client/main.go`, `examples/pumpfun_sniper_trading/main.go`, `examples/pumpfun_copy_trading/main.go`, `examples/pumpswap_trading/main.go`.

## Validation

- Run formatter and type checks.
- For Rust examples, run `cargo check` and targeted example builds.
- For new trade paths, add a dry-run/simulation path and a unit test around param construction if possible.
- Never require mainnet credentials to pass normal tests.
