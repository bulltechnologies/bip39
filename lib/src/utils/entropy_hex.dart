import 'dart:typed_data';

import 'package:hex/hex.dart';

import '../bip39_constants.dart';
import '../bip39_exceptions.dart';

/// Decodes a hex entropy string or throws [Bip39InvalidEntropyException].
Uint8List decodeEntropyHex(String entropyHex) {
  try {
    return Uint8List.fromList(HEX.decode(entropyHex));
  } on FormatException {
    throw Bip39InvalidEntropyException(invalidEntropyMessage);
  }
}
