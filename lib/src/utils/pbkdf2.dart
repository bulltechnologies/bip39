import 'dart:typed_data';

import 'package:native_crypto/native_crypto.dart';

/// BIP39 PBKDF2-HMAC-SHA512 (2048 iterations, 64-byte output).
class PBKDF2 {
  PBKDF2({
    Pbkdf2? pbkdf2,
    this.iterationCount = 2048,
    this.desiredKeyLength = 64,
  }) : _pbkdf2 = pbkdf2 ?? Pbkdf2();

  final int iterationCount;
  final int desiredKeyLength;

  final Pbkdf2 _pbkdf2;

  static final PBKDF2 instance = PBKDF2();

  Uint8List processBytes(Uint8List password, Uint8List salt) {
    return _pbkdf2.deriveKey(
      prf: Pbkdf2Prf.hmacSha512,
      password: password,
      salt: salt,
      iterations: iterationCount,
      derivedKeyLength: desiredKeyLength,
    );
  }
}
