import 'dart:typed_data';

import 'bip39_encoding.dart';
import 'wordlists/bip39_language.dart';

/// Configuration for mnemonic generation ([generateMnemonic]).
final class Bip39MnemonicOptions {
  const Bip39MnemonicOptions({
    this.language = Bip39Language.english,
    this.strength = 128,
    this.normalizeInput = false,
    this.normalizeWords = true,
    this.useIdeographicSeparator = true,
    this.randomBytes,
  });

  /// Defaults: English, 128-bit entropy, NFKD word normalization.
  static const Bip39MnemonicOptions defaults = Bip39MnemonicOptions();

  /// Wordlist language for generated or parsed mnemonics.
  final Bip39Language language;

  /// Entropy size in bits (128, 160, 192, 224, or 256).
  final int strength;

  /// When true, trims the phrase and splits on Unicode whitespace (and
  /// ideographic space for [Bip39Language.japanese]).
  final bool normalizeInput;

  /// NFKD-normalize each word before wordlist lookup (BIP39 wordlist form).
  final bool normalizeWords;

  /// When true and [language] is Japanese, encoded mnemonics use U+3000 between words.
  final bool useIdeographicSeparator;

  /// Optional CSPRNG override for tests or custom entropy sources.
  final RandomBytes? randomBytes;

  /// Entropy/codec options derived from this configuration.
  Bip39EntropyOptions get entropyOptions => Bip39EntropyOptions(
        language: language,
        normalizeInput: normalizeInput,
        normalizeWords: normalizeWords,
        useIdeographicSeparator: useIdeographicSeparator,
      );

  Bip39MnemonicOptions copyWith({
    Bip39Language? language,
    int? strength,
    bool? normalizeInput,
    bool? normalizeWords,
    bool? useIdeographicSeparator,
    RandomBytes? randomBytes,
  }) =>
      Bip39MnemonicOptions(
        language: language ?? this.language,
        strength: strength ?? this.strength,
        normalizeInput: normalizeInput ?? this.normalizeInput,
        normalizeWords: normalizeWords ?? this.normalizeWords,
        useIdeographicSeparator:
            useIdeographicSeparator ?? this.useIdeographicSeparator,
        randomBytes: randomBytes ?? this.randomBytes,
      );
}

/// Configuration for mnemonic parsing and validation.
final class Bip39ValidateOptions {
  const Bip39ValidateOptions({
    this.language = Bip39Language.english,
    this.normalizeInput = false,
    this.normalizeWords = true,
  });

  static const Bip39ValidateOptions defaults = Bip39ValidateOptions();

  final Bip39Language language;
  final bool normalizeInput;

  /// NFKD-normalize each word before wordlist lookup.
  final bool normalizeWords;

  Bip39EntropyOptions get entropyOptions => Bip39EntropyOptions(
        language: language,
        normalizeInput: normalizeInput,
        normalizeWords: normalizeWords,
      );

  Bip39ValidateOptions copyWith({
    Bip39Language? language,
    bool? normalizeInput,
    bool? normalizeWords,
  }) =>
      Bip39ValidateOptions(
        language: language ?? this.language,
        normalizeInput: normalizeInput ?? this.normalizeInput,
        normalizeWords: normalizeWords ?? this.normalizeWords,
      );
}

/// Configuration for PBKDF2 seed derivation ([mnemonicToSeed]).
final class Bip39SeedOptions {
  const Bip39SeedOptions({
    this.passphrase = '',
    this.seedEncoding = Bip39SeedEncoding.bip39Compliant,
    this.zeroizeIntermediateBuffers = true,
  });

  /// BIP39-spec seed encoding (NFKD + UTF-8).
  static const Bip39SeedOptions defaults = Bip39SeedOptions();

  /// Trezor / pre-1.1.0 ASCII-oriented encoding for migration tests.
  static const Bip39SeedOptions legacyDefaults = Bip39SeedOptions(
    seedEncoding: Bip39SeedEncoding.legacy,
  );

  /// Optional BIP39 passphrase (often called the "25th word").
  final String passphrase;

  /// Byte encoding for PBKDF2 password and salt.
  final Bip39SeedEncoding seedEncoding;

  /// When true, PBKDF2 password and salt [Uint8List] buffers are zeroed after use.
  ///
  /// The returned seed is never auto-zeroized; use [SensitiveBytes] or [zeroizeBytes].
  final bool zeroizeIntermediateBuffers;

  Bip39SeedOptions copyWith({
    String? passphrase,
    Bip39SeedEncoding? seedEncoding,
    bool? zeroizeIntermediateBuffers,
  }) =>
      Bip39SeedOptions(
        passphrase: passphrase ?? this.passphrase,
        seedEncoding: seedEncoding ?? this.seedEncoding,
        zeroizeIntermediateBuffers:
            zeroizeIntermediateBuffers ?? this.zeroizeIntermediateBuffers,
      );
}

/// Configuration for entropy ↔ mnemonic conversion.
final class Bip39EntropyOptions {
  const Bip39EntropyOptions({
    this.language = Bip39Language.english,
    this.normalizeInput = false,
    this.normalizeWords = true,
    this.useIdeographicSeparator = true,
  });

  static const Bip39EntropyOptions defaults = Bip39EntropyOptions();

  final Bip39Language language;
  final bool normalizeInput;

  /// NFKD-normalize each word before wordlist lookup.
  final bool normalizeWords;

  /// Use U+3000 between words when encoding Japanese mnemonics.
  final bool useIdeographicSeparator;

  Bip39EntropyOptions copyWith({
    Bip39Language? language,
    bool? normalizeInput,
    bool? normalizeWords,
    bool? useIdeographicSeparator,
  }) =>
      Bip39EntropyOptions(
        language: language ?? this.language,
        normalizeInput: normalizeInput ?? this.normalizeInput,
        normalizeWords: normalizeWords ?? this.normalizeWords,
        useIdeographicSeparator:
            useIdeographicSeparator ?? this.useIdeographicSeparator,
      );
}

/// Generates cryptographically secure random bytes.
typedef RandomBytes = Uint8List Function(int size);
