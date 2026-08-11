import 'dart:typed_data';

import 'package:hex/hex.dart';

import '../bip39_constants.dart';
import '../bip39_exceptions.dart';

/// Decodes a hex entropy string or throws [Bip39InvalidEntropyException].
///
/// Rejects odd-length hex and lengths outside BIP39 (32, 40, 48, 56, or 64
/// digits) before decoding so malformed input cannot be silently padded.
Uint8List decodeEntropyHex(String entropyHex) {
  if (!allowedEntropyHexLengths.contains(entropyHex.length)) {
    throw Bip39InvalidEntropyException(invalidEntropyMessage);
  }
  try {
    return Uint8List.fromList(HEX.decode(entropyHex));
  } on FormatException {
    throw Bip39InvalidEntropyException(invalidEntropyMessage);
  }
}
