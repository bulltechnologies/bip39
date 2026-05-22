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
  bip39: ^1.1.0
```

**Git** (current source of truth):

```yaml
dependencies:
  bip39:
    git:
      url: https://github.com/bulltechnologies/bip39.git
      ref: v1.1.0 # or a commit SHA on master
```

```bash
dart pub get
```

## Quick start

```dart
import 'package:bip39/bip39.dart';

// English mnemonic (12 words, 128-bit entropy)
final mnemonic = generateMnemonic();

// 64-byte seed (PBKDF2-HMAC-SHA512, 2048 iterations)
final seed = mnemonicToSeed(mnemonic, passphrase: 'optional');

// Hex seed for logging-free copy paths
final seedHex = mnemonicToSeedHex(mnemonic);
```

## Why this fork (1.1.0)

| Area | What you get |
|------|----------------|
| Wordlists | All **10** official BIP39 languages with O(1) lookup |
| Correctness | Trezor English + Japanese vector suites; spec-compliant NFKD seed path |
| API | Layered: top-level helpers, `Bip39` facade, `MnemonicCodec`, raw word arrays |
| Security | Typed errors, buffer zeroization hooks, documented Dart `String` limits |
| Compatibility | English defaults and `legacy` seed encoding match pre-fork integrations |

See [CHANGELOG.md](CHANGELOG.md) for the full release notes.

## Features

- **10 official wordlists** — English, Japanese, Korean, Spanish, Chinese (Simplified/Traditional), French, Italian, Czech, Portuguese
- **Test vectors** — [Trezor English](https://github.com/trezor/python-mnemonic/blob/master/vectors.json), [Japanese BIP39](https://github.com/bip32JP/bip32JP.github.io/blob/master/test_JP_BIP39.json)
- **Structured validation** — `validateMnemonicDetailed`, `Bip39FailureReason`, typed exceptions
- **Seed encoding** — `legacy` (1.0.x / Trezor ASCII) and `bip39Compliant` (NFKD + UTF-8 per spec)
- **Memory hygiene** — zeroize PBKDF2 intermediates, RNG entropy, and seed `Uint8List`s where possible

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
mnemonicToSeedHex(phrase, passphrase: 'TREZOR', seedEncoding: Bip39SeedEncoding.legacy);
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
| `Bip39SeedOptions` | `passphrase`, `seedEncoding`, `zeroizeIntermediateBuffers` |

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
| PBKDF2 passphrase | `passphrase` | `''` |
| Seed bytes (`Bip39` API) | `seedEncoding` | `bip39Compliant` |
| Seed bytes (top-level) | `seedEncoding` | `legacy` |
| Zeroize PBKDF2 password/salt | `zeroizeIntermediateBuffers` | `true` |
| Custom RNG | `randomBytes` | OS CSPRNG |

Allowed strengths: `128`, `160`, `192`, `224`, `256`.

## Seed encoding

| Mode | Use when |
|------|----------|
| `Bip39SeedEncoding.legacy` | Matching dart-bitcoin/bip39 1.0.x, Trezor ASCII vectors, existing app behavior |
| `Bip39SeedEncoding.bip39Compliant` | Unicode passphrases, hardware-wallet parity, full spec NFKD + UTF-8 |

```dart
// Top-level defaults to legacy
mnemonicToSeedHex(m);

// Spec-complete
mnemonicToSeedHex(m, seedEncoding: Bip39SeedEncoding.bip39Compliant);
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
| PBKDF2 password & salt | After `Bip39.mnemonicToSeed` with default `zeroizeIntermediateBuffers` |
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

| Before (1.0.x) | After (bulltechnologies 1.1.0) |
|----------------|--------------------------------|
| `import 'package:bip39/bip39.dart'` | Same import |
| `generateMnemonic()` | Unchanged; add `language:` as needed |
| `mnemonicToSeed` / `mnemonicToSeedHex` | Still **legacy** by default at top level |
| English-only | Optional `Bip39Language.*` on all mnemonic APIs |
| `WORDLIST` | Still exported; prefer `englishWords` |

Change `pubspec.yaml` dependency to bulltechnologies (git URL above or pub.dev once published). No code changes required for typical English + legacy seed paths.

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
