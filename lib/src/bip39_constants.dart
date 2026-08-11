import 'dart:typed_data';

/// Supported mnemonic strengths in bits (BIP39).
const List<int> allowedMnemonicStrengths = [128, 160, 192, 224, 256];

/// Allowed mnemonic word counts (BIP39).
const Set<int> allowedMnemonicWordCounts = {12, 15, 18, 21, 24};

/// Allowed hex entropy string lengths (16–32 bytes, in hex digits).
const Set<int> allowedEntropyHexLengths = {32, 40, 48, 56, 64};

const String invalidMnemonicMessage = 'Invalid mnemonic';
const String invalidEntropyMessage = 'Invalid entropy';
const String invalidChecksumMessage = 'Invalid mnemonic checksum';

/// Returns the BIP39 mnemonic word count for [strength] bits.
///
/// [strength] must be one of [allowedMnemonicStrengths].
int wordCountForStrength(int strength) {
  if (!allowedMnemonicStrengths.contains(strength)) {
    throw ArgumentError.value(
      strength,
      'strength',
      'strength must be one of $allowedMnemonicStrengths',
    );
  }
  return (strength + strength ~/ 32) ~/ 11;
}

/// Returns the BIP39 entropy strength in bits for [wordCount] words.
///
/// [wordCount] must be one of [allowedMnemonicWordCounts].
int strengthForWordCount(int wordCount) {
  if (!allowedMnemonicWordCounts.contains(wordCount)) {
    throw ArgumentError.value(
      wordCount,
      'wordCount',
      'wordCount must be one of $allowedMnemonicWordCounts',
    );
  }
  return wordCount * 11 * 32 ~/ 33;
}

/// Lowercase hex digits for seed hex encoding (avoids per-byte [toRadixString]).
const String _hexDigits = '0123456789abcdef';

/// Encodes [bytes] as lowercase hex without intermediate string allocations.
String encodeBytesHex(Uint8List bytes) {
  final buffer = StringBuffer();
  for (final byte in bytes) {
    buffer
      ..write(_hexDigits[byte >> 4])
      ..write(_hexDigits[byte & 0x0f]);
  }
  return buffer.toString();
}
