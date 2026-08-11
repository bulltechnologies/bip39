import 'dart:convert';
import 'dart:typed_data';

import 'package:unorm_dart/unorm_dart.dart' as unorm;

import 'security/memory.dart';
import 'wordlists/bip39_language.dart';

/// Whether seed derivation uses legacy `String.codeUnits` encoding or full
/// BIP39 NFKD + UTF-8.
enum Bip39SeedEncoding {
  /// Pre-1.1.0 behavior: [String.codeUnits] for mnemonic and UTF-8 salt only.
  ///
  /// Preserved for backward compatibility. Prefer [bip39Compliant] for new work.
  @Deprecated(
    'Use Bip39SeedEncoding.bip39Compliant. Legacy encoding remains available '
    'via explicit opt-in until a future major version.',
  )
  legacy,

  /// BIP39-compliant: NFKD normalize mnemonic and passphrase, then UTF-8 encode.
  bip39Compliant,
}

final RegExp _japaneseStrictSeparator = RegExp(r'[ \u3000]+');
final RegExp _unicodeWhitespace = RegExp(r'\s+');
final RegExp _japaneseUnicodeWhitespace = RegExp(r'[\s\u3000]+');

/// NFKD-normalize [input] per BIP39 (used before UTF-8 encoding for seeds).
String bip39Normalize(String input) => unorm.nfkd(input);

bool _isAscii(String input) {
  for (final unit in input.codeUnits) {
    if (unit > 0x7F) {
      return false;
    }
  }
  return true;
}

/// NFKD-normalize a single mnemonic word before wordlist lookup.
///
/// Official wordlists are stored in NFKD; IMEs often emit NFC. Normalizing
/// words closes that gap without changing ASCII phrases.
String normalizeMnemonicWord(String word) =>
    _isAscii(word) ? word : bip39Normalize(word);

/// Word separator used when encoding mnemonics for [language].
///
/// When [useIdeographicSeparator] is null, Japanese uses U+3000 and all other
/// languages use ASCII space — matching [Bip39CodecOptions.useIdeographicSeparator]
/// defaults.
String mnemonicWordSeparator(
  Bip39Language language, {
  bool? useIdeographicSeparator,
}) {
  final ideographic =
      useIdeographicSeparator ?? language.supportsIdeographicSpace;
  if (ideographic && language.supportsIdeographicSpace) {
    return '\u3000';
  }
  return ' ';
}

/// Returns a canonical mnemonic string for [language] without validating checksum.
///
/// Applies the same splitting and NFKD word normalization used by parsers when
/// [normalizeInput] / [normalizeWords] are enabled, then rejoins with the
/// language-appropriate separator. Seed APIs hash the original [mnemonic]
/// string; call this explicitly before [mnemonicToSeed] when you need the
/// canonical form to match validation input.
String canonicalizeMnemonic(
  String mnemonic, {
  bool normalizeInput = false,
  bool normalizeWords = true,
  Bip39Language language = Bip39Language.english,
  bool useIdeographicSeparator = true,
}) {
  final words = splitMnemonicWords(
    mnemonic,
    normalizeInput: normalizeInput,
    normalizeWords: normalizeWords,
    language: language,
  );
  return words.join(
    mnemonicWordSeparator(
      language,
      useIdeographicSeparator: useIdeographicSeparator,
    ),
  );
}

/// Encode [input] for KDF password bytes per [encoding].
///
/// Caller should [zeroizeBytes] the returned buffer when done (see [Bip39.mnemonicToSeed]).
Uint8List encodeMnemonicForSeed(String input, Bip39SeedEncoding encoding) {
  switch (encoding) {
    case Bip39SeedEncoding.legacy:
      return Uint8List.fromList(input.codeUnits);
    case Bip39SeedEncoding.bip39Compliant:
      return utf8.encode(bip39Normalize(input));
  }
}

/// Encode salt (`mnemonic` + passphrase) per [encoding].
///
/// Caller should [zeroizeBytes] the returned buffer when done.
Uint8List encodeSaltForSeed(String passphrase, Bip39SeedEncoding encoding) {
  const prefix = 'mnemonic';
  switch (encoding) {
    case Bip39SeedEncoding.legacy:
      return utf8.encode(prefix + passphrase);
    case Bip39SeedEncoding.bip39Compliant:
      return utf8.encode(bip39Normalize(prefix + passphrase));
  }
}

/// Splits a mnemonic phrase into words.
///
/// When [normalizeInput] is false, splits on ASCII space only (legacy behavior),
/// except [Bip39Language.japanese] also splits on U+3000.
/// When [normalizeInput] is true, trims and splits on Unicode whitespace.
///
/// When [normalizeWords] is true, each token is NFKD-normalized per BIP39
/// wordlist form before lookup.
List<String> splitMnemonicWords(
  String mnemonic, {
  bool normalizeInput = false,
  bool normalizeWords = true,
  Bip39Language language = Bip39Language.english,
}) {
  final List<String> raw;
  if (!normalizeInput) {
    if (language.supportsIdeographicSpace) {
      raw = mnemonic.split(_japaneseStrictSeparator);
    } else {
      raw = mnemonic.split(' ');
    }
  } else {
    final trimmed = mnemonic.trim();
    if (trimmed.isEmpty) {
      return <String>[];
    }
    final pattern = language.supportsIdeographicSpace
        ? _japaneseUnicodeWhitespace
        : _unicodeWhitespace;
    raw = trimmed.split(pattern);
  }

  if (!normalizeWords) {
    return raw;
  }
  return raw.map(normalizeMnemonicWord).toList(growable: false);
}
