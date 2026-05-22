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

/// NFKD-normalize [input] per BIP39 (used before UTF-8 encoding for seeds).
String bip39Normalize(String input) => unorm.nfkd(input);

/// NFKD-normalize a single mnemonic word before wordlist lookup.
///
/// Official wordlists are stored in NFKD; IMEs often emit NFC. Normalizing
/// words closes that gap without changing ASCII phrases.
String normalizeMnemonicWord(String word) => bip39Normalize(word);

/// Word separator used when encoding mnemonics for [language].
String mnemonicWordSeparator(
  Bip39Language language, {
  bool useIdeographicSeparator = false,
}) {
  if (useIdeographicSeparator && language.supportsIdeographicSpace) {
    return '\u3000';
  }
  return ' ';
}

/// Encode [input] for KDF password bytes per [encoding].
///
/// Caller should [zeroizeBytes] the returned buffer when done (see [Bip39.mnemonicToSeed]).
Uint8List encodeMnemonicForSeed(String input, Bip39SeedEncoding encoding) {
  switch (encoding) {
    case Bip39SeedEncoding.legacy:
      return Uint8List.fromList(input.codeUnits);
    case Bip39SeedEncoding.bip39Compliant:
      return Uint8List.fromList(utf8.encode(bip39Normalize(input)));
  }
}

/// Encode salt (`mnemonic` + passphrase) per [encoding].
///
/// Caller should [zeroizeBytes] the returned buffer when done.
Uint8List encodeSaltForSeed(String passphrase, Bip39SeedEncoding encoding) {
  const prefix = 'mnemonic';
  switch (encoding) {
    case Bip39SeedEncoding.legacy:
      return Uint8List.fromList(utf8.encode(prefix + passphrase));
    case Bip39SeedEncoding.bip39Compliant:
      return Uint8List.fromList(
        utf8.encode(bip39Normalize(prefix + passphrase)),
      );
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
      raw = mnemonic
          .split(RegExp(r'[\s\u3000]+'))
          .where((word) => word.isNotEmpty)
          .toList(growable: false);
    } else {
      raw = mnemonic.split(' ');
    }
  } else {
    final trimmed = mnemonic.trim();
    if (trimmed.isEmpty) {
      return <String>[];
    }
    final pattern = language.supportsIdeographicSpace
        ? RegExp(r'[\s\u3000]+')
        : RegExp(r'\s+');
    raw = trimmed.split(pattern);
  }

  if (!normalizeWords) {
    return raw;
  }
  return raw.map(normalizeMnemonicWord).toList(growable: false);
}
