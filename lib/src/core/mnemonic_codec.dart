import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;

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

  static int _binaryToByte(String binary) => int.parse(binary, radix: 2);

  static String _bytesToBinary(Uint8List bytes) =>
      bytes.map((byte) => byte.toRadixString(2).padLeft(8, '0')).join();

  static String _deriveChecksumBits(Uint8List entropy) {
    final ent = entropy.length * 8;
    final cs = ent ~/ 32;
    final hash = sha256.convert(entropy);
    final hashBytes = Uint8List.fromList(hash.bytes);
    try {
      return _bytesToBinary(hashBytes).substring(0, cs);
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
    Bip39EntropyOptions options = Bip39EntropyOptions.defaults,
  }) {
    _assertLanguage(options.language);
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
    Bip39EntropyOptions options = Bip39EntropyOptions.defaults,
  }) {
    _assertLanguage(options.language);
    validateEntropyBytes(entropy);
    final entropyBits = _bytesToBinary(entropy);
    final checksumBits = _deriveChecksumBits(entropy);
    final bits = entropyBits + checksumBits;
    final chunks = entropyBitChunkPattern
        .allMatches(bits)
        .map((match) => match.group(0)!)
        .toList(growable: false);
    final separator = mnemonicWordSeparator(
      wordlist.language,
      useIdeographicSeparator: options.useIdeographicSeparator,
    );
    return chunks
        .map((binary) => wordlist.wordAt(_binaryToByte(binary)))
        .join(separator);
  }

  /// Mnemonic → hex entropy (checksum verified).
  String mnemonicToEntropy(
    String mnemonic, {
    Bip39EntropyOptions options = Bip39EntropyOptions.defaults,
  }) {
    _assertLanguage(options.language);
    final words = splitMnemonicWords(
      mnemonic,
      language: wordlist.language,
      normalizeInput: options.normalizeInput,
      normalizeWords: options.normalizeWords,
    );
    if (words.isEmpty || words.length % 3 != 0) {
      throw Bip39InvalidMnemonicException(
        invalidMnemonicMessage,
        reason: Bip39FailureReason.invalidWordCount,
      );
    }

    final bits = StringBuffer();
    for (final word in words) {
      final index = wordlist.lookupIndex(word);
      if (index == null) {
        throw Bip39InvalidMnemonicException(
          invalidMnemonicMessage,
          reason: Bip39FailureReason.unknownWord,
          unknownWord: word,
        );
      }
      bits.write(index.toRadixString(2).padLeft(Bip39Wordlist.bitsPerWord, '0'));
    }

    final bitString = bits.toString();
    final dividerIndex = (bitString.length / 33).floor() * 32;
    final entropyBits = bitString.substring(0, dividerIndex);
    final checksumBits = bitString.substring(dividerIndex);

    final entropyBytes = Uint8List.fromList(
      entropyBytePattern
          .allMatches(entropyBits)
          .map((match) => _binaryToByte(match.group(0)!))
          .toList(growable: false),
    );

    try {
      validateEntropyBytes(entropyBytes);

      final newChecksum = _deriveChecksumBits(entropyBytes);
      if (newChecksum != checksumBits) {
        throw Bip39InvalidChecksumException(invalidChecksumMessage);
      }

      return entropyBytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
    } finally {
      zeroizeBytes(entropyBytes);
    }
  }

  /// Returns `true` when [mnemonic] is valid for this wordlist.
  bool validateMnemonic(
    String mnemonic, {
    Bip39ValidateOptions options = Bip39ValidateOptions.defaults,
  }) =>
      validateMnemonicDetailed(mnemonic, options: options).isValid;

  MnemonicValidationResult validateMnemonicDetailed(
    String mnemonic, {
    Bip39ValidateOptions options = Bip39ValidateOptions.defaults,
  }) {
    try {
      mnemonicToEntropy(mnemonic, options: options.entropyOptions);
      return const MnemonicValidationResult.valid();
    } on Bip39InvalidMnemonicException catch (e) {
      return MnemonicValidationResult.invalid(
        e.reason,
        unknownWord: e.unknownWord,
      );
    } on Bip39InvalidChecksumException catch (e) {
      return MnemonicValidationResult.invalid(e.reason);
    } on Bip39InvalidEntropyException catch (e) {
      return MnemonicValidationResult.invalid(e.reason);
    }
  }

  void _assertLanguage(Bip39Language language) {
    if (language != wordlist.language) {
      throw ArgumentError.value(
        language,
        'language',
        'Codec is bound to ${wordlist.language.fileName}',
      );
    }
  }
}
