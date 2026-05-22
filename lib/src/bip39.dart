import 'dart:math';
import 'dart:typed_data';

import 'bip39_encoding.dart';
import 'bip39_exceptions.dart';
import 'bip39_options.dart';
import 'core/mnemonic_codec.dart';
import 'security/memory.dart';
import 'bip39_kdf.dart';
import 'utils/argon2.dart';
import 'utils/pbkdf2.dart';
import 'wordlists/bip39_language.dart';
import 'wordlists/bip39_wordlist.dart';
import 'wordlists/bip39_wordlists.dart';

export 'bip39_constants.dart';
export 'bip39_encoding.dart';
export 'bip39_exceptions.dart';
export 'bip39_kdf.dart';
export 'bip39_options.dart';
export 'core/mnemonic_codec.dart';
export 'security/memory.dart';
export 'utils/entropy_hex.dart';
export 'wordlists/bip39_language.dart';
export 'wordlists/bip39_wordlist.dart';
export 'wordlists/bip39_wordlists.dart';

// Backward-compatible English wordlist export.
export 'wordlists/english.dart' show WORDLIST, englishWords;

// Direct access to generated word arrays per language.
export 'wordlists/generated/chinese_simplified.dart' show chineseSimplifiedWords;
export 'wordlists/generated/chinese_traditional.dart' show chineseTraditionalWords;
export 'wordlists/generated/czech.dart' show czechWords;
export 'wordlists/generated/english.dart' show englishWords;
export 'wordlists/generated/french.dart' show frenchWords;
export 'wordlists/generated/italian.dart' show italianWords;
export 'wordlists/generated/japanese.dart' show japaneseWords;
export 'wordlists/generated/korean.dart' show koreanWords;
export 'wordlists/generated/portuguese.dart' show portugueseWords;
export 'wordlists/generated/spanish.dart' show spanishWords;

Uint8List _defaultRandomBytes(int size) {
  final rng = Random.secure();
  final bytes = Uint8List(size);
  for (var i = 0; i < size; i++) {
    bytes[i] = rng.nextInt(256);
  }
  return bytes;
}

/// High-level BIP39 entry point with explicit wordlist and option objects.
///
/// Top-level functions ([generateMnemonic], [mnemonicToSeed], …) delegate here
/// with English defaults for backward compatibility.
abstract final class Bip39 {
  /// All supported [Bip39Language] values.
  static List<Bip39Language> get languages => Bip39Wordlists.languages;

  /// Official wordlist for [language] (2048 words, indexed).
  static Bip39Wordlist wordlist(Bip39Language language) =>
      Bip39Wordlists.forLanguage(language);

  /// English wordlist.
  static Bip39Wordlist get englishWordlist => Bip39Wordlists.english;

  /// Mnemonic codec for [language].
  static MnemonicCodec codec(Bip39Language language) =>
      MnemonicCodec.forLanguage(language);

  /// Generates a mnemonic using [options].
  static String generateMnemonic({
    Bip39MnemonicOptions options = Bip39MnemonicOptions.defaults,
  }) {
    MnemonicCodec.validateStrength(options.strength);
    final random = options.randomBytes ?? _defaultRandomBytes;
    final entropy = random(options.strength ~/ 8);
    try {
      return codec(options.language).entropyToMnemonicFromBytes(
        entropy,
        options: options.entropyOptions,
      );
    } finally {
      zeroizeBytes(entropy);
    }
  }

  /// Entropy hex → mnemonic.
  static String entropyToMnemonic(
    String entropyHex, {
    Bip39EntropyOptions options = Bip39EntropyOptions.defaults,
  }) =>
      codec(options.language).entropyToMnemonic(entropyHex, options: options);

  static String entropyToMnemonicFromBytes(
    Uint8List entropy, {
    Bip39EntropyOptions options = Bip39EntropyOptions.defaults,
  }) =>
      codec(options.language)
          .entropyToMnemonicFromBytes(entropy, options: options);

  static String mnemonicToEntropy(
    String mnemonic, {
    Bip39EntropyOptions options = Bip39EntropyOptions.defaults,
  }) =>
      codec(options.language).mnemonicToEntropy(mnemonic, options: options);

  static bool validateMnemonic(
    String mnemonic, {
    Bip39ValidateOptions options = Bip39ValidateOptions.defaults,
  }) =>
      codec(options.language).validateMnemonic(mnemonic, options: options);

  static MnemonicValidationResult validateMnemonicDetailed(
    String mnemonic, {
    Bip39ValidateOptions options = Bip39ValidateOptions.defaults,
  }) =>
      codec(options.language)
          .validateMnemonicDetailed(mnemonic, options: options);

  /// 64-byte seed via [Bip39SeedOptions.kdf] (BIP39 PBKDF2 by default).
  ///
  /// Use [Bip39SeedOptions.argon2] for optional Argon2id.
  /// The returned [Uint8List] is a copy; call [zeroizeBytes] when finished, or
  /// use [mnemonicToSeedSensitive] for explicit lifecycle control.
  static Uint8List mnemonicToSeed(
    String mnemonic, {
    Bip39SeedOptions options = Bip39SeedOptions.defaults,
  }) =>
      Uint8List.fromList(
        _deriveSeedBytes(mnemonic, options: options),
      );

  /// Same as [mnemonicToSeed] but returns a [SensitiveBytes] wrapper.
  static SensitiveBytes mnemonicToSeedSensitive(
    String mnemonic, {
    Bip39SeedOptions options = Bip39SeedOptions.defaults,
  }) =>
      SensitiveBytes(_deriveSeedBytes(mnemonic, options: options), copy: false);

  static String mnemonicToSeedHex(
    String mnemonic, {
    Bip39SeedOptions options = Bip39SeedOptions.defaults,
  }) =>
      mnemonicToSeed(mnemonic, options: options)
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();

  static Uint8List _deriveSeedBytes(
    String mnemonic, {
    required Bip39SeedOptions options,
  }) {
    final password = encodeMnemonicForSeed(mnemonic, options.seedEncoding);
    final salt = encodeSaltForSeed(options.passphrase, options.seedEncoding);
    try {
      return switch (options.kdf) {
        Bip39Kdf.pbkdf2 => PBKDF2.instance.processBytes(password, salt),
        Bip39Kdf.argon2id => Argon2.instance.processBytes(
            password,
            salt,
            params: options.argon2Params,
          ),
      };
    } finally {
      if (options.zeroizeIntermediateBuffers) {
        zeroizeBytes(password);
        zeroizeBytes(salt);
      }
    }
  }
}

// --- Backward-compatible top-level API (English defaults) ---

/// See [Bip39.generateMnemonic].
String generateMnemonic({
  int strength = 128,
  RandomBytes randomBytes = _defaultRandomBytes,
  Bip39Language language = Bip39Language.english,
}) =>
    Bip39.generateMnemonic(
      options: Bip39MnemonicOptions(
        strength: strength,
        randomBytes: randomBytes,
        language: language,
      ),
    );

/// See [Bip39.entropyToMnemonic].
String entropyToMnemonic(
  String entropyString, {
  Bip39Language language = Bip39Language.english,
}) =>
    Bip39.entropyToMnemonic(
      entropyString,
      options: Bip39EntropyOptions(language: language),
    );

/// See [Bip39.entropyToMnemonicFromBytes].
String entropyToMnemonicFromBytes(
  Uint8List entropy, {
  Bip39Language language = Bip39Language.english,
}) =>
    Bip39.entropyToMnemonicFromBytes(
      entropy,
      options: Bip39EntropyOptions(language: language),
    );

/// See [Bip39.mnemonicToSeed].
///
/// Defaults to [Bip39SeedEncoding.bip39Compliant] and [Bip39Kdf.pbkdf2] per BIP39.
Uint8List mnemonicToSeed(
  String mnemonic, {
  String passphrase = '',
  Bip39SeedEncoding seedEncoding = Bip39SeedEncoding.bip39Compliant,
  Bip39Kdf kdf = Bip39Kdf.pbkdf2,
  Bip39Argon2Params argon2Params = Bip39Argon2Params.defaults,
}) =>
    Bip39.mnemonicToSeed(
      mnemonic,
      options: Bip39SeedOptions(
        passphrase: passphrase,
        seedEncoding: seedEncoding,
        kdf: kdf,
        argon2Params: argon2Params,
        zeroizeIntermediateBuffers: true,
      ),
    );

/// See [Bip39.mnemonicToSeedSensitive].
SensitiveBytes mnemonicToSeedSensitive(
  String mnemonic, {
  String passphrase = '',
  Bip39SeedEncoding seedEncoding = Bip39SeedEncoding.bip39Compliant,
  Bip39Kdf kdf = Bip39Kdf.pbkdf2,
  Bip39Argon2Params argon2Params = Bip39Argon2Params.defaults,
}) =>
    Bip39.mnemonicToSeedSensitive(
      mnemonic,
      options: Bip39SeedOptions(
        passphrase: passphrase,
        seedEncoding: seedEncoding,
        kdf: kdf,
        argon2Params: argon2Params,
      ),
    );

/// See [Bip39.mnemonicToSeedHex].
String mnemonicToSeedHex(
  String mnemonic, {
  String passphrase = '',
  Bip39SeedEncoding seedEncoding = Bip39SeedEncoding.bip39Compliant,
  Bip39Kdf kdf = Bip39Kdf.pbkdf2,
  Bip39Argon2Params argon2Params = Bip39Argon2Params.defaults,
}) =>
    Bip39.mnemonicToSeedHex(
      mnemonic,
      options: Bip39SeedOptions(
        passphrase: passphrase,
        seedEncoding: seedEncoding,
        kdf: kdf,
        argon2Params: argon2Params,
      ),
    );

/// See [Bip39.validateMnemonic].
bool validateMnemonic(
  String mnemonic, {
  bool normalizeInput = false,
  Bip39Language language = Bip39Language.english,
}) =>
    Bip39.validateMnemonic(
      mnemonic,
      options: Bip39ValidateOptions(
        language: language,
        normalizeInput: normalizeInput,
      ),
    );

/// See [Bip39.validateMnemonicDetailed].
MnemonicValidationResult validateMnemonicDetailed(
  String mnemonic, {
  bool normalizeInput = false,
  Bip39Language language = Bip39Language.english,
}) =>
    Bip39.validateMnemonicDetailed(
      mnemonic,
      options: Bip39ValidateOptions(
        language: language,
        normalizeInput: normalizeInput,
      ),
    );

/// See [Bip39.mnemonicToEntropy].
String mnemonicToEntropy(
  String mnemonic, {
  bool normalizeInput = false,
  Bip39Language language = Bip39Language.english,
}) =>
    Bip39.mnemonicToEntropy(
      mnemonic,
      options: Bip39EntropyOptions(
        language: language,
        normalizeInput: normalizeInput,
      ),
    );
