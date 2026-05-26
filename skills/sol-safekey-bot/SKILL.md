---
name: sol-safekey-bot
description: Use this skill when integrating sol-safekey into Solana bots or tools, including encrypted keystores, interactive wallet management, password handling, wallet unlock, bot startup scripts, SOL/SPL/WSOL operations, durable nonce setup, and secure key handling for Rust or multi-language bot stacks.
---

# Sol SafeKey Bot

Use `sol-safekey` whenever a bot needs wallet creation, encrypted keystore storage, unlock, or secure Solana operations.

## Core Security Rules

- Do not hard-code base58 private keys.
- Do not store wallet passwords in environment variables.
- Do not commit keystores, decrypted keys, `.env`, logs with secrets, or startup scripts containing secrets.
- Prefer encrypted keystore files plus stdin or interactive password entry.
- Clear password variables in shell scripts after use.
- Keep real trading disabled until wallet loading and simulation paths are verified.

## Dependency

For bot integration:

```toml
sol-safekey = { version = "0.1.7", features = ["solana-ops"] }
```

For local path development:

```toml
sol-safekey = { path = "../sol-safekey", features = ["solana-ops"] }
```

Feature flags include `cli`, `2fa`, `solana-ops`, `sol-trade-sdk`, and `full`.

## Three Integration Modes

### 1. Embedded Interactive Menu

Add a `safekey` subcommand before bot startup:

```rust
if std::env::args().nth(1).as_deref() == Some("safekey") {
    sol_safekey::interactive::show_main_menu()
        .map_err(|e| anyhow::anyhow!(e))?;
    return Ok(());
}
```

Users run:

```bash
./your-bot safekey
```

### 2. Bot Helper Unlock

Use the helper when an interactive unlock is acceptable:

```rust
let keypair = sol_safekey::bot_helper::ensure_wallet_ready("keystore.json")?;
```

### 3. Programmatic Keystore Load

Use this when the bot reads a password from stdin or another secure source:

```rust
use sol_safekey::KeyManager;
use std::io::{self, Read};

let json = std::fs::read_to_string("keystore.json")?;
let mut password = String::new();
io::stdin().read_to_string(&mut password)?;
let keypair = KeyManager::keypair_from_encrypted_json(&json, password.trim())?;
```

For creating a keystore:

```rust
let keypair = sol_safekey::KeyManager::generate_keypair();
let json = sol_safekey::KeyManager::keypair_to_encrypted_json(&keypair, password)?;
std::fs::write("keystore.json", json)?;
```

## Startup Script Pattern

Prefer stdin over env vars:

```bash
#!/usr/bin/env bash
set -euo pipefail

read -rsp "Wallet password: " WALLET_PASSWORD
echo
printf '%s' "$WALLET_PASSWORD" | ./target/release/your-bot
WALLET_PASSWORD=""
unset WALLET_PASSWORD
```

Avoid `export WALLET_PASSWORD=...`.

## Bot Integration With sol-trade-sdk

After unlocking, pass the keypair as the payer to `sol-trade-sdk`:

```rust
let payer = std::sync::Arc::new(keypair);
let trade_client = sol_trade_sdk::SolanaTrade::new(payer, trade_config).await;
```

Keep wallet handling separate from trade strategy. The strategy should receive a signer/client, not raw private key text.

## CLI Capabilities

The CLI can create encrypted wallets, decrypt, unlock, check balances, transfer SOL/SPL, wrap/unwrap WSOL, close WSOL ATA, create durable nonce accounts, and perform supported PumpFun/PumpSwap sell/cashback operations when features are enabled.

Use CLI or interactive mode for setup; use library APIs for bot runtime.

## Review Checklist

- Keystore path is configurable.
- Password is read from stdin, prompt, or a secret manager; not an env var.
- Private key strings do not appear in source, tests, logs, or errors.
- Runtime logs print public key only.
- `.gitignore` excludes keystores, logs, and local config.
- Bot can start in dry-run/simulate mode after unlocking.

## Multi-Language Guidance

If the bot is not Rust, prefer using `sol-safekey` CLI for wallet lifecycle and a small bridge that returns a signer only inside the local process. If a native binding is unavailable, do not reimplement encryption casually; use the CLI/library as the trust boundary or ask the user how they want secrets managed.
