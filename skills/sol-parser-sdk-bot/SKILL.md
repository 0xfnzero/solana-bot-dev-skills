---
name: sol-parser-sdk-bot
description: Use this skill when developing bots or SDK integrations with sol-parser-sdk, including Rust and multi-language variants, direct parsing, Yellowstone gRPC subscriptions, event filters, account subscriptions, ShredStream, RPC transaction replay, DEX event matching, and parser contribution work.
---

# Sol Parser SDK Bot

Use this skill for direct `sol-parser-sdk` usage. If the user wants a higher-level stream facade, consider `solana-streamer-bot` first.

## What The SDK Provides

- Low-latency Solana DEX event parsing.
- Yellowstone gRPC subscription helpers.
- RPC transaction parsing by fetched transaction or signature.
- Account subscriptions and account event parsing.
- Jito ShredStream support with important data-completeness caveats.
- Protocol and event filtering for parser-side pruning.
- Contribution paths for adding protocols, event types, account fillers, and examples.

Supported protocol families include PumpFun, PumpSwap/Pump AMM, Pump Fees, Bonk/Raydium Launchpad, Raydium CPMM, Raydium CLMM, Raydium AMM V4, Meteora DAMM v2, Meteora Pools, Meteora DLMM, and Orca Whirlpool.

Current source layout:

- `src/core/events/enum_impl.rs` and `src/core/events/types.rs`: `DexEvent` variants and event structs.
- `src/grpc/types.rs`: `OrderMode`, `ClientConfig`, `Protocol`, `EventType`, `EventTypeFilter`, transaction/account filters.
- `src/grpc/filter.rs`: `TransactionFilter::for_protocols` and `AccountFilter::for_protocols`.
- `src/instr`, `src/logs`, `src/accounts`: instruction, log, and account parsers.
- `src/rpc_parser.rs`: RPC transaction parsing helpers.
- `examples/`: runnable gRPC, RPC parse, account subscription, ShredStream, and debug examples.

## Rust Imports And Setup

Typical dependency:

```toml
sol-parser-sdk = "0.5.1"
```

For max parser performance in Rust:

```toml
sol-parser-sdk = { version = "0.5.1", default-features = false, features = ["parse-zero-copy"] }
```

Common Rust imports:

```rust
use sol_parser_sdk::grpc::{
    AccountFilter, ClientConfig, EventType, EventTypeFilter, OrderMode, Protocol,
    TransactionFilter, YellowstoneGrpc,
};
use sol_parser_sdk::DexEvent;
```

## Multi-Language Packages

Use the target repo's language and package manager. Current package names and directly installable package versions:

| Language | Package/module | Version | Install |
|----------|----------------|---------|---------|
| Rust | `sol-parser-sdk` | `0.5.1` | `cargo add sol-parser-sdk@0.5.1` |
| Node.js/TypeScript | `sol-parser-sdk-nodejs` | `0.4.4` on npm | `npm install sol-parser-sdk-nodejs@0.4.4` |
| Python | `sol-parser-sdk-python` | `0.4.5` | `pip install sol-parser-sdk-python==0.4.5` |
| Go | `github.com/0xfnzero/sol-parser-sdk-golang` | `v0.4.5` | `go get github.com/0xfnzero/sol-parser-sdk-golang@v0.4.5` |

The Node.js repository has a `v0.4.5` tag/package.json, but npm `latest` is `0.4.4` as of the source review. Do not generate `npm install sol-parser-sdk-nodejs@0.4.5` unless that package version is published or the user is installing from GitHub/tag source.

Language-specific entry points:

- Node.js/TypeScript: import from `sol-parser-sdk-nodejs`; for live bot streams use `new YellowstoneGrpc(...).subscribeDexEvents(...)`, `transactionFilterForProtocols`, `eventTypeFilterIncludeOnly`, and async iteration over the subscription. Use lower-level `parseDexEventsFromGrpcTransactionInfo`, `parseLogsOnly`, and `dexEventToJsonString` only for custom gRPC callbacks, replay, or debugging.
- Python: import from `sol_parser`; for live bot streams use `YellowstoneGrpc.new_with_config(...)`, `transaction_filter_for_protocols`, `event_type_filter_include_only`, and `await client.subscribe_dex_events(...)`, which returns an `asyncio.Queue[DexEvent]`. Use `parse_logs_only` for lower-level log parsing or RPC/debug utilities.
- Go: import `github.com/0xfnzero/sol-parser-sdk-golang/solparser`; for live bot streams use `NewYellowstoneGrpc`, `TransactionFilterForProtocols`, `EventTypeFilterIncludeOnly`, and `SubscribeDexEvents`. Use `ParseSubscribeTransaction` for custom Geyser transaction handling and `DexEventsFromShredTransactionWire` for ShredStream wire transactions.

Environment naming differs by language:

- Node.js: gRPC examples use `GRPC_URL` and `GRPC_TOKEN`; ShredStream uses `SHREDSTREAM_URL` or `SHRED_URL`, and PumpFun Shred JSON also needs `RPC_URL`.
- Python: accepts `GRPC_URL`/`GRPC_ENDPOINT`, `GRPC_AUTH_TOKEN`/`GRPC_TOKEN`, with CLI overrides such as `--grpc-url` and `--grpc-token`.
- Go: gRPC examples use `GRPC_URL` and `GRPC_TOKEN`; RPC utility uses `TX_SIGNATURE` and `RPC_URL`; ShredStream uses `SHRED_URL`.

Do not translate Rust identifiers mechanically. Check the target language README/examples first, then preserve concepts: protocol selection, transaction/account filters, event type filters, typed/JSON event handling, RPC replay, and ShredStream caveats.

Source-verified live stream API map:

| Concept | Rust | Node.js/TypeScript | Python | Go |
|---------|------|--------------------|--------|----|
| Client | `YellowstoneGrpc::new_with_config` | `new YellowstoneGrpc(endpoint, token)` | `YellowstoneGrpc.new_with_config(endpoint, token, config)` | `solparser.NewYellowstoneGrpc(endpoint, cfg)` |
| Protocol tx filter | `TransactionFilter::for_protocols` | `transactionFilterForProtocols(["PumpFun"])` | `transaction_filter_for_protocols([Protocol.PUMP_FUN])` | `solparser.TransactionFilterForProtocols([]solparser.Protocol{...})` |
| Event filter | `EventTypeFilter::include_only` | `eventTypeFilterIncludeOnly([...])` | `event_type_filter_include_only([...])` | `solparser.EventTypeFilterIncludeOnly(...)` |
| Subscribe | `subscribe_dex_events` | `subscribeDexEvents` async iterable | `subscribe_dex_events` returns `asyncio.Queue` | `SubscribeDexEvents` returns channels |
| Event type names | `EventType::PumpFunBuy` | `"PumpFunBuy"` | `EventType.PUMP_FUN_BUY` | `solparser.EventTypePumpFunBuy` |

## Subscription Pattern

Use this shape for low-latency consumers:

```rust
let config = ClientConfig {
    order_mode: OrderMode::Unordered,
    enable_metrics: false,
    ..Default::default()
};
let grpc = YellowstoneGrpc::new_with_config(endpoint, token, config)?;

let protocols = vec![Protocol::PumpFun, Protocol::PumpSwap];
let tx_filter = TransactionFilter::for_protocols(&protocols);
let account_filter = AccountFilter::for_protocols(&protocols);
let event_filter = EventTypeFilter::include_only(vec![
    EventType::PumpFunBuy,
    EventType::PumpFunSell,
    EventType::PumpSwapBuy,
    EventType::PumpSwapSell,
]);

let queue = grpc
    .subscribe_dex_events(vec![tx_filter], vec![account_filter], Some(event_filter))
    .await?;

while let Some(event) = queue.pop() {
    match event {
        DexEvent::PumpFunBuy(e) => {
            // inspect e.mint, e.sol_amount, e.is_created_buy, reserves, creator, etc.
        }
        _ => {}
    }
}
```

Use a hybrid spin/yield loop only for latency-sensitive Rust bots. For normal services, prefer a sleep/yield loop to reduce CPU use.

## Filters

- Use `TransactionFilter::for_protocols(&protocols)` to listen for transactions touching protocol programs.
- Use `AccountFilter::for_protocols(&protocols)` for owner-based account subscriptions.
- Use `EventTypeFilter::include_only(...)` when you know the event types; it reduces parser work.
- Use `exclude_types(...)` when you want broad streams minus a few event types; it cannot be used as a full protocol skip hint.
- For wallet tracking, use `account_include` or `account_required` with the wallet address plus relevant DEX program filters.

Important event groups:

- PumpFun: `PumpFunCreate`, `PumpFunCreateV2`, `PumpFunBuy`, `PumpFunSell`, `PumpFunBuyExactSolIn`, `PumpFunMigrate`.
- PumpSwap: `PumpSwapCreatePool`, `PumpSwapBuy`, `PumpSwapSell`, liquidity events.
- Raydium/Orca/Meteora: usually start with swap events, then add pool/liquidity events only if the strategy needs them.
- Accounts: `TokenAccount`, `NonceAccount`, `AccountPumpFun*`, `AccountPumpSwapPool`, `AccountRaydiumClmm*`.

PumpFun note: `PumpFunTrade` is the broad trade group; `PumpFunBuy`, `PumpFunSell`, and `PumpFunBuyExactSolIn` are filtered views over the parsed trade event. For sniping, include create plus buy event types and check `PumpFunTradeEvent.is_created_buy`.

Account subscription:

- Exact account: `AccountFilter { account: vec![pubkey], owner: vec![], filters: vec![] }`.
- Owner/program account stream: `AccountFilter::for_protocols(&[Protocol::PumpSwap])` or `add_owner`.
- Memcmp filters: use `account_filter_memcmp(offset, bytes)` from `grpc::types`; ATA mint is commonly offset `0`, PumpSwap pool mint/pubkey filters often use offset `32`.
- Account-only listeners can pass an empty/default transaction filter with a specific account filter and account `EventTypeFilter`.

## Order Mode Choice

- `Unordered`: lowest latency, immediate output. Best for sniping and most monitors.
- `MicroBatch`: short microsecond window, sorted output. Good when strategy benefits from near-ordering but still needs speed.
- `StreamingOrdered`: lower latency than full ordered, releases continuous tx-index sequences.
- `Ordered`: full slot ordering, highest latency. Use for analysis, replay-like behavior, or strict order requirements.

## RPC Parsing

Use RPC parsing for debugging, replay, regression tests, and support tickets:

- `parse_transaction_from_rpc` fetches and parses by signature.
- `parse_rpc_transaction` parses an already fetched encoded transaction.
- Keep sample signatures in tests when adding support for a new event type.

## ShredStream Caveat

ShredStream can be faster but may not contain every detail needed by trade construction, especially inner/CPI-only information or ALT-loaded account data. If trading logic depends on full account fields, verify the event has every required field before sending a trade. Fall back to gRPC/RPC enrichment when needed.

## Parser Contribution Workflow

When modifying the parser:

1. Inspect `src/instr`, `src/logs`, `src/accounts`, `src/grpc`, and IDL files for the target protocol pattern.
2. Add event structs/variants in `src/core/events`, then map `EventType` and protocol filter behavior in `src/grpc/types.rs`.
3. Add program IDs and route instruction/log parsing through existing protocol dispatchers.
4. Add account fillers in `src/core/account_fillers` only when event fields must be enriched from account keys/data.
5. Prefer Borsh/easy-to-maintain parsing first; add zero-copy specialization only when there is a measured hot path need.
6. Avoid heap allocation in hot parser paths; use bounded buffers, `#[inline]`, and existing SIMD/memchr patterns where local code already does so.
7. Add RPC-by-signature examples or tests for the new event.
8. Run `cargo fmt`, `cargo test`, targeted examples, and release-mode examples when latency matters.

## Sniping And Copy-Trading Hints

- Sniping: filter `PumpFunCreate`, `PumpFunBuy`, and `PumpFunBuyExactSolIn`; when a buy event has `is_created_buy`, hand the event to `sol-trade-sdk`.
- Copy trading: use `TransactionFilter.account_include` or `account_required` for the target wallet plus DEX programs; filter buy/sell event types; deduplicate by signature and event index.
- The parser discovers and normalizes events; order placement belongs in `sol-trade-sdk`.
- If strict wallet order matters, prefer `MicroBatch` or `StreamingOrdered`; if latency matters more, use `Unordered`.

## Multi-Language Guidance

For Node.js, Python, or Go variants, preserve the same concepts even if names differ:

- Protocol selection.
- Transaction/account filters.
- Event type include/exclude filters.
- Typed event matching.
- RPC parse vs live stream distinction.
- Order mode or delivery semantics where exposed.

Before writing non-Rust code, inspect that language repo's README/examples or installed package types. Do not assume the Rust API names are identical.

## Multi-Language Example Selection

- Node.js parser stream: `examples/pumpfun_grpc_json.ts`, `examples/pumpfun_trade_filter.ts`, `examples/multi_protocol_grpc.ts`, `examples/parse_tx_by_signature.ts`.
- Python parser stream: `examples/pumpfun_trade_filter.py`, `examples/pumpfun_with_metrics.py`, `examples/multi_protocol_grpc.py`, `examples/parse_tx_by_signature.py`.
- Go parser stream: `examples/yellowstone_grpc_parse.go`, `examples/pumpfun_trade_filter.go`, `examples/multi_protocol_grpc.go`, `examples/parse_tx_by_signature.go`.
