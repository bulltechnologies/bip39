import 'dart:typed_data';

import 'package:pointycastle/digests/sha512.dart';
import 'package:pointycastle/key_derivators/api.dart' show Pbkdf2Parameters;
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';

/// BIP39 PBKDF2-HMAC-SHA512 (2048 iterations, 64-byte output).
class PBKDF2 {
  PBKDF2({
    this.blockLength = 128,
    this.iterationCount = 2048,
    this.desiredKeyLength = 64,
  }) : _derivator = PBKDF2KeyDerivator(
          HMac(SHA512Digest(), blockLength),
        );

  final int blockLength;
  final int iterationCount;
  final int desiredKeyLength;

  final PBKDF2KeyDerivator _derivator;

  static final PBKDF2 instance = PBKDF2();

  Uint8List processBytes(Uint8List password, Uint8List salt) {
    _derivator
      ..reset()
      ..init(Pbkdf2Parameters(salt, iterationCount, desiredKeyLength));
    return _derivator.process(password);
  }
}
