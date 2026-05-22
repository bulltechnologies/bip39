# bip39

Production-grade [BIP39](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki) mnemonic generation and seed derivation for Dart and Flutter.

[![CI](https://github.com/bulltechnologies/bip39/actions/workflows/ci.yml/badge.svg)](https://github.com/bulltechnologies/bip39/actions/workflows/ci.yml)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](LICENSE)
[![Dart SDK](https://img.shields.io/badge/SDK-%3E%3D3.0.0%20%3C4.0.0-blue)](pubspec.yaml)

Maintained by **[bulltechnologies](https://github.com/bulltechnologies)** — fork of [dart-bitcoin/bip39](https://github.com/dart-bitcoin/bip39) (originally ported from [bitcoinjs/bip39](https://github.com/bitcoinjs/bip39)).

## Install

**pub.dev** (when published):

```yaml
dependencies:
  bip39: ^1.2.0
```

**Git** (current source of truth):

```yaml
dependencies:
  bip39:
    git:
      url: https://github.com/bulltechnologies/bip39.git
      ref: v1.2.0 # or a commit SHA on master
```

```bash
dart pub get
```

## Quick start

```dart
import 'package:bip39/bip39.dart';

// English mnemonic (12 words, 128-bit entropy)
final mnemonic = generateMnemonic();

// 64-byte seed (BIP39 PBKDF2 + NFKD/UTF-8 by default)
final seed = mnemonicToSeed(mnemonic, passphrase: 'optional');

// Hex seed for logging-free copy paths
final seedHex = mnemonicToSeedHex(mnemonic);
```

## Why this fork (1.2.0)

| Area | What you get |
|------|----------------|
| Wordlists | All **10** official BIP39 languages with O(1) lookup |
| Correctness | Trezor English + Japanese vector suites; spec-compliant NFKD seed path |
| API | Layered: top-level helpers, `Bip39` facade, `MnemonicCodec`, raw word arrays |
| Security | Typed errors, buffer zeroization hooks, documented Dart `String` limits |
| KDF | **BIP39 PBKDF2** by default; optional Argon2id for stronger non-standard derivation |
| Compatibility | Spec-compliant encoding + PBKDF2; `legacyDefaults` for dart-bitcoin 1.0.x seeds |

See [CHANGELOG.md](CHANGELOG.md) for release notes and **[MIGRATION.md](MIGRATION.md)** for upgrading from dart-bitcoin 1.0.x (wallet seed compatibility, legacy encoding, Argon2 opt-in).

## Features

- **10 official wordlists** — English, Japanese, Korean, Spanish, Chinese (Simplified/Traditional), French, Italian, Czech, Portuguese
- **Test vectors** — [Trezor English](https://github.com/trezor/python-mnemonic/blob/master/vectors.json), [Japanese BIP39](https://github.com/bip32JP/bip32JP.github.io/blob/master/test_JP_BIP39.json)
- **Structured validation** — `validateMnemonicDetailed`, `Bip39FailureReason`, typed exceptions
- **BIP39 seed derivation** — PBKDF2-HMAC-SHA512 (2048 iterations) + NFKD/UTF-8 encoding by default
- **Optional Argon2id** — memory-hard KDF via `Bip39SeedOptions.argon2` (not BIP39-standard)
- **Seed encoding** — `bip39Compliant` (default) or `legacy` for 1.0.x / Trezor ASCII mnemonics
- **Memory hygiene** — zeroize KDF intermediates, RNG entropy, and seed `Uint8List`s where possible

## Wordlists

### Registry

```dart
for (final lang in Bip39Language.values) {
  print(lang.displayName);
}

final japanese = Bip39Wordlists.forLanguage(Bip39Language.japanese);
print(japanese.words.length); // 2048
print(japanese.lookupIndex('あいこくしん'));
```

### Raw arrays (UI, autocomplete, custom validators)

| Language | Constant |
|----------|----------|
| English | `englishWords` / `WORDLIST` (legacy alias) |
| Japanese | `japaneseWords` |
| Korean | `koreanWords` |
| Spanish | `spanishWords` |
| Chinese (Simplified) | `chineseSimplifiedWords` |
| Chinese (Traditional) | `chineseTraditionalWords` |
| French | `frenchWords` |
| Italian | `italianWords` |
| Czech | `czechWords` |
| Portuguese | `portugueseWords` |

```dart
import 'package:bip39/bip39.dart' show frenchWords, Bip39Wordlists;

final words = frenchWords;
// or: Bip39Wordlists.forLanguage(Bip39Language.french).words
```

## API overview

Three layers; pick the shallowest that fits.

### 1. Top-level functions (English default)

Same entry points as dart-bitcoin/bip39 1.0.x. Optional `language`, `normalizeInput`, and `seedEncoding` were added without breaking existing call sites.

```dart
generateMnemonic(strength: 256, language: Bip39Language.spanish);
validateMnemonic(phrase, language: Bip39Language.french, normalizeInput: true);
mnemonicToSeedHex(phrase, passphrase: 'TREZOR');
entropyToMnemonic('00000000000000000000000000000000');
mnemonicToEntropy(mnemonic);
```

### 2. `Bip39` facade + option objects

```dart
Bip39.generateMnemonic(
  options: Bip39MnemonicOptions(
    language: Bip39Language.korean,
    strength: 192,
    normalizeInput: true,
  ),
);

Bip39.mnemonicToSeed(
  mnemonic,
  options: Bip39SeedOptions(
    passphrase: 'secret',
    seedEncoding: Bip39SeedEncoding.bip39Compliant,
  ),
);
```

| Class | Controls |
|-------|----------|
| `Bip39MnemonicOptions` | `language`, `strength`, `normalizeInput`, `randomBytes` |
| `Bip39EntropyOptions` | `language`, `normalizeInput` |
| `Bip39ValidateOptions` | `language`, `normalizeInput` |
| `Bip39SeedOptions` | `passphrase`, `seedEncoding`, `kdf`, `argon2Params`, `zeroizeIntermediateBuffers` |

### 3. `MnemonicCodec` (per-language)

```dart
final codec = MnemonicCodec.forLanguage(Bip39Language.italian);
final mnemonic = codec.entropyToMnemonic(entropyHex);
final entropy = codec.mnemonicToEntropy(mnemonic);
final ok = codec.validateMnemonicDetailed(mnemonic);
```

## Configuration reference

| Concern | Parameter | Default |
|---------|-----------|---------|
| Wordlist | `language` / `Bip39Language` | `english` |
| Entropy bits | `strength` | `128` → 12 words |
| Trim / Unicode whitespace | `normalizeInput` | `false` |
| NFKD per-word lookup | `normalizeWords` | `true` |
| Japanese U+3000 when encoding | `useIdeographicSeparator` | `true` (Japanese) |
| Passphrase | `passphrase` | `''` |
| KDF | `kdf` | `pbkdf2` (BIP39) |
| Seed encoding | `seedEncoding` | `bip39Compliant` |
| Argon2id (optional) | `kdf: Bip39Kdf.argon2id` or `Bip39SeedOptions.argon2` | — |
| Argon2 cost | `argon2Params` | 64 MiB, 4 lanes, 4 iterations |
| Zeroize KDF password/salt | `zeroizeIntermediateBuffers` | `true` |
| Custom RNG | `randomBytes` | OS CSPRNG |

Allowed strengths: `128`, `160`, `192`, `224`, `256`.

## Seed derivation

| KDF | Use when |
|-----|----------|
| `Bip39Kdf.pbkdf2` (default) | BIP39 spec, Trezor, Ledger, hardware wallets, test vectors |
| `Bip39Kdf.argon2id` | Optional stronger derivation (seeds differ from standard wallets) |

```dart
// BIP39 default (PBKDF2 + compliant encoding)
Bip39.mnemonicToSeed(mnemonic);

// Optional Argon2id
Bip39.mnemonicToSeed(mnemonic, options: Bip39SeedOptions.argon2);
```

### Seed encoding

| Mode | Use when |
|------|----------|
| `Bip39SeedEncoding.legacy` | Matching dart-bitcoin/bip39 1.0.x, Trezor ASCII vectors |
| `Bip39SeedEncoding.bip39Compliant` | Default — NFKD + UTF-8 per BIP39 |

```dart
// Trezor-compatible: legacy encoding + PBKDF2
mnemonicToSeedHex(
  m,
  seedEncoding: Bip39SeedEncoding.legacy,
  kdf: Bip39Kdf.pbkdf2,
);
```

## Validation

```dart
if (validateMnemonic(phrase)) { /* ... */ }

final result = validateMnemonicDetailed(phrase);
if (!result.isValid) {
  switch (result.reason) {
    case Bip39FailureReason.unknownWord:
      print('Unknown: ${result.unknownWord}');
    case Bip39FailureReason.invalidChecksum:
      // warn user — phrase may be from another app/language
    default:
      break;
  }
}
```

**Recovery UX:** BIP39 allows phrases with invalid checksums from other wallets or languages. Warn when the checksum fails, but let power users confirm import after basic checks (word count ≥ 12, separator present).

## Memory & secrets

Dart **cannot** erase `String` mnemonics or passphrases from the heap. The library still clears sensitive **byte buffers** where it controls allocation:

| Buffer | Cleared when |
|--------|----------------|
| KDF password & salt | After `Bip39.mnemonicToSeed` with default `zeroizeIntermediateBuffers` |
| RNG entropy in `Bip39.generateMnemonic` | Always after encoding |
| Decoded entropy hex | After `entropyToMnemonic` |
| Internal entropy in `mnemonicToEntropy` | In `finally` after checksum |
| SHA-256 checksum scratch | After checksum derivation |

**Caller-owned seed:**

```dart
final sensitive = Bip39.mnemonicToSeedSensitive(mnemonic);
try {
  final seed = sensitive.bytes;
  // HD wallet / secure storage
} finally {
  sensitive.zeroize();
}

// Or raw Uint8List:
final seed = Bip39.mnemonicToSeed(mnemonic);
try {
  // use seed
} finally {
  seed.zeroize();
}
```

Do not log mnemonics, passphrases, or seeds. Buffer zeroization reduces heap exposure; it does not defeat swap, core dumps, or VM copies — use platform secure storage when available.

## Migrating from dart-bitcoin/bip39

**→ Full guide: [MIGRATION.md](MIGRATION.md)** (1.0.0 wallet treatment, golden tests, encoding migration, 1.1/1.2 features).

| Before (1.0.x) | After (bulltechnologies 1.2.0) |
|----------------|--------------------------------|
| `import 'package:bip39/bip39.dart'` | Same import |
| `generateMnemonic()` | Unchanged; add `language:` as needed |
| `mnemonicToSeed` / `mnemonicToSeedHex` | Default **bip39Compliant** + PBKDF2; **1.0.x wallets must use [Bip39SeedOptions.legacyDefaults]** |
| English-only | Optional `Bip39Language.*` on all mnemonic APIs |
| `WORDLIST` | Still exported; prefer `englishWords` |

## Regenerating wordlists

Sources live in `tool/wordlist_src/` (from [bitcoin/bips bip-0039](https://github.com/bitcoin/bips/tree/master/bip-0039)):

```bash
dart run tool/generate_wordlists.dart
```

CI verifies generated files stay in sync.

## Development

```bash
dart pub get
dart analyze
dart test
```

Requires Dart **≥ 3.0.0**.

## License & attribution

- **License:** [BSD-3-Clause](LICENSE) — Copyright (c) 2026 **bulltechnologies**
- **Upstream:** [NOTICE](NOTICE) documents lineage from dart-bitcoin/bip39 and bitcoinjs/bip39

BIP39 specification: [bip-0039](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki).
