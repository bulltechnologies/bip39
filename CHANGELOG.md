## Unreleased

### Native crypto backend
- Upgraded the pinned **[native_crypto](https://github.com/bulltechnologies/native_crypto)** backend to commit `b7565bde3f0cf196d65fbfdcdd9ca348f806450a`, including its latest native-provider hardening, native arena/output-buffer APIs, and device-bound key-enclave support.
- Adopted native output-buffer APIs for BIP39 checksum hashing and CSPRNG entropy filling to reduce transient secret allocations.
- Example integration tests opt into `NativeCryptoTesting.allowUiIsolate()` so real-provider KATs remain compatible with native_crypto's debug root-isolate guard.

## 2.0.0

### Native crypto backend (breaking)
- **Flutter-only:** requires Flutter and Dart **≥ 3.12**. Dart VM-only and web targets are unsupported (no pure-Dart fallback).
- All cryptographic primitives delegate to **[native_crypto](https://github.com/bulltechnologies/native_crypto)**: `SecureRandom`, `Sha256`, PBKDF2-HMAC-SHA512, and Argon2id.
- Removed `crypto` and `pointycastle` dependencies and local pure-Dart KDF implementations.
- **Seed outputs unchanged:** BIP39 encoding, NFKD normalization, wordlists, checksum logic, `Bip39Kdf`, `Bip39SeedOptions`, legacy profiles, and synchronous public APIs are preserved byte-for-byte.
- `Bip39Argon2Params.version` remains an `int` (`Bip39Argon2Version.v10` / `v13`); mapped internally to native Argon2 version enums.
- Synchronous native calls must run from a **persistent background crypto isolate** (not the UI isolate). No async API or automatic isolate wrapper is provided.
- CI uses Flutter tooling and rejects remaining `crypto` / `pointycastle` imports.

## 1.2.0

### BIP39 compliance (defaults)
- [Bip39SeedOptions.defaults] and top-level [mnemonicToSeed] / [mnemonicToSeedHex] use [Bip39SeedEncoding.bip39Compliant] (NFKD + UTF-8) and [Bip39Kdf.pbkdf2] (HMAC-SHA512, 2048 iterations, 64-byte seed) per the [BIP39 spec](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki).
- Trezor English and Japanese vector suites pass with default options (no encoding or KDF overrides).
- [Bip39SeedOptions.legacyDefaults] for dart-bitcoin 1.0.x / Trezor ASCII `codeUnits` mnemonic encoding.

### Optional Argon2id
- [Bip39Kdf.argon2id] opt-in via [Bip39SeedOptions.argon2], `kdf: Bip39Kdf.argon2id`, or `argon2Params` on [Bip39SeedOptions].
- [Bip39Argon2Params] for cost tuning (~64 MiB, 4 lanes, 4 iterations by default); [Bip39Argon2Params.test] for fast unit tests.
- Implemented with pointycastle Argon2id (no extra dependency).
- [MIGRATION.md](MIGRATION.md): detailed upgrade guide (emphasis on dart-bitcoin 1.0.0 wallet compatibility).

## 1.1.0

Maintained fork under [bulltechnologies/bip39](https://github.com/bulltechnologies/bip39), based on [dart-bitcoin/bip39](https://github.com/dart-bitcoin/bip39).

### Security & memory
- [zeroizeBytes], [SensitiveBytes], and [Bip39.mnemonicToSeedSensitive] for clearing seed buffers after use.
- PBKDF2 password/salt buffers zeroed by default ([Bip39SeedOptions.zeroizeIntermediateBuffers]).
- RNG entropy buffer zeroed after [Bip39.generateMnemonic].
- SHA-256 checksum scratch buffer zeroed during mnemonic encode/decode.
- Documented Dart VM limits: [String] secrets cannot be wiped from the heap.

### BIP39 correctness
- Fix CSPRNG off-by-one: all byte values 0–255 are reachable in `generateMnemonic`.
- Replace debug-only `assert` on `strength` with `Bip39InvalidStrengthException` at runtime.
- [Bip39SeedOptions] uses [Bip39SeedEncoding.bip39Compliant] for the facade API.
- NFKD per-word normalization before wordlist lookup ([normalizeWords], default `true`).
- Japanese mnemonics encode with U+3000 separators by default ([useIdeographicSeparator]).
- Invalid entropy hex throws [Bip39InvalidEntropyException] instead of [FormatException].
- [test/japanese_vectors.json]: 24 vectors from [bip32JP](https://github.com/bip32JP/bip32JP.github.io/blob/master/test_JP_BIP39.json).

### Wordlists
- All 10 official BIP39 languages (incl. Portuguese per current bitcoin/bips).
- [Bip39Language], [Bip39Wordlist], [Bip39Wordlists] registry with O(1) lookup.
- Exported raw arrays: `englishWords`, `japaneseWords`, … (`WORDLIST` alias preserved).
- `tool/generate_wordlists.dart` + `tool/wordlist_src/` for reproducible regeneration.

### Architecture
- [MnemonicCodec] per-language encode/decode.
- [Bip39] facade with [Bip39MnemonicOptions], [Bip39ValidateOptions], [Bip39EntropyOptions], [Bip39SeedOptions].
- Top-level API unchanged for English defaults; optional `language` on all mnemonic functions.
- `validateMnemonicDetailed`, typed `Bip39*Exception` hierarchy, `MnemonicValidationResult`.
- `entropyToMnemonicFromBytes`, `allowedMnemonicStrengths`, `bip39Normalize`.
- Optional `normalizeInput` on mnemonic parsing/validation.

### Reliability & tooling
- O(1) English word lookup via index map; reused `PBKDF2` instance for seed derivation.
- Wordlist validation: exactly 2048 unique words at load time.
- Japanese ideographic space (U+3000) support when `normalizeInput: true`.
- Cross-language tests; English vector suite unchanged.
- Dart SDK `>=3.0.0 <4.0.0`, updated dependencies, `lints`, CI workflow.

## 1.0.6

- Resolved nullsafety code issues

## 1.0.0

- Initial version (dart-bitcoin/bip39 lineage)
