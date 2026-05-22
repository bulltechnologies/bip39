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
- Default [Bip39SeedOptions] uses [Bip39SeedEncoding.bip39Compliant]; top-level API still defaults to `legacy`.
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
