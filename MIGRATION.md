# Migration guide

This document covers upgrading from **[dart-bitcoin/bip39](https://github.com/dart-bitcoin/bip39) 1.0.x** through **bulltechnologies/bip39 1.1.0**, **1.2.0**, and **2.0.0**.

**Read the [1.0.0 wallet section](#wallets-created-with-dart-bitcoinbip39-100) first if you have live user funds.**

---

## Upgrading to 2.0.0 (native crypto backend)

### What changed

| Topic | 1.2.0 | 2.0.0 |
|-------|-------|-------|
| Runtime | Dart VM / Flutter | **Flutter only** (Dart ≥ 3.12) |
| Crypto | `crypto` + `pointycastle` (pure Dart) | **[native_crypto](https://github.com/bulltechnologies/native_crypto)** (OS-backed FFI) |
| Web / Dart-only CLI | Supported | **Unsupported** — fails at build/dependency resolution |
| Seed bytes | PBKDF2 / Argon2id outputs | **Unchanged** (no wallet migration) |
| Public API | Synchronous | **Unchanged** (still synchronous) |

### What you must do

1. **Use Flutter** — add `flutter` SDK dependency; remove Dart-only VM or web targets that cannot load `native_crypto`.
2. **Upgrade SDK** — `environment: sdk: ^3.12.0` and `flutter: ">=3.3.0"`.
3. **Run crypto off the UI isolate** — `mnemonicToSeed`, `generateMnemonic`, and checksum validation call native FFI synchronously. Invoke them from a **persistent background crypto isolate** (see [native_crypto example](https://github.com/bulltechnologies/native_crypto/tree/main/example/lib/crypto_isolate.dart)). The library does not provide an async wrapper.
4. **No seed migration** — existing wallets keep the same seeds when using the same `Bip39SeedOptions` profile (`legacyDefaults`, `defaults`, or `argon2`).

### `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  bip39:
    git:
      url: https://github.com/bulltechnologies/bip39.git
      ref: v2.0.0
```

### Argon2 version constants

`Bip39Argon2Params.version` is still an `int`. Use `Bip39Argon2Version.v13` (0x13) or `Bip39Argon2Version.v10` (0x10) instead of pointycastle `Argon2Parameters` constants.

---

## Version map

| Release | Seed encoding default | KDF default | Mnemonic validation | Runtime |
|---------|----------------------|-------------|---------------------|---------|
| **dart-bitcoin 1.0.x** | Implicit `legacy` (`codeUnits` + UTF-8 salt) | PBKDF2 only | English; no NFKD per-word normalization | Dart VM |
| **bulltechnologies 1.1.0** | Facade: `bip39Compliant`; top-level still `legacy` until 1.2 | PBKDF2 only | NFKD words, 10 languages, typed errors | Dart VM |
| **bulltechnologies 1.2.0** | `bip39Compliant` everywhere | PBKDF2 (BIP39); optional Argon2id | Same as 1.1 + `Bip39SeedOptions.argon2` | Dart VM |
| **bulltechnologies 2.0.0** | `bip39Compliant` everywhere | Native PBKDF2 / Argon2id (same outputs) | Unchanged | **Flutter only** |

**1.2.0+ defaults match the [BIP39 specification](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)** (NFKD + UTF-8 + PBKDF2-HMAC-SHA512, 2048 iterations). They do **not** automatically match every dart-bitcoin 1.0.x deployment.

---

## Wallets created with dart-bitcoin/bip39 1.0.0

### What 1.0.0 actually did

If your app called the top-level API with no extra parameters:

```dart
final seed = mnemonicToSeed(mnemonic, passphrase: passphrase);
```

then seeds were derived as follows:

| Input | 1.0.0 bytes fed to PBKDF2 |
|-------|---------------------------|
| **Password** (mnemonic sentence) | `mnemonic.codeUnits` (UTF-16 code units, not UTF-8) |
| **Salt** | `utf8.encode('mnemonic' + passphrase)` — no NFKD on passphrase |
| **KDF** | PBKDF2-HMAC-SHA512, 2048 iterations, 64-byte output |

In **bulltechnologies 1.2.0**, that exact behavior is named **`Bip39SeedEncoding.legacy`** and exposed as:

```dart
Bip39SeedOptions.legacyDefaults
// equivalent to:
// seedEncoding: Bip39SeedEncoding.legacy, kdf: Bip39Kdf.pbkdf2
```

### When 1.0.0 seeds equal 1.2.0 defaults

For **pure ASCII** mnemonics and **pure ASCII** passphrases, `legacy` and `bip39Compliant` usually produce **identical** PBKDF2 seeds (Trezor English vectors pass on 1.2.0 defaults).

Common cases:

| 1.0.0 wallet input | Expected seed compatibility with 1.2.0 defaults | Notes |
|--------------------|--------------------------------------------------|-------|
| English mnemonic + **no passphrase** | Usually identical | English BIP39 words and empty passphrase encode to the same bytes under legacy and BIP39-compliant encoding. |
| English mnemonic + ASCII passphrase (e.g. `TREZOR`, `my secret 123`) | Usually identical | ASCII survives NFKD normalization unchanged. |
| English mnemonic + Unicode passphrase (e.g. `café`, emoji, CJK) | May differ | BIP39 requires NFKD normalization before UTF-8 encoding; 1.0.0 did not normalize the passphrase salt. |
| Non-English / Unicode mnemonic | May differ | BIP39-compliant derivation normalizes and UTF-8 encodes the mnemonic; 1.0.0 used `String.codeUnits`. |

They **diverge** when:

- The passphrase contains Unicode (e.g. `café`, emoji, CJK).
- The mnemonic string contains non-ASCII characters encoded differently under `codeUnits` vs NFKD+UTF-8.
- You rely on exact `codeUnits` behavior for unusual Unicode in the mnemonic sentence.

**NFKD passphrase normalization** means converting visually equivalent Unicode strings to a canonical decomposed form before deriving the seed. For example, `é` can be represented either as one precomposed code point or as `e` plus a combining accent. BIP39 normalizes the passphrase so those equivalent forms produce the same salt bytes.

**Never assume “ASCII-only users ⇒ safe to switch defaults” without golden tests on real phrases from your database.**

### How to treat existing 1.0.0 wallets (production rule)

| Rule | Rationale |
|------|-----------|
| **Persist how each wallet was derived** | Store `seedDerivationVersion` (or equivalent) at wallet creation time. |
| **Never change derivation silently on unlock** | Changing encoding or KDF changes the seed → different addresses → lost funds appearance. |
| **Use `legacyDefaults` for all 1.0.0 wallets** | Safest default, even when no passphrase was used and seeds would usually match. |
| **Use `defaults` only for new wallets** | After you explicitly choose BIP39-spec derivation for new accounts. |
| **Do not enable Argon2 for existing PBKDF2 wallets** | Argon2 is a different KDF; seeds will never match. |

Recommended persisted metadata (example):

```dart
enum WalletSeedProfile {
  /// dart-bitcoin 1.0.x / this package legacy encoding + PBKDF2
  dartBitcoin10Legacy,

  /// BIP39 spec: NFKD + UTF-8 + PBKDF2 (1.2.0 defaults)
  bip39CompliantPbkdf2,

  /// Optional bulltechnologies extension (1.2.0 opt-in)
  bip39CompliantArgon2id,
}
```

At unlock / sign:

```dart
Bip39SeedOptions seedOptionsFor(WalletSeedProfile profile) => switch (profile) {
  WalletSeedProfile.dartBitcoin10Legacy => Bip39SeedOptions.legacyDefaults,
  WalletSeedProfile.bip39CompliantPbkdf2 => Bip39SeedOptions.defaults,
  WalletSeedProfile.bip39CompliantArgon2id => Bip39SeedOptions.argon2,
};
```

### Compatibility shim (minimal change from 1.0.0)

Centralize seed derivation in one module:

```dart
import 'package:bip39/bip39.dart';

/// Keep this for every wallet created before you intentionally migrated encoding.
const kLegacySeedOptions = Bip39SeedOptions.legacyDefaults;

Uint8List deriveSeedLegacy(String mnemonic, {String passphrase = ''}) {
  return Bip39.mnemonicToSeed(
    mnemonic,
    options: kLegacySeedOptions.copyWith(passphrase: passphrase),
  );
}
```

Top-level equivalent:

```dart
mnemonicToSeed(
  mnemonic,
  passphrase: passphrase,
  seedEncoding: Bip39SeedEncoding.legacy,
);
```

### Verify before you deploy 1.2.0

Add **golden tests** using mnemonics/passphrases from production (testnet keys only, or synthetic copies of real Unicode patterns):

```dart
test('production wallet sample matches legacy 1.0.0 seed', () {
  const mnemonic = '...'; // from support / test vault
  const passphrase = '...';
  const expectedSeedHex = '...'; // captured under dart-bitcoin 1.0.0

  expect(
    Bip39.mnemonicToSeedHex(
      mnemonic,
      options: Bip39SeedOptions.legacyDefaults.copyWith(passphrase: passphrase),
    ),
    expectedSeedHex,
  );
});
```

Run the same mnemonic with `Bip39SeedOptions.defaults`. If hex differs, that wallet **must** stay on `legacyDefaults` (or you need a user-visible migration).

---

## Migrating 1.0.0 wallets to BIP39-compliant seeds

Only attempt this if you **want** spec-aligned derivation (e.g. alignment with Trezor/Ledger import/export for Unicode passphrases) and can handle wallets where seeds change.

### Step 1 — Detect divergence

```dart
bool seedsDiverge(String mnemonic, {String passphrase = ''}) {
  final legacy = Bip39.mnemonicToSeed(
    mnemonic,
    options: Bip39SeedOptions.legacyDefaults.copyWith(passphrase: passphrase),
  );
  final compliant = Bip39.mnemonicToSeed(
    mnemonic,
    options: Bip39SeedOptions.defaults.copyWith(passphrase: passphrase),
  );
  if (legacy.length != compliant.length) return true;
  for (var i = 0; i < legacy.length; i++) {
    if (legacy[i] != compliant[i]) return true;
  }
  return false;
}
```

- If `false`: you may switch stored profile to `bip39CompliantPbkdf2` without changing the seed (common for ASCII-only).
- If `true`: migration changes keys; treat as **new wallet** from a keys perspective unless you implement re-scan / re-import UX.

### Step 2 — User-visible migration (if seeds diverge)

Do **not** auto-migrate in the background. Typical patterns:

1. **Keep legacy profile forever** for old accounts (simplest, safest).
2. **“Upgrade wallet” flow**: user re-enters mnemonic + passphrase; show old vs new first address; require explicit consent; backup reminder.
3. **New account only**: old accounts unchanged; new accounts use `Bip39SeedOptions.defaults`.

### Step 3 — Update stored profile after consent

```dart
await walletStore.updateSeedProfile(
  walletId,
  WalletSeedProfile.bip39CompliantPbkdf2,
);
```

Re-derive seed with `defaults` on every unlock from then on.

---

## Upgrading dependency only (no seed migration)

Suitable when all existing wallets were created with dart-bitcoin 1.0.x and you want **identical** behavior.

### `pubspec.yaml`

```yaml
dependencies:
  bip39:
    git:
      url: https://github.com/bulltechnologies/bip39.git
      ref: v1.2.0
```

### Code changes

1. Replace direct `mnemonicToSeed` calls with `Bip39SeedOptions.legacyDefaults` (or the shim above).
2. Run your full wallet / HD derivation test suite.
3. Ship.

No user action required if golden tests pass.

---

## Migrating from bulltechnologies 1.1.0 → 1.2.0

| Topic | 1.1.0 | 1.2.0 | Action |
|-------|-------|-------|--------|
| Top-level `seedEncoding` | `legacy` | `bip39Compliant` | If you relied on implicit legacy at top level, pass `legacy` or use `legacyDefaults` |
| KDF | PBKDF2 only | PBKDF2 default; optional Argon2 | No change unless you opt in |
| Facade `Bip39SeedOptions.defaults` | Already `bip39Compliant` | Unchanged | Facade-only apps may already be spec-compliant |

**If you already set `seedEncoding` explicitly in 1.1.0, 1.2.0 does not change your seeds.**

---

## Adopting 1.1.0 features (validation, languages, memory)

Safe to adopt without changing seeds **if seed options stay on `legacyDefaults` for old wallets**.

### Validation and import UX

```dart
final result = Bip39.validateMnemonicDetailed(
  userPhrase,
  options: Bip39ValidateOptions(
    language: selectedLanguage,
    normalizeInput: true, // pasted phrases with extra whitespace
  ),
);
```

- **`normalizeWords: true` (default)** — NFC Japanese phrases may validate when 1.0.0 rejected them. This does **not** change seeds; it only affects whether import succeeds.
- Warn users on `Bip39FailureReason.invalidChecksum` (phrase may be wrong language or typo).

### Multi-language wordlists

```dart
Bip39.generateMnemonic(
  options: Bip39MnemonicOptions(language: Bip39Language.spanish),
);
```

English top-level `generateMnemonic()` / `validateMnemonic()` remain for backward compatibility.

### Memory hygiene (recommended)

```dart
final sensitive = Bip39.mnemonicToSeedSensitive(
  mnemonic,
  options: seedOptionsFor(wallet.seedProfile),
);
try {
  await hdWallet.fromSeed(sensitive.bytes);
} finally {
  sensitive.zeroize();
}
```

Mnemonics and passphrases in `String` form cannot be wiped from the Dart heap; avoid logging them.

### CSPRNG fix (1.1.0)

`generateMnemonic()` can now emit byte value `255` in entropy. Only affects **newly generated** mnemonics, not recovery of existing ones.

---

## Adopting 1.2.0 features (BIP39 defaults and Argon2)

### New wallets: BIP39-spec seeds

For **new** accounts (no legacy seed profile):

```dart
final seed = Bip39.mnemonicToSeed(
  mnemonic,
  options: Bip39SeedOptions.defaults, // bip39Compliant + pbkdf2
);
```

Interoperates with standard hardware wallets and BIP39 test vectors.

### New product line: Argon2id (optional)

**Only for new wallet types.** Seeds are incompatible with PBKDF2 and with dart-bitcoin 1.0.0.

```dart
final seed = Bip39.mnemonicToSeed(
  mnemonic,
  options: Bip39SeedOptions.argon2.copyWith(passphrase: passphrase),
);
```

Tune cost for production devices:

```dart
Bip39SeedOptions(
  kdf: Bip39Kdf.argon2id,
  argon2Params: Bip39Argon2Params(
    iterations: 4,
    memoryKiB: 65536,
    parallelism: 4,
  ),
);
```

Profile on minimum-spec hardware; Argon2 can block the UI thread if run synchronously on the main isolate.

---

## API quick reference

| Goal | API |
|------|-----|
| Match **dart-bitcoin 1.0.0** seeds | `Bip39SeedOptions.legacyDefaults` |
| Match **BIP39 spec** / Trezor vectors | `Bip39SeedOptions.defaults` |
| Explicit BIP39 PBKDF2 alias | `Bip39SeedOptions.bip39Standard` (same as `defaults`) |
| Stronger non-standard KDF | `Bip39SeedOptions.argon2` |
| Top-level legacy encoding | `seedEncoding: Bip39SeedEncoding.legacy` |

---

## Pre-release checklist

- [ ] Inventory every `mnemonicToSeed` / `mnemonicToSeedHex` / `mnemonicToSeedSensitive` call site
- [ ] Golden-test 3–5 legacy wallets (ASCII + any Unicode passphrases you support)
- [ ] Confirm HD paths and first address match testnet expectations after upgrade
- [ ] Persist `seedProfile` (or equivalent) per wallet at creation
- [ ] Document in app release notes if import validation became more permissive (1.1+)
- [ ] Never enable Argon2 for existing PBKDF2 wallets without a new wallet version
- [ ] If using Argon2: load-test on target devices; validate web targets separately

---

## Decision flowchart

```
Were seeds created with dart-bitcoin/bip39 1.0.x (implicit legacy encoding)?
│
├─ YES → Use legacyDefaults for those wallets until explicitly migrated
│         │
│         ├─ Need byte-identical seeds forever? → Stay on legacyDefaults
│         │
│         └─ Want BIP39-spec for some users? → Per-wallet profile + detect seedsDiverge()
│
└─ NO (new app or already on bip39Compliant) → Use defaults for new wallets
          │
          └─ Want stronger KDF for NEW product only? → argon2 profile, never mix with PBKDF2
```

---

## Further reading

- [CHANGELOG.md](CHANGELOG.md) — release-by-release changes
- [README.md](README.md) — API overview and configuration table
- [BIP-0039](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki) — normative specification
