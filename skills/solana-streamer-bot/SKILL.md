---
name: solana-streamer-bot
description: Use this skill when building bot-facing event streams with solana-streamer or solana-streamer-sdk, including Yellowstone gRPC, ShredStream, dynamic subscriptions, DexEvent callbacks, account filters, RPC transaction replay, and migration from older trait-based streamer APIs.
---

# Solana Streamer Bot

Use `solana-streamer-sdk` for application-level bots that need stable event streams backed by `sol-parser-sdk`.

## When To Prefer Streamer

Prefer `solana-streamer-sdk` when the user needs:

- A bot-facing `DexEvent` stream across multiple DEX protocols.
- Callback-style subscription APIs.
- gRPC plus ShredStream behind a simpler facade.
- RPC transaction replay converted to streamer events.
- Dynamic subscription management.
- Account and transaction filtering in one subscription.

Use `sol-parser-sdk` directly for parser internals, maximal low-level control, or contribution work.

## Dependency

```toml
solana-streamer-sdk = "1.5.1"
```

For zero-copy parser backend:

```toml
solana-streamer-sdk = { version = "1.5.1", default-features = false, features = ["sdk-parse-zero-copy"] }
```

## Current Event Model

Current v1 APIs use concrete enum events:

- Event type: `DexEvent`
- Callback signature: `Fn(DexEvent)`
- Event matching: standard Rust `match`
- Metadata: `event.metadata().event_type`, `.signature`, `.slot`, `.protocol`

When migrating old code, replace `Box<dyn UnifiedEvent>` and `match_event!` with `DexEvent` enum matching.

## gRPC Subscription Pattern

```rust
use solana_streamer_sdk::streaming::{
    event_parser::{
        common::{filter::EventTypeFilter, EventType},
        DexEvent, Protocol,
    },
    grpc::ClientConfig,
    yellowstone_grpc::{AccountFilter, TransactionFilter},
    YellowstoneGrpc,
};

let mut config = ClientConfig::default();
config.enable_metrics = false;

let grpc = YellowstoneGrpc::new_with_config(endpoint, token, config)?;

let protocols = vec![Protocol::PumpFun, Protocol::PumpSwap];
let tx_filter = TransactionFilter {
    account_include: vec![/* program ids or wallets */],
    account_exclude: vec![],
    account_required: vec![],
};
let account_filter = AccountFilter {
    account: vec![],
    owner: vec![/* program ids */],
    filters: vec![],
};
let event_filter = Some(EventTypeFilter::include_only(vec![
    EventType::PumpFunBuy,
    EventType::PumpFunSell,
]));

grpc.subscribe_events_immediate(
    protocols,
    None,
    vec![tx_filter],
    vec![account_filter],
    event_filter,
    None,
    |event: DexEvent| {
        match event {
            DexEvent::PumpFunTradeEvent(e) => {
                // strategy logic
            }
            _ => {}
        }
    },
).await?;
```

Check the installed SDK examples for exact variant names in the current version before editing a repo.

## Filters

- Transaction filters select transactions by account include/exclude/required.
- Account filters select account updates by exact account, owner, and memcmp-like filters.
- Event filters should be as narrow as possible for bots.
- Streamer supports include and exclude semantics; exclude-only filters may still keep broad upstream subscriptions open and drop locally when needed.

## RPC Replay

Use streamer RPC helpers when debugging or creating tests:

- `fetch_rpc_transaction_as_streamer_events`
- `fetch_rpc_transaction_as_streamer_events_async`
- `parse_encoded_rpc_transaction_as_streamer_events`

Use these to reproduce a live event without running a stream.

## ShredStream

ShredStream is useful for latency-sensitive bots, but it has limitations:

- ALT-loaded accounts may be best-effort.
- CPI/inner-only details may be unavailable.
- Trade execution must verify every required field before constructing `sol-trade-sdk` params.

For a bot that trades from ShredStream, design an enrichment or fallback path if required fields are missing.

## Bot Integration Rules

- Keep callbacks short. Push events into a strategy queue if trade construction or RPC calls are expensive.
- Deduplicate by signature plus event index, or by mint for first-buy strategies.
- Record stream receive timestamp and pass it into downstream trade params if the trade SDK exposes latency tracing.
- Use `stop()` or signal handling for graceful shutdown.
- Enable metrics only when measuring; metrics add overhead.

## Multi-Language Guidance

If the user asks for TypeScript, Python, or Go streamer-like code, first check whether a language-specific package exists. If not, combine that language's `sol-parser-sdk-*` bindings with the same facade concepts: typed event stream, narrow filters, strategy callback, and replay helpers.
