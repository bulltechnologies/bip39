import 'dart:typed_data';

import 'package:native_crypto/native_crypto.dart' show Sha256;

import '../bip39_constants.dart';
import '../bip39_encoding.dart';
import '../bip39_exceptions.dart';
import '../bip39_options.dart';
import '../security/memory.dart';
import '../utils/entropy_hex.dart';
import '../wordlists/bip39_language.dart';
import '../wordlists/bip39_wordlist.dart';
import '../wordlists/bip39_wordlists.dart';

/// Pure BIP39 mnemonic encode/decode using a specific [Bip39Wordlist].
final class MnemonicCodec {
  /// Codec using the English wordlist.
  static final MnemonicCodec english =
      MnemonicCodec(Bip39Wordlists.english);

  MnemonicCodec(this.wordlist);

  final Bip39Wordlist wordlist;

  /// Builds a codec for [language].
  factory MnemonicCodec.forLanguage(Bip39Language language) =>
      MnemonicCodec(Bip39Wordlists.forLanguage(language));

  static final Sha256 _sha256 = Sha256();

  static const int _indexMask = (1 << Bip39Wordlist.bitsPerWord) - 1;

  static int _checksumBitCount(int entropyByteLength) =>
      entropyByteLength * 8 ~/ 32;

  static int _deriveChecksumValue(Uint8List entropy) {
    final cs = _checksumBitCount(entropy.length);
    final hashBytes = _sha256.hash(entropy);
    try {
      return hashBytes[0] >> (8 - cs);
    } finally {
      zeroizeBytes(hashBytes);
    }
  }

  static void validateEntropyBytes(Uint8List entropy) {
    if (entropy.length < 16 ||
        entropy.length > 32 ||
        entropy.length % 4 != 0) {
      throw Bip39InvalidEntropyException(invalidEntropyMessage);
    }
  }

  static void validateStrength(int strength) {
    if (!allowedMnemonicStrengths.contains(strength)) {
      throw Bip39InvalidStrengthException(
        'strength must be one of $allowedMnemonicStrengths (got $strength)',
        strength,
      );
    }
  }

  /// Hex entropy string → mnemonic in [wordlist.language].
  String entropyToMnemonic(
    String entropyHex, {
    Bip39CodecOptions options = Bip39CodecOptions.defaults,
  }) {
    final entropy = decodeEntropyHex(entropyHex);
    try {
      return entropyToMnemonicFromBytes(entropy, options: options);
    } finally {
      zeroizeBytes(entropy);
    }
  }

  /// Raw entropy bytes → mnemonic.
  ///
  /// Does not modify [entropy]; callers holding secrets should [zeroizeBytes]
  /// on their buffer after this returns.
  String entropyToMnemonicFromBytes(
    Uint8List entropy, {
    Bip39CodecOptions options = Bip39CodecOptions.defaults,
  }) {
    validateEntropyBytes(entropy);
    final cs = _checksumBitCount(entropy.length);
    final separator = mnemonicWordSeparator(
      wordlist.language,
      useIdeographicSeparator: options.useIdeographicSeparator,
    );

    var buffer = 0;
    var bitsInBuffer = 0;
    final wordParts = <String>[];

    void emitIndex() {
      bitsInBuffer -= Bip39Wordlist.bitsPerWord;
      final index = (buffer >> bitsInBuffer) & _indexMask;
      wordParts.add(wordlist.wordAt(index));
    }

    for (final byte in entropy) {
      buffer = (buffer << 8) | byte;
      bitsInBuffer += 8;
      while (bitsInBuffer >= Bip39Wordlist.bitsPerWord) {
        emitIndex();
      }
    }

    final checksum = _deriveChecksumValue(entropy);
    buffer = (buffer << cs) | checksum;
    bitsInBuffer += cs;
    while (bitsInBuffer >= Bip39Wordlist.bitsPerWord) {
      emitIndex();
    }

    return wordParts.join(separator);
  }

  /// Mnemonic → hex entropy (checksum verified).
  String mnemonicToEntropy(
    String mnemonic, {
    Bip39CodecOptions options = Bip39CodecOptions.defaults,
  }) {
    final decoded = tryDecodeMnemonic(mnemonic, options: options);
    switch (decoded) {
      case MnemonicDecodeSuccess(:final entropyBytes):
        try {
          return encodeBytesHex(entropyBytes);
        } finally {
          zeroizeBytes(entropyBytes);
        }
      case MnemonicDecodeFailure(:final reason, :final unknownWord):
        _throwParseFailure(reason, unknownWord: unknownWord);
    }
  }

  /// Mnemonic → raw entropy bytes (checksum verified).
  ///
  /// Returns a copy; call [zeroizeBytes] when finished.
  Uint8List mnemonicToEntropyBytes(
    String mnemonic, {
    Bip39CodecOptions options = Bip39CodecOptions.defaults,
  }) {
    final decoded = tryDecodeMnemonic(mnemonic, options: options);
    switch (decoded) {
      case MnemonicDecodeSuccess(:final entropyBytes):
        try {
          return Uint8List.fromList(entropyBytes);
        } finally {
          zeroizeBytes(entropyBytes);
        }
      case MnemonicDecodeFailure(:final reason, :final unknownWord):
        _throwParseFailure(reason, unknownWord: unknownWord);
    }
  }

  /// Parses [mnemonic] without throwing or hex conversion.
  MnemonicDecodeResult tryDecodeMnemonic(
    String mnemonic, {
    Bip39CodecOptions options = Bip39CodecOptions.defaults,
  }) {
    final parsed = _parseMnemonic(mnemonic, options: options);
    return switch (parsed) {
      _MnemonicParseSuccess(:final entropyBytes) =>
        MnemonicDecodeSuccess(entropyBytes),
      _MnemonicParseFailure(:final reason, :final unknownWord) =>
        MnemonicDecodeFailure(reason, unknownWord: unknownWord),
    };
  }

  /// Returns `true` when [mnemonic] is valid for this wordlist.
  bool validateMnemonic(
    String mnemonic, {
    Bip39CodecOptions options = Bip39CodecOptions.defaults,
  }) =>
      validateMnemonicDetailed(mnemonic, options: options).isValid;

  MnemonicValidationResult validateMnemonicDetailed(
    String mnemonic, {
    Bip39CodecOptions options = Bip39CodecOptions.defaults,
  }) {
    final parsed = _parseMnemonic(mnemonic, options: options);
    switch (parsed) {
      case _MnemonicParseSuccess(:final entropyBytes):
        zeroizeBytes(entropyBytes);
        return const MnemonicValidationResult.valid();
      case _MnemonicParseFailure(:final reason, :final unknownWord):
        return MnemonicValidationResult.invalid(
          reason,
          unknownWord: unknownWord,
        );
    }
  }

  _MnemonicParseResult _parseMnemonic(
    String mnemonic, {
    required Bip39CodecOptions options,
  }) {
    final words = splitMnemonicWords(
      mnemonic,
      language: wordlist.language,
      normalizeInput: options.normalizeInput,
      normalizeWords: options.normalizeWords,
    );
    if (words.isEmpty || !allowedMnemonicWordCounts.contains(words.length)) {
      return _MnemonicParseFailure(Bip39FailureReason.invalidWordCount);
    }

    final totalBits = words.length * Bip39Wordlist.bitsPerWord;
    final entropyBitCount = totalBits * 32 ~/ 33;
    final checksumBitCount = totalBits - entropyBitCount;
    final entropyByteCount = entropyBitCount ~/ 8;

    var buffer = 0;
    var bitsInBuffer = 0;
    var entropyBytesWritten = 0;
    final entropyBytes = Uint8List(entropyByteCount);

    for (final word in words) {
      final index = wordlist.lookupIndex(word);
      if (index == null) {
        return _MnemonicParseFailure(
          Bip39FailureReason.unknownWord,
          unknownWord: word,
        );
      }

      buffer = (buffer << Bip39Wordlist.bitsPerWord) | index;
      bitsInBuffer += Bip39Wordlist.bitsPerWord;

      while (bitsInBuffer >= 8 && entropyBytesWritten < entropyByteCount) {
        bitsInBuffer -= 8;
        entropyBytes[entropyBytesWritten++] = (buffer >> bitsInBuffer) & 0xFF;
      }
    }

    if (entropyBytesWritten != entropyByteCount ||
        bitsInBuffer != checksumBitCount) {
      return _MnemonicParseFailure(Bip39FailureReason.invalidEntropy);
    }

    final checksumValue = buffer & ((1 << checksumBitCount) - 1);

    try {
      validateEntropyBytes(entropyBytes);
    } on Bip39InvalidEntropyException {
      return _MnemonicParseFailure(Bip39FailureReason.invalidEntropy);
    }

    if (checksumValue != _deriveChecksumValue(entropyBytes)) {
      return _MnemonicParseFailure(Bip39FailureReason.invalidChecksum);
    }

    return _MnemonicParseSuccess(entropyBytes);
  }

  Never _throwParseFailure(
    Bip39FailureReason reason, {
    String? unknownWord,
  }) {
    switch (reason) {
      case Bip39FailureReason.unknownWord:
        throw Bip39InvalidMnemonicException(
          invalidMnemonicMessage,
          reason: reason,
          unknownWord: unknownWord,
        );
      case Bip39FailureReason.invalidWordCount:
        throw Bip39InvalidMnemonicException(
          invalidMnemonicMessage,
          reason: reason,
        );
      case Bip39FailureReason.invalidChecksum:
        throw Bip39InvalidChecksumException(invalidChecksumMessage);
      case Bip39FailureReason.invalidEntropy:
        throw Bip39InvalidEntropyException(invalidEntropyMessage);
      default:
        throw Bip39InvalidMnemonicException(
          invalidMnemonicMessage,
          reason: reason,
        );
    }
  }
}

sealed class _MnemonicParseResult {}

final class _MnemonicParseSuccess extends _MnemonicParseResult {
  _MnemonicParseSuccess(this.entropyBytes);

  final Uint8List entropyBytes;
}

final class _MnemonicParseFailure extends _MnemonicParseResult {
  _MnemonicParseFailure(this.reason, {this.unknownWord});

  final Bip39FailureReason reason;
  final String? unknownWord;
}
