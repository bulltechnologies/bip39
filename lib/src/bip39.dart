import 'dart:typed_data';

import 'package:native_crypto/native_crypto.dart' show SecureRandom;

import 'bip39_constants.dart' as constants;
import 'bip39_encoding.dart';
import 'bip39_encoding.dart' as encoding;
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

// English wordlist: [englishWords] and legacy [WORDLIST] alias.
export 'wordlists/english.dart' show WORDLIST, englishWords;

// Direct access to generated word arrays per language (except English above).
export 'wordlists/generated/chinese_simplified.dart' show chineseSimplifiedWords;
export 'wordlists/generated/chinese_traditional.dart' show chineseTraditionalWords;
export 'wordlists/generated/czech.dart' show czechWords;
export 'wordlists/generated/french.dart' show frenchWords;
export 'wordlists/generated/italian.dart' show italianWords;
export 'wordlists/generated/japanese.dart' show japaneseWords;
export 'wordlists/generated/korean.dart' show koreanWords;
export 'wordlists/generated/portuguese.dart' show portugueseWords;
export 'wordlists/generated/spanish.dart' show spanishWords;

final SecureRandom _defaultSecureRandom = SecureRandom();

Uint8List _defaultRandomBytes(int size) {
  final bytes = Uint8List(size);
  _defaultSecureRandom.fill(bytes);
  return bytes;
}

/// High-level BIP39 entry point with explicit wordlist and option objects.
///
/// Top-level functions ([generateMnemonic], [mnemonicToSeed], …) delegate here
/// with English defaults for backward compatibility.
///
/// Native cryptography must run on a dedicated background isolate (see
/// [native_crypto](https://github.com/bulltechnologies/native_crypto)); this
/// library does not provide an async wrapper or short-lived [Isolate.run]
/// helper that would copy secrets into ephemeral isolate heaps.
abstract final class Bip39 {
  /// All supported [Bip39Language] values.
  static List<Bip39Language> get languages => Bip39Wordlists.languages;

  /// Official wordlist for [language] (2048 words, indexed).
  static Bip39Wordlist wordlist(Bip39Language language) =>
      Bip39Wordlists.forLanguage(language);

  /// English wordlist.
  static Bip39Wordlist get englishWordlist => Bip39Wordlists.english;

  /// Mnemonic codec for [language] (cached per language).
  static final Map<Bip39Language, MnemonicCodec> _codecs = {};

  static MnemonicCodec codec(Bip39Language language) =>
      _codecs.putIfAbsent(
        language,
        () => MnemonicCodec.forLanguage(language),
      );

  static Bip39Language _entropyLanguage(Bip39EntropyOptions options) =>
      options.language ?? Bip39Language.english;

  static void _assertEntropyLanguage(
    Bip39Language codecLanguage,
    Bip39EntropyOptions options,
  ) {
    final language = options.language;
    if (language != null && language != codecLanguage) {
      throw ArgumentError.value(
        language,
        'language',
        'Codec is bound to ${codecLanguage.fileName}',
      );
    }
  }

  /// Generates a mnemonic using [options].
  ///
  /// [options.randomBytes] must return exactly `strength ~/ 8` bytes. The
  /// library copies that buffer before zeroizing it; caller-owned views are
  /// not modified.
  static String generateMnemonic({
    Bip39MnemonicOptions options = Bip39MnemonicOptions.defaults,
  }) {
    MnemonicCodec.validateStrength(options.strength);
    final expectedLength = options.strength ~/ 8;
    final random = options.randomBytes ?? _defaultRandomBytes;
    final raw = random(expectedLength);
    if (raw.length != expectedLength) {
      throw ArgumentError.value(
        raw.length,
        'randomBytes',
        'Expected $expectedLength bytes for strength ${options.strength}',
      );
    }
    final entropy = Uint8List.fromList(raw);
    try {
      return codec(options.language).entropyToMnemonicFromBytes(
        entropy,
        options: options.codecOptions,
      );
    } finally {
      zeroizeBytes(entropy);
    }
  }

  /// Entropy hex → mnemonic.
  static String entropyToMnemonic(
    String entropyHex, {
    Bip39EntropyOptions options = Bip39EntropyOptions.defaults,
  }) {
    final language = _entropyLanguage(options);
    _assertEntropyLanguage(language, options);
    return codec(language).entropyToMnemonic(
      entropyHex,
      options: options.codecOptions,
    );
  }

  static String entropyToMnemonicFromBytes(
    Uint8List entropy, {
    Bip39EntropyOptions options = Bip39EntropyOptions.defaults,
  }) {
    final language = _entropyLanguage(options);
    _assertEntropyLanguage(language, options);
    return codec(language).entropyToMnemonicFromBytes(
      entropy,
      options: options.codecOptions,
    );
  }

  static String mnemonicToEntropy(
    String mnemonic, {
    Bip39EntropyOptions options = Bip39EntropyOptions.defaults,
  }) {
    final language = _entropyLanguage(options);
    _assertEntropyLanguage(language, options);
    return codec(language).mnemonicToEntropy(
      mnemonic,
      options: options.codecOptions,
    );
  }

  /// Mnemonic → raw entropy bytes (checksum verified).
  ///
  /// Returns a copy; call [zeroizeBytes] when finished.
  static Uint8List mnemonicToEntropyBytes(
    String mnemonic, {
    Bip39EntropyOptions options = Bip39EntropyOptions.defaults,
  }) {
    final language = _entropyLanguage(options);
    _assertEntropyLanguage(language, options);
    return codec(language).mnemonicToEntropyBytes(
      mnemonic,
      options: options.codecOptions,
    );
  }

  /// Parses [mnemonic] without throwing or hex conversion.
  static MnemonicDecodeResult tryDecodeMnemonic(
    String mnemonic, {
    Bip39EntropyOptions options = Bip39EntropyOptions.defaults,
  }) {
    final language = _entropyLanguage(options);
    _assertEntropyLanguage(language, options);
    return codec(language).tryDecodeMnemonic(
      mnemonic,
      options: options.codecOptions,
    );
  }

  static bool validateMnemonic(
    String mnemonic, {
    Bip39ValidateOptions options = Bip39ValidateOptions.defaults,
  }) =>
      codec(options.language).validateMnemonic(
        mnemonic,
        options: options.codecOptions,
      );

  static MnemonicValidationResult validateMnemonicDetailed(
    String mnemonic, {
    Bip39ValidateOptions options = Bip39ValidateOptions.defaults,
  }) =>
      codec(options.language).validateMnemonicDetailed(
        mnemonic,
        options: options.codecOptions,
      );

  /// Returns a canonical mnemonic for [options.language] without validating checksum.
  ///
  /// See [canonicalizeMnemonic].
  static String canonicalizeMnemonic(
    String mnemonic, {
    Bip39CodecOptions options = Bip39CodecOptions.defaults,
    Bip39Language language = Bip39Language.english,
  }) =>
      encoding.canonicalizeMnemonic(
        mnemonic,
        normalizeInput: options.normalizeInput,
        normalizeWords: options.normalizeWords,
        language: language,
        useIdeographicSeparator: options.useIdeographicSeparator,
      );

  /// BIP39 mnemonic word count for [strength] bits.
  static int wordCountForStrength(int strength) =>
      constants.wordCountForStrength(strength);

  /// BIP39 entropy strength in bits for [wordCount] words.
  static int strengthForWordCount(int wordCount) =>
      constants.strengthForWordCount(wordCount);

  /// 64-byte seed via [Bip39SeedOptions.kdf] (BIP39 PBKDF2 by default).
  ///
  /// Default [Bip39Kdf.pbkdf2] always returns **64 bytes**. Optional
  /// [Bip39Kdf.argon2id] uses [Bip39SeedOptions.derivedSeedLength]
  /// ([Bip39Argon2Params.desiredKeyLength], default 64).
  ///
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
  }) {
    final seed = _deriveSeedBytes(mnemonic, options: options);
    try {
      return constants.encodeBytesHex(seed);
    } finally {
      zeroizeBytes(seed);
    }
  }

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
  bool useIdeographicSeparator = true,
}) =>
    Bip39.generateMnemonic(
      options: Bip39MnemonicOptions(
        strength: strength,
        randomBytes: randomBytes,
        language: language,
        useIdeographicSeparator: useIdeographicSeparator,
      ),
    );

/// See [Bip39.entropyToMnemonic].
String entropyToMnemonic(
  String entropyString, {
  Bip39Language language = Bip39Language.english,
  bool useIdeographicSeparator = true,
}) =>
    Bip39.entropyToMnemonic(
      entropyString,
      options: Bip39EntropyOptions(
        language: language,
        useIdeographicSeparator: useIdeographicSeparator,
      ),
    );

/// See [Bip39.entropyToMnemonicFromBytes].
String entropyToMnemonicFromBytes(
  Uint8List entropy, {
  Bip39Language language = Bip39Language.english,
  bool useIdeographicSeparator = true,
}) =>
    Bip39.entropyToMnemonicFromBytes(
      entropy,
      options: Bip39EntropyOptions(
        language: language,
        useIdeographicSeparator: useIdeographicSeparator,
      ),
    );

/// See [Bip39.mnemonicToSeed].
///
/// Defaults to [Bip39SeedEncoding.bip39Compliant] and [Bip39Kdf.pbkdf2] per BIP39.
/// Returns **64 bytes** unless [kdf] is [Bip39Kdf.argon2id] with a custom
/// [Bip39Argon2Params.desiredKeyLength].
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
  bool normalizeWords = true,
  Bip39Language language = Bip39Language.english,
}) =>
    Bip39.validateMnemonic(
      mnemonic,
      options: Bip39ValidateOptions(
        language: language,
        normalizeInput: normalizeInput,
        normalizeWords: normalizeWords,
      ),
    );

/// See [Bip39.validateMnemonicDetailed].
MnemonicValidationResult validateMnemonicDetailed(
  String mnemonic, {
  bool normalizeInput = false,
  bool normalizeWords = true,
  Bip39Language language = Bip39Language.english,
}) =>
    Bip39.validateMnemonicDetailed(
      mnemonic,
      options: Bip39ValidateOptions(
        language: language,
        normalizeInput: normalizeInput,
        normalizeWords: normalizeWords,
      ),
    );

/// See [Bip39.mnemonicToEntropy].
String mnemonicToEntropy(
  String mnemonic, {
  bool normalizeInput = false,
  bool normalizeWords = true,
  Bip39Language language = Bip39Language.english,
}) =>
    Bip39.mnemonicToEntropy(
      mnemonic,
      options: Bip39EntropyOptions(
        language: language,
        normalizeInput: normalizeInput,
        normalizeWords: normalizeWords,
      ),
    );

/// See [Bip39.mnemonicToEntropyBytes].
Uint8List mnemonicToEntropyBytes(
  String mnemonic, {
  bool normalizeInput = false,
  bool normalizeWords = true,
  Bip39Language language = Bip39Language.english,
}) =>
    Bip39.mnemonicToEntropyBytes(
      mnemonic,
      options: Bip39EntropyOptions(
        language: language,
        normalizeInput: normalizeInput,
        normalizeWords: normalizeWords,
      ),
    );

/// See [Bip39.tryDecodeMnemonic].
MnemonicDecodeResult tryDecodeMnemonic(
  String mnemonic, {
  bool normalizeInput = false,
  bool normalizeWords = true,
  Bip39Language language = Bip39Language.english,
}) =>
    Bip39.tryDecodeMnemonic(
      mnemonic,
      options: Bip39EntropyOptions(
        language: language,
        normalizeInput: normalizeInput,
        normalizeWords: normalizeWords,
      ),
    );

/// See [Bip39.wordCountForStrength].
int wordCountForStrength(int strength) => Bip39.wordCountForStrength(strength);

/// See [Bip39.strengthForWordCount].
int strengthForWordCount(int wordCount) => Bip39.strengthForWordCount(wordCount);
